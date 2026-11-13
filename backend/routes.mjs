import { randomUUID } from 'node:crypto';
import { PORT } from './config.mjs';
import {
  COURSE_CATALOG,
  COURSE_OWNERSHIPS,
  DSA_COURSE_ID,
  DSA_MANAGER_EMAILS,
  DSA_ROSTER_CLASSROOM_ID,
  INITIAL_CLASSROOM_OWNERSHIPS,
  INITIAL_SESSIONS,
  PROVISIONED_STUDENT_ACCOUNTS,
  USERS,
} from './data/seeds.mjs';
import {
  clone,
  createCourseSubmissionRecords,
  createUser,
  getAssignment,
  getCourse,
  getCourseDetail,
  getResourcePermissions,
  findProvisionedStudent,
  normalizeRole,
  normalizeEmail,
  toListResponse,
  toMembershipView,
  toResource,
  toSubmissionView,
} from './domain/backend-data.mjs';
import {
  mutateCollection,
  readCollection,
  readSubmissions,
  saveCollection,
  saveSubmissions,
} from './data/storage.mjs';
import { apiError, readRequestBody, sendJson } from './http.mjs';
import { createSession, getSessionUser, revokeSession } from './auth.mjs';
import { getCodePulseClassrooms, getCodePulseSubmissionContext, handleCodePulse } from './codepulse.mjs';
import { answerAssistantQuestion } from './assistant.mjs';

const isMembershipRoute = (parts) =>
  parts[0] === 'api' &&
  (parts[1] === 'classrooms' || parts[1] === 'courses') &&
  parts[2] &&
  parts[3] === 'memberships';

const getClassroomIdFromParts = (parts) => parts[2];

const isAssignedLecturer = (courseId, email) => {
  const ownership = COURSE_OWNERSHIPS[String(courseId)];
  return Boolean(
    ownership?.ownershipLocked === true &&
      normalizeEmail(ownership.ownerEmail) === normalizeEmail(email),
  ) || INITIAL_CLASSROOM_OWNERSHIPS.some(
    (ownership) =>
      ownership.classroomId === courseId &&
      ownership.status === 'ACTIVE' &&
      normalizeEmail(ownership.ownerEmail) === normalizeEmail(email),
  ) || INITIAL_SESSIONS.some(
    (session) =>
      session.courseId === courseId &&
      normalizeEmail(session.ownerEmail) === normalizeEmail(email),
  ) || (String(courseId) === DSA_COURSE_ID && DSA_MANAGER_EMAILS.some(
    (managerEmail) => normalizeEmail(managerEmail) === normalizeEmail(email),
  ));
};

const isActiveRecord = (record) => String(record.status).toUpperCase() === 'ACTIVE';

const isCodePulseMembershipFor = (membership, classroom) =>
  membership.classroomId === classroom.id ||
  (classroom.courseId === DSA_COURSE_ID && membership.classroomId === DSA_ROSTER_CLASSROOM_ID);

const isMembershipForClassroom = (membership, classroomId) =>
  membership.classroomId === classroomId
  || (String(classroomId) === DSA_COURSE_ID && membership.classroomId === DSA_ROSTER_CLASSROOM_ID);

const getCourseWithCanonicalRoster = async (courseId) => {
  const course = getCourse(courseId);
  if (String(courseId) !== DSA_COURSE_ID) return course;

  const memberships = await readCollection('memberships');
  const activeMemberships = memberships.filter(
    (membership) => membership.classroomId === DSA_ROSTER_CLASSROOM_ID && isActiveRecord(membership),
  );
  const students = activeMemberships.map((membership) => {
    const catalogStudent = course.students.find(
      (student) => normalizeEmail(student.email) === normalizeEmail(membership.studentEmail),
    );
    return {
      ...catalogStudent,
      id: membership.studentId,
      name: membership.studentName,
      email: membership.studentEmail,
    };
  });

  return { ...course, students };
};

const getAssignedCourseIds = async (viewerRole, viewerEmail) => {
  if (viewerRole === 'admin') {
    // The admin route gate only exposes the DSA lab catalog/detail endpoints.
    // Keep the course list consistent with what this role can actually open.
    return new Set([DSA_COURSE_ID]);
  }
  if (['coordinator', 'chairman'].includes(viewerRole)) {
    return new Set(Object.keys(COURSE_CATALOG));
  }

  const assignedCourseIds = new Set();
  const normalizedViewerEmail = normalizeEmail(viewerEmail);

  if (viewerRole === 'lecturer') {
    Object.entries(COURSE_OWNERSHIPS)
      .filter(([, ownership]) => ownership.ownershipLocked === true
        && normalizeEmail(ownership.ownerEmail) === normalizedViewerEmail)
      .forEach(([courseId]) => assignedCourseIds.add(String(courseId)));

    const sessions = await readCollection('sessions');
    sessions
      .filter((session) => normalizeEmail(session.ownerEmail) === normalizedViewerEmail)
      .forEach((session) => assignedCourseIds.add(String(session.courseId)));
  }

  const codePulseClassrooms = await getCodePulseClassrooms();
  if (viewerRole === 'lecturer') {
    codePulseClassrooms
      .filter((classroom) => classroom.courseId === DSA_COURSE_ID && (
        DSA_MANAGER_EMAILS.some((managerEmail) => normalizeEmail(managerEmail) === normalizedViewerEmail) ||
        classroom.managerEmails?.some((managerEmail) => normalizeEmail(managerEmail) === normalizedViewerEmail)
      ))
      .forEach((classroom) => assignedCourseIds.add(String(classroom.courseId)));
  }

  if (viewerRole === 'lecturer') {
    codePulseClassrooms
      .filter((classroom) => normalizeEmail(classroom.lecturerEmail) === normalizedViewerEmail)
      .forEach((classroom) => assignedCourseIds.add(String(classroom.courseId)));
  }

  if (viewerRole === 'student') {
    const memberships = await readCollection('memberships');
    memberships
      .filter((membership) => isActiveRecord(membership) && normalizeEmail(membership.studentEmail ?? membership.userEmail) === normalizedViewerEmail)
      .forEach((membership) => {
        const legacyCourseId = String(membership.classroomId);
        if (COURSE_CATALOG[legacyCourseId]) assignedCourseIds.add(legacyCourseId);
        codePulseClassrooms
          .filter((classroom) => classroom.status === 'ACTIVE' && isCodePulseMembershipFor(membership, classroom))
          .forEach((classroom) => assignedCourseIds.add(String(classroom.courseId)));
      });
  }

  return assignedCourseIds;
};

const assertCourseAccess = async (courseId, viewerRole, viewerEmail) => {
  const assignedCourseIds = await getAssignedCourseIds(viewerRole, viewerEmail);
  if (!assignedCourseIds.has(String(courseId))) {
    if (viewerRole === 'student') {
      throw apiError(403, 'MEMBERSHIP_REQUIRED', 'Tài khoản không có membership ACTIVE trong classroom này.');
    }
    throw apiError(403, 'FORBIDDEN', 'Bạn không được phân công khóa học này.');
  }
};

const getCourseDetailWithSavedContent = async (course, viewerRole, viewerEmail) => {
  const detail = getCourseDetail(course, viewerRole, viewerEmail);
  const saved = (await readCollection('courseDetails'))
    .find((record) => String(record.courseId) === String(course.id));
  if (!saved) return { ...detail, contentRevision: 0 };

  return {
    ...detail,
    content: saved.content,
    contentRevision: saved.revision,
    contentUpdatedAt: saved.updatedAt,
    meta: { ...detail.meta, updatedAt: saved.updatedAt },
  };
};

const validateCourseContent = (content) => {
  if (!Array.isArray(content)) {
    throw apiError(400, 'INVALID_COURSE_CONTENT', 'content phải là danh sách nội dung khóa học.');
  }
  if (content.length > 100) {
    throw apiError(400, 'INVALID_COURSE_CONTENT', 'Khóa học không được vượt quá 100 mục nội dung.');
  }
  if (Buffer.byteLength(JSON.stringify(content), 'utf8') > 512_000) {
    throw apiError(413, 'COURSE_CONTENT_TOO_LARGE', 'Nội dung khóa học vượt quá giới hạn 500 KB.');
  }

  const supportedTypes = new Set([
    'introduction', 'material', 'movie', 'note', 'submission', 'reference', 'bookReference',
  ]);
  const ids = new Set();
  return content.map((section) => {
    if (!section || typeof section !== 'object' || Array.isArray(section)) {
      throw apiError(400, 'INVALID_COURSE_CONTENT', 'Mỗi mục nội dung phải là một object.');
    }
    const id = typeof section.id === 'string' ? section.id.trim() : '';
    const type = typeof section.type === 'string' ? section.type : '';
    const title = typeof section.title === 'string' ? section.title.trim() : '';
    const description = section.description ?? '';
    if (!id || id.length > 200 || ids.has(id)) {
      throw apiError(400, 'INVALID_COURSE_CONTENT', 'Mỗi mục cần ID duy nhất, tối đa 200 ký tự.');
    }
    if (!supportedTypes.has(type)) {
      throw apiError(400, 'INVALID_COURSE_CONTENT', `Loại nội dung không được hỗ trợ: ${type || '(trống)'}.`);
    }
    if (!title || title.length > 200) {
      throw apiError(400, 'INVALID_COURSE_CONTENT', 'Tiêu đề cần có nội dung và không quá 200 ký tự.');
    }
    if (typeof description !== 'string' || description.length > 5000) {
      throw apiError(400, 'INVALID_COURSE_CONTENT', 'Mô tả phải là văn bản tối đa 5.000 ký tự.');
    }
    if (!section.data || typeof section.data !== 'object' || Array.isArray(section.data)) {
      throw apiError(400, 'INVALID_COURSE_CONTENT', 'data của mỗi mục phải là một object.');
    }
    ids.add(id);
    return {
      id,
      type,
      title,
      data: section.data,
      ...(description ? { description } : {}),
    };
  });
};

const ensureClassroomExists = (classroomId) => {
  if (!COURSE_CATALOG[classroomId]) {
    throw apiError(404, 'CLASSROOM_NOT_FOUND', `Không tìm thấy classroom ${classroomId}.`);
  }
};

const assertStudentHasAccess = (memberships, classroomId, viewerRole, viewerEmail) => {
  if (viewerRole !== 'student') return;
  if (!memberships.some((membership) =>
    isMembershipForClassroom(membership, classroomId)
    && normalizeEmail(membership.studentEmail) === normalizeEmail(viewerEmail)
    && isActiveRecord(membership))) {
    throw apiError(
      403,
      'MEMBERSHIP_REQUIRED',
      'Tài khoản không có membership ACTIVE trong classroom này.',
    );
  }
};

const membershipListResponse = (items, classroomId, viewerRole, viewerEmail) => ({
  items: items.map((item) => toMembershipView(item, viewerRole, viewerEmail)),
  classroomId,
  viewerRole,
  permissions: {
    canView: true,
    canEdit: viewerRole === 'lecturer',
    canDelete: viewerRole === 'lecturer',
    canCreate: viewerRole === 'lecturer',
  },
  availableStudents: viewerRole === 'lecturer'
    ? PROVISIONED_STUDENT_ACCOUNTS
    : [],
  meta: {
    source: 'node-backend',
    updatedAt: new Date().toISOString(),
    total: items.length,
  },
});

async function handleRequest(request, response) {
  if (request.method === 'OPTIONS') {
    sendJson(response, 204, {});
    return;
  }

  const requestUrl = new URL(request.url, `http://127.0.0.1:${PORT}`);
  const parts = requestUrl.pathname.split('/').filter(Boolean);

  if (request.method === 'GET' && requestUrl.pathname === '/api/health') {
    sendJson(response, 200, { ok: true, service: 'spm-backend' });
    return;
  }

  if (request.method === 'POST' && requestUrl.pathname === '/api/auth/login') {
    const body = await readRequestBody(request);
    const user = USERS.find(
      (candidate) => candidate.email === body.email && candidate.password === body.password,
    );

    if (!user) throw apiError(401, 'INVALID_CREDENTIALS', 'Email hoặc mật khẩu không đúng!');
    if (user.status !== 'ACTIVE') throw apiError(403, 'ACCOUNT_LOCKED', 'Tài khoản đã bị khóa hoặc không được phép truy cập!');

    sendJson(response, 200, {
      accessToken: createSession(user),
      user: createUser(user),
      role: normalizeRole(user.role),
    });
    return;
  }

  if (request.method === 'POST' && requestUrl.pathname === '/api/auth/logout') {
    sendJson(response, 200, { revoked: revokeSession(request) });
    return;
  }

  const currentUser = getSessionUser(request, USERS);
  if (!currentUser) throw apiError(401, 'UNAUTHORIZED', 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.');
  if (currentUser.status !== 'ACTIVE') throw apiError(403, 'ACCOUNT_LOCKED', 'Tài khoản đã bị khóa hoặc không được phép truy cập!');
  if (request.method === 'GET' && requestUrl.pathname === '/api/auth/me') {
    sendJson(response, 200, { user: createUser(currentUser), role: normalizeRole(currentUser.role) });
    return;
  }
  const viewerRole = normalizeRole(currentUser.role);
  const effectiveUser = { ...currentUser, role: viewerRole };
  const viewerEmail = currentUser.email;
  if (request.method === 'POST' && requestUrl.pathname === '/api/assistant/messages') {
    if (!['student', 'lecturer'].includes(viewerRole)) {
      throw apiError(403, 'FORBIDDEN', 'Trợ lý hướng dẫn hiện dành cho sinh viên và giảng viên.');
    }
    const body = await readRequestBody(request);
    const result = await answerAssistantQuestion(
      body.question,
      viewerRole === 'lecturer' ? 'tutor' : 'student',
    );
    sendJson(response, 200, result);
    return;
  }
  if (requestUrl.pathname.startsWith('/api/codepulse/')) {
    await handleCodePulse({ request, response, requestUrl, user: effectiveUser, sendJson, readRequestBody, apiError });
    return;
  }
  const isDsaLabCatalogRoute = requestUrl.pathname === '/api/courses'
    || requestUrl.pathname === `/api/courses/${DSA_COURSE_ID}/detail`;
  const isDsaLabSubmissionRoute = (requestUrl.pathname.startsWith(`/api/courses/${DSA_COURSE_ID}/submissions`)
    || requestUrl.pathname.startsWith('/api/submissions/'));
  if (viewerRole === 'admin'
    && !isDsaLabCatalogRoute
    && !isDsaLabSubmissionRoute) {
    throw apiError(403, 'FORBIDDEN', 'Vai trò này không có quyền truy cập API khóa học.');
  }

  if (isMembershipRoute(parts)) {
    const classroomId = getClassroomIdFromParts(parts);
    ensureClassroomExists(classroomId);
    const membershipId = parts[4];
    if (viewerRole === 'lecturer') {
      if (!isAssignedLecturer(classroomId, viewerEmail)) {
        throw apiError(403, 'FORBIDDEN', 'Bạn không được phân công classroom này.');
      }
    }

    if (request.method === 'GET' && !membershipId) {
      const records = await readCollection('memberships');
      if (viewerRole === 'student') {
        assertStudentHasAccess(records, classroomId, viewerRole, viewerEmail);
      }
      const classroomMemberships = records.filter((record) => isMembershipForClassroom(record, classroomId));
      // Students may open the roster as a class directory. Access is still
      // gated by the authenticated student's own ACTIVE membership above;
      // the response must not be reduced to only the current student.
      const visibleMemberships = classroomMemberships;

      sendJson(
        response,
        200,
        membershipListResponse(visibleMemberships, classroomId, viewerRole, viewerEmail),
      );
      return;
    }

    if (request.method === 'POST' && !membershipId) {
      const body = await readRequestBody(request);
      if (viewerRole !== 'lecturer') {
        throw apiError(403, 'FORBIDDEN', 'Chỉ lecturer được quản lý membership của classroom.');
      }

      const studentEmail = normalizeEmail(body.studentEmail ?? body.email);
      const student = findProvisionedStudent(studentEmail);
      if (!student) {
        throw apiError(404, 'STUDENT_NOT_FOUND', 'Không tìm thấy tài khoản student đã được provision.');
      }

      const result = await mutateCollection('memberships', (records) => {
        const existing = records.find(
          (record) =>
            isMembershipForClassroom(record, classroomId) &&
            (record.studentId === student.id || normalizeEmail(record.studentEmail) === studentEmail),
        );
        if (existing?.status === 'ACTIVE') {
          return { membership: existing, created: false, reactivated: false };
        }

        const now = new Date().toISOString();
        const membershipClassroomId = String(classroomId) === DSA_COURSE_ID
          ? DSA_ROSTER_CLASSROOM_ID
          : classroomId;
        const membership = existing
          ? {
            ...existing,
            studentId: student.id,
            studentName: student.name,
            studentEmail: student.email,
            status: 'ACTIVE',
            revokedAt: null,
            updatedAt: now,
          }
          : {
            id: `membership-${membershipClassroomId}-${student.id}`,
            classroomId: membershipClassroomId,
            studentId: student.id,
            studentName: student.name,
            studentEmail: student.email,
            status: 'ACTIVE',
            enrolledAt: now,
            revokedAt: null,
            createdAt: now,
            updatedAt: now,
          };
        if (existing) records[records.indexOf(existing)] = membership;
        else records.push(membership);
        return { membership, created: !existing, reactivated: Boolean(existing) };
      });
      sendJson(response, result.created ? 201 : 200, {
        item: toMembershipView(result.membership, viewerRole, viewerEmail),
        created: result.created,
        reactivated: result.reactivated,
      });
      return;
    }

    if ((request.method === 'PATCH' || request.method === 'DELETE') && membershipId) {
      const body = await readRequestBody(request);
      if (viewerRole !== 'lecturer') {
        throw apiError(403, 'FORBIDDEN', 'Chỉ lecturer được revoke membership của classroom.');
      }

      const updated = await mutateCollection('memberships', (records) => {
        const index = records.findIndex(
          (record) => isMembershipForClassroom(record, classroomId) && record.id === membershipId,
        );
        if (index < 0) {
          throw apiError(404, 'MEMBERSHIP_NOT_FOUND', `Không tìm thấy membership ${membershipId}.`);
        }

        const requestedStatus = request.method === 'DELETE' ? 'REVOKED' : body.status ?? 'REVOKED';
        if (!['ACTIVE', 'REVOKED'].includes(requestedStatus)) {
          throw apiError(400, 'INVALID_MEMBERSHIP_STATUS', 'Membership status phải là ACTIVE hoặc REVOKED.');
        }

        const now = new Date().toISOString();
        const membership = {
          ...records[index],
          status: requestedStatus,
          revokedAt: requestedStatus === 'REVOKED' ? now : null,
          updatedAt: now,
        };
        records[index] = membership;
        return membership;
      });
      sendJson(response, 200, {
        item: toMembershipView(updated, viewerRole, viewerEmail),
      });
      return;
    }
  }

  if (request.method === 'GET' && requestUrl.pathname === '/api/courses') {
    const assignedCourseIds = await getAssignedCourseIds(viewerRole, viewerEmail);
    const items = await Promise.all(Object.keys(COURSE_CATALOG)
      .filter((courseId) => assignedCourseIds.has(courseId))
      .map((courseId) => getCourseWithCanonicalRoster(courseId)));
    sendJson(response, 200, toListResponse(items, viewerRole, viewerEmail, 'course'));
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'courses' && parts[3] === 'tutor-feedback') {
    const course = await getCourseWithCanonicalRoster(parts[2]);
    await assertCourseAccess(course.id, viewerRole, viewerEmail);
    const coursePermissions = getCourseDetail(course, viewerRole, viewerEmail).permissions;
    if (viewerRole !== 'lecturer') {
      throw apiError(403, 'FORBIDDEN', 'Nhận xét tutor chỉ dành cho giảng viên được phân công.');
    }

    if (request.method === 'GET') {
      const stored = (await readCollection('courseFeedback'))
        .find((record) => String(record.courseId) === String(course.id));
      sendJson(response, 200, {
        item: {
          courseComment: stored?.courseComment ?? '',
          studentComments: stored?.studentComments ?? {},
          revision: stored?.revision ?? 0,
        },
      });
      return;
    }

    if (request.method === 'PATCH') {
      if (!coursePermissions.canEdit) {
        throw apiError(403, 'FORBIDDEN', 'Chỉ giảng viên sở hữu khóa học được cập nhật nhận xét.');
      }
      const body = await readRequestBody(request);
      if (!body || typeof body !== 'object' || Array.isArray(body)) {
        throw apiError(400, 'INVALID_COURSE_FEEDBACK', 'Body phải là một object JSON.');
      }
      if (!Number.isInteger(body.expectedRevision) || body.expectedRevision < 0) {
        throw apiError(400, 'INVALID_CONTENT_REVISION', 'expectedRevision phải là số nguyên không âm.');
      }
      if (typeof body.courseComment !== 'string' || body.courseComment.length > 5000) {
        throw apiError(400, 'INVALID_COURSE_FEEDBACK', 'Nhận xét môn học phải là văn bản tối đa 5.000 ký tự.');
      }
      if (!body.studentComments || typeof body.studentComments !== 'object' || Array.isArray(body.studentComments)) {
        throw apiError(400, 'INVALID_COURSE_FEEDBACK', 'studentComments phải là object theo email học viên.');
      }

      const rosterEmails = new Map(
        course.students.map((student) => [normalizeEmail(student.email), student.email]),
      );
      const studentComments = {};
      for (const [email, comment] of Object.entries(body.studentComments)) {
        const normalizedEmail = normalizeEmail(email);
        if (!rosterEmails.has(normalizedEmail)) {
          throw apiError(400, 'INVALID_COURSE_FEEDBACK', 'Chỉ được nhận xét học viên trong danh sách của khóa học.');
        }
        if (typeof comment !== 'string' || comment.length > 2000) {
          throw apiError(400, 'INVALID_COURSE_FEEDBACK', 'Mỗi nhận xét học viên phải là văn bản tối đa 2.000 ký tự.');
        }
        studentComments[rosterEmails.get(normalizedEmail)] = comment;
      }

      const updatedAt = new Date().toISOString();
      const saved = await mutateCollection('courseFeedback', (records) => {
        const index = records.findIndex((record) => String(record.courseId) === String(course.id));
        const previous = index < 0 ? null : records[index];
        const revision = previous?.revision ?? 0;
        if (body.expectedRevision !== revision) {
          throw apiError(409, 'REVISION_CONFLICT', 'Nhận xét đã được cập nhật ở nơi khác. Tải lại trước khi lưu.');
        }
        const record = {
          ...(previous ?? {}),
          courseId: String(course.id),
          courseComment: body.courseComment,
          studentComments,
          revision: revision + 1,
          updatedAt,
          updatedBy: viewerEmail,
        };
        if (index < 0) records.push(record);
        else records[index] = record;
        return record;
      });
      sendJson(response, 200, {
        item: {
          courseComment: saved.courseComment,
          studentComments: saved.studentComments,
          revision: saved.revision,
        },
      });
      return;
    }
  }

  if (parts[0] === 'api' && parts[1] === 'courses' && parts[3] === 'detail' && request.method === 'PATCH') {
    const body = await readRequestBody(request);
    if (!body || typeof body !== 'object' || Array.isArray(body)) {
      throw apiError(400, 'INVALID_COURSE_CONTENT', 'Body phải là một object JSON.');
    }
    const course = await getCourseWithCanonicalRoster(parts[2]);
    await assertCourseAccess(parts[2], viewerRole, viewerEmail);
    const currentDetail = getCourseDetail(course, viewerRole, viewerEmail);
    if (!currentDetail.permissions.canEdit) {
      throw apiError(403, 'FORBIDDEN', 'Bạn không có quyền chỉnh sửa nội dung khóa học này.');
    }
    if (!Number.isInteger(body.expectedRevision) || body.expectedRevision < 0) {
      throw apiError(400, 'INVALID_CONTENT_REVISION', 'expectedRevision phải là số nguyên không âm.');
    }
    const content = validateCourseContent(body.content);
    const updatedAt = new Date().toISOString();
    const saved = await mutateCollection('courseDetails', async (records) => {
      const index = records.findIndex((record) => String(record.courseId) === String(course.id));
      const previous = index < 0 ? null : records[index];
      const revision = previous?.revision ?? 0;
      if (body.expectedRevision !== revision) {
        throw apiError(409, 'REVISION_CONFLICT', 'Nội dung khóa học đã thay đổi. Tải lại trước khi lưu.');
      }

      const previousContent = previous?.content ?? currentDetail.content;
      const retainedIds = new Set(content.map((section) => section.id));
      const removedAssignments = previousContent
        .filter((section) => section.type === 'submission' && !retainedIds.has(section.id));
      if (removedAssignments.length > 0) {
        const removedIds = new Set(removedAssignments.map((assignment) => assignment.id));
        const submissions = await readSubmissions();
        if (submissions.some((submission) =>
          String(submission.courseId) === String(course.id) && removedIds.has(submission.assignmentId))) {
          throw apiError(409, 'ASSIGNMENT_HAS_SUBMISSIONS', 'Không thể xóa bài tập đã có bài nộp; hãy giữ mục và cập nhật nội dung.');
        }
      }

      const record = {
        ...(previous ?? {}),
        courseId: String(course.id),
        content,
        revision: revision + 1,
        updatedAt,
        updatedBy: viewerEmail,
      };
      if (index < 0) records.push(record);
      else records[index] = record;
      return record;
    });

    sendJson(response, 200, {
      course: toResource(course, viewerRole, viewerEmail, 'course'),
      detail: {
        ...currentDetail,
        content: saved.content,
        contentRevision: saved.revision,
        contentUpdatedAt: saved.updatedAt,
        meta: { ...currentDetail.meta, updatedAt: saved.updatedAt },
      },
    });
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'courses' && parts[3] === 'detail' && request.method === 'GET') {
    const course = await getCourseWithCanonicalRoster(parts[2]);
    await assertCourseAccess(parts[2], viewerRole, viewerEmail);
    sendJson(response, 200, {
      course: toResource(course, viewerRole, viewerEmail, 'course'),
      detail: await getCourseDetailWithSavedContent(course, viewerRole, viewerEmail),
    });
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'courses' && parts[3] === 'submissions' && request.method === 'GET') {
    const course = await getCourseWithCanonicalRoster(parts[2]);
    if (!['student', 'lecturer'].includes(viewerRole)) {
      throw apiError(403, 'FORBIDDEN', 'Bạn không có quyền xem bài nộp.');
    }
    await assertCourseAccess(course.id, viewerRole, viewerEmail);
    const detail = await getCourseDetailWithSavedContent(course, viewerRole, viewerEmail);
    const assignments = getAssignment(detail, requestUrl.searchParams.get('assignmentId'));
    if (assignments.length === 0) {
      throw apiError(404, 'ASSIGNMENT_NOT_FOUND', `Không tìm thấy bài tập trong khóa học ${course.id}.`);
    }

    let records = await readSubmissions();
    let changed = false;
    const items = [];

    for (const assignment of assignments) {
      const submissionContext = await getCodePulseSubmissionContext(course.id, assignment.id);
      const submissionStudents = course.id === DSA_COURSE_ID && submissionContext.classroom
        ? (await readCollection('memberships'))
          .filter((membership) => isActiveRecord(membership)
            && isCodePulseMembershipFor(membership, submissionContext.classroom))
          .map((membership) => ({
            name: membership.studentName,
            email: membership.studentEmail,
          }))
        : course.students;
      let assignmentRecords = records.filter(
        (record) => record.courseId === course.id && record.assignmentId === assignment.id,
      );

      if (assignmentRecords.length === 0) {
        assignmentRecords = createCourseSubmissionRecords(course, assignment.id, submissionStudents);
        records = [...records, ...assignmentRecords];
        changed = true;
      }

      items.push(...assignmentRecords.map((record) => toSubmissionView(record, assignment, viewerRole, submissionContext)));
    }

    if (changed) await saveSubmissions(records);

    if (viewerRole === 'student') {
      const studentId = requestUrl.searchParams.get('studentId');
      const studentEmail = requestUrl.searchParams.get('studentEmail');
      if (studentEmail && studentEmail !== viewerEmail) {
        throw apiError(403, 'FORBIDDEN', 'Bạn không có quyền xem bài nộp của người khác.');
      }
      const ownItems = items.filter((item) => item.student.email === viewerEmail);
      if (studentId && ownItems.some((item) => item.student.id !== studentId)) {
        throw apiError(403, 'FORBIDDEN', 'Bạn không có quyền xem bài nộp của người khác.');
      }
      items.splice(0, items.length, ...ownItems);
    }

    sendJson(response, 200, {
      items,
      viewerRole,
      permissions: {
        canView: true,
        canEdit: viewerRole === 'lecturer',
        canCreate: viewerRole === 'student',
      },
      meta: {
        source: 'node-backend',
        updatedAt: new Date().toISOString(),
        total: items.length,
      },
    });
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'submissions' && parts[2] && request.method === 'PATCH') {
    const body = await readRequestBody(request);
    const records = await readSubmissions();
    const index = records.findIndex((record) => record.id === parts[2]);
    if (index < 0) throw apiError(404, 'SUBMISSION_NOT_FOUND', `Không tìm thấy submission ${parts[2]}.`);

    const current = records[index];
    if (!['student', 'lecturer'].includes(viewerRole)) {
      throw apiError(403, 'FORBIDDEN', 'Bạn không có quyền sửa bài nộp.');
    }
    if (viewerRole === 'student' && current.student.email !== viewerEmail) {
      throw apiError(403, 'FORBIDDEN', 'Bạn không có quyền sửa bài nộp của người khác.');
    }
    await assertCourseAccess(current.courseId, viewerRole, viewerEmail);
    const updated = { ...current };

    if (viewerRole === 'lecturer') {
      if (body.score !== undefined) updated.score = body.score;
      if (body.feedback !== undefined) updated.feedback = body.feedback;
    } else {
      if (body.submittedAt !== undefined) updated.submittedAt = body.submittedAt;
      if (body.fileUrl !== undefined) updated.fileUrl = body.fileUrl;
    }

    updated.status = updated.submittedAt
      ? updated.score === null ? 'submitted' : 'graded'
      : 'not-submitted';

    records[index] = updated;
    await saveSubmissions(records);

    const course = await getCourseWithCanonicalRoster(updated.courseId);
    await assertCourseAccess(course.id, viewerRole, viewerEmail);
    const detail = await getCourseDetailWithSavedContent(course, viewerRole, viewerEmail);
    const assignment = getAssignment(detail, updated.assignmentId)[0];
    if (!assignment) throw apiError(404, 'ASSIGNMENT_NOT_FOUND', `Không tìm thấy assignment ${updated.assignmentId}.`);

    sendJson(response, 200, {
      item: toSubmissionView(
        updated,
        assignment,
        viewerRole,
        await getCodePulseSubmissionContext(updated.courseId, assignment.id),
      ),
    });
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'session-requests' && !parts[2] && request.method === 'GET') {
    const records = await readCollection('sessionRequests');
    let items;
    if (viewerRole === 'student') {
      items = records.filter((item) => normalizeEmail(item.requesterEmail) === normalizeEmail(viewerEmail));
    } else if (viewerRole === 'lecturer') {
      const assignedCourseIds = await getAssignedCourseIds(viewerRole, viewerEmail);
      items = records.filter((item) => assignedCourseIds.has(String(item.courseId)));
    } else if (['coordinator', 'chairman'].includes(viewerRole)) {
      items = records;
    } else {
      throw apiError(403, 'FORBIDDEN', 'Bạn không có quyền xem yêu cầu buổi học.');
    }

    sendJson(response, 200, {
      items,
      viewerRole,
      permissions: {
        canCreate: viewerRole === 'student',
        canReview: ['lecturer', 'coordinator', 'chairman'].includes(viewerRole),
      },
      meta: { source: 'node-backend', updatedAt: new Date().toISOString(), total: items.length },
    });
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'session-requests' && !parts[2] && request.method === 'POST') {
    if (viewerRole !== 'student') {
      throw apiError(403, 'FORBIDDEN', 'Chỉ sinh viên được gửi yêu cầu buổi học.');
    }
    const body = await readRequestBody(request);
    if (!body || typeof body !== 'object' || Array.isArray(body)) {
      throw apiError(400, 'INVALID_SESSION_REQUEST', 'Body phải là một object JSON.');
    }
    const courseId = typeof body.courseId === 'string' ? body.courseId.trim() : '';
    const requestType = typeof body.requestType === 'string' ? body.requestType : '';
    const title = typeof body.title === 'string' ? body.title.trim() : '';
    const description = typeof body.description === 'string' ? body.description.trim() : '';
    const proposedAt = typeof body.proposedAt === 'string' ? new Date(body.proposedAt) : null;
    if (!courseId || !COURSE_CATALOG[courseId]) {
      throw apiError(400, 'INVALID_SESSION_REQUEST', 'Chọn khóa học đang có trong danh sách của bạn.');
    }
    if (!['new', 'makeup', 'absent'].includes(requestType)) {
      throw apiError(400, 'INVALID_SESSION_REQUEST', 'Loại yêu cầu phải là new, makeup hoặc absent.');
    }
    if (!title || title.length > 160 || description.length > 3000) {
      throw apiError(400, 'INVALID_SESSION_REQUEST', 'Tiêu đề bắt buộc (tối đa 160 ký tự); mô tả tối đa 3.000 ký tự.');
    }
    const now = Date.now();
    if (!proposedAt || !Number.isFinite(proposedAt.getTime())
      || proposedAt.getTime() <= now
      || proposedAt.getTime() > now + 366 * 24 * 60 * 60 * 1000) {
      throw apiError(400, 'INVALID_SESSION_REQUEST', 'Thời gian đề xuất phải ở tương lai và không quá một năm.');
    }
    const memberships = await readCollection('memberships');
    assertStudentHasAccess(memberships, courseId, viewerRole, viewerEmail);
    const course = await getCourseWithCanonicalRoster(courseId);
    const createdAt = new Date().toISOString();
    const item = await mutateCollection('sessionRequests', (records) => {
      const record = {
        id: `session-request-${randomUUID()}`,
        courseId,
        courseTitle: course.title,
        requesterEmail: viewerEmail,
        requestType,
        title,
        description,
        proposedAt: proposedAt.toISOString(),
        status: 'pending',
        reviewReason: '',
        createdAt,
        updatedAt: createdAt,
      };
      records.unshift(record);
      return record;
    });
    sendJson(response, 201, { item });
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'session-requests' && parts[2] && request.method === 'PATCH') {
    if (!['lecturer', 'coordinator', 'chairman'].includes(viewerRole)) {
      throw apiError(403, 'FORBIDDEN', 'Bạn không có quyền xử lý yêu cầu buổi học.');
    }
    const body = await readRequestBody(request);
    if (!body || typeof body !== 'object' || Array.isArray(body)) {
      throw apiError(400, 'INVALID_SESSION_REQUEST_STATUS', 'Body phải là một object JSON.');
    }
    const status = typeof body.status === 'string' ? body.status.toLowerCase() : '';
    const reason = typeof body.reason === 'string' ? body.reason.trim() : '';
    if (!['approved', 'declined'].includes(status)) {
      throw apiError(400, 'INVALID_SESSION_REQUEST_STATUS', 'Trạng thái xử lý phải là approved hoặc declined.');
    }
    if (reason.length > 1000 || (status === 'declined' && !reason)) {
      throw apiError(400, 'INVALID_SESSION_REQUEST_REASON', 'Khi từ chối cần nêu lý do tối đa 1.000 ký tự.');
    }
    const assignedCourseIds = viewerRole === 'lecturer'
      ? await getAssignedCourseIds(viewerRole, viewerEmail)
      : null;
    const updated = await mutateCollection('sessionRequests', (records) => {
      const index = records.findIndex((item) => item.id === parts[2]);
      if (index < 0) throw apiError(404, 'SESSION_REQUEST_NOT_FOUND', 'Không tìm thấy yêu cầu buổi học.');
      const current = records[index];
      if (assignedCourseIds && !assignedCourseIds.has(String(current.courseId))) {
        throw apiError(403, 'FORBIDDEN', 'Bạn không được phân công khóa học của yêu cầu này.');
      }
      if (current.status !== 'pending') {
        throw apiError(409, 'SESSION_REQUEST_ALREADY_REVIEWED', 'Yêu cầu đã được xử lý và không thể đổi trạng thái.');
      }
      const item = {
        ...current,
        status,
        reviewReason: reason,
        reviewedBy: viewerEmail,
        reviewedAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
      records[index] = item;
      return item;
    });
    sendJson(response, 200, { item: updated });
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'sessions' && request.method === 'GET') {
    const courseId = requestUrl.searchParams.get('courseId');
    const records = await readCollection('sessions');
    let items = courseId ? records.filter((record) => record.courseId === courseId) : records;
    if (viewerRole === 'student') {
      const memberships = await readCollection('memberships');
      if (courseId) {
        assertStudentHasAccess(memberships, courseId, viewerRole, viewerEmail);
      } else {
        const activeClassrooms = new Set(
          memberships
            .filter(
              (membership) =>
                membership.status === 'ACTIVE' &&
                normalizeEmail(membership.studentEmail) === normalizeEmail(viewerEmail),
            )
            .map((membership) => membership.classroomId),
        );
        items = items.filter((record) => activeClassrooms.has(record.courseId));
      }
    } else if (viewerRole === 'lecturer') {
      items = items.filter((record) => record.ownerEmail === viewerEmail);
    }
    sendJson(response, 200, toListResponse(items, viewerRole, viewerEmail, 'session'));
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'sessions' && !parts[2] && request.method === 'POST') {
    const body = await readRequestBody(request);
    if (viewerRole !== 'lecturer' && viewerRole !== 'coordinator' && viewerRole !== 'chairman') {
      throw apiError(403, 'FORBIDDEN', 'Bạn không có quyền tạo session.');
    }
    if (viewerRole === 'lecturer' && body.item?.courseId && !isAssignedLecturer(body.item.courseId, viewerEmail)) {
      throw apiError(403, 'FORBIDDEN', 'Bạn không được phân công khóa học này.');
    }
    const item = {
      ...clone(body.item ?? {}),
      id: body.item?.id ?? `session-${Date.now()}`,
      createdAt: body.item?.createdAt ?? new Date().toISOString(),
      ownerRole: viewerRole,
      ownerEmail: viewerEmail,
    };
    const records = await readCollection('sessions');
    records.push(item);
    await saveCollection('sessions', records);
    sendJson(response, 201, { item: toResource(item, viewerRole, viewerEmail, 'session') });
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'sessions' && parts[2] && request.method === 'PATCH') {
    const body = await readRequestBody(request);
    const records = await readCollection('sessions');
    const index = records.findIndex((record) => record.id === parts[2]);
    if (index < 0) throw apiError(404, 'SESSION_NOT_FOUND', `Không tìm thấy session ${parts[2]}.`);

    const current = records[index];
    const permissions = getResourcePermissions({
      viewerRole,
      ownerRole: current.ownerRole,
      ownerEmail: current.ownerEmail,
      viewerEmail,
    });
    if (!permissions.canEdit) throw apiError(403, 'FORBIDDEN', 'Bạn không có quyền chỉnh sửa session này.');

    const { id: ignoredId, ownerRole: ignoredRole, ownerEmail: ignoredEmail, ...patch } = clone(body.patch ?? {});
    if (viewerRole === 'lecturer' && patch.courseId && !isAssignedLecturer(patch.courseId, viewerEmail)) {
      throw apiError(403, 'FORBIDDEN', 'Bạn không được phân công khóa học này.');
    }
    const updated = { ...current, ...patch, updatedAt: new Date().toISOString() };
    records[index] = updated;
    await saveCollection('sessions', records);
    sendJson(response, 200, { item: toResource(updated, viewerRole, viewerEmail, 'session') });
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'sessions' && parts[2] && request.method === 'DELETE') {
    const body = await readRequestBody(request);
    const records = await readCollection('sessions');
    const current = records.find((record) => record.id === parts[2]);
    if (!current) throw apiError(404, 'SESSION_NOT_FOUND', `Không tìm thấy session ${parts[2]}.`);
    const permissions = getResourcePermissions({
      viewerRole,
      ownerRole: current.ownerRole,
      ownerEmail: current.ownerEmail,
      viewerEmail,
    });
    if (!permissions.canDelete) throw apiError(403, 'FORBIDDEN', 'Bạn không có quyền xóa session này.');
    await saveCollection('sessions', records.filter((record) => record.id !== parts[2]));
    sendJson(response, 200, { deleted: true });
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'registrations' && request.method === 'GET') {
    const registrationType = requestUrl.searchParams.get('registrationType');
    const records = await readCollection('registrations');
    const items = registrationType
      ? records.filter((record) => record.registrationType === registrationType)
      : records;
    sendJson(response, 200, toListResponse(items, viewerRole, viewerEmail, 'registration'));
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'registrations' && !parts[2] && request.method === 'POST') {
    const body = await readRequestBody(request);
    const requestedRegistrationRole = normalizeRole(body.registrationType);
    if (viewerRole !== 'coordinator' && viewerRole !== 'chairman' && requestedRegistrationRole !== viewerRole) {
      throw apiError(403, 'FORBIDDEN', 'Bạn không có quyền tạo đăng ký này.');
    }
    const item = {
      ...clone(body.item ?? {}),
      id: body.item?.id ?? `registration-${Date.now()}`,
      registrationType: body.registrationType ?? viewerRole,
      ownerRole: viewerRole,
      ownerEmail: viewerEmail,
      createdAt: body.item?.createdAt ?? new Date().toISOString(),
    };
    const records = await readCollection('registrations');
    records.push(item);
    await saveCollection('registrations', records);
    sendJson(response, 201, { item: toResource(item, viewerRole, viewerEmail, 'registration') });
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'registrations' && parts[2] && request.method === 'PATCH') {
    const body = await readRequestBody(request);
    const records = await readCollection('registrations');
    const index = records.findIndex((record) => record.id === parts[2]);
    if (index < 0) throw apiError(404, 'REGISTRATION_NOT_FOUND', `Không tìm thấy registration ${parts[2]}.`);
    const current = records[index];
    const permissions = getResourcePermissions({
      viewerRole,
      ownerRole: current.ownerRole,
      ownerEmail: current.ownerEmail,
      viewerEmail,
    });
    if (!permissions.canEdit) throw apiError(403, 'FORBIDDEN', 'Bạn không có quyền chỉnh sửa registration này.');
    const { id: ignoredId, ownerRole: ignoredRole, ownerEmail: ignoredEmail, ...patch } = clone(body.patch ?? {});
    const updated = { ...current, ...patch, updatedAt: new Date().toISOString() };
    records[index] = updated;
    await saveCollection('registrations', records);
    sendJson(response, 200, { item: toResource(updated, viewerRole, viewerEmail, 'registration') });
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'registrations' && parts[2] && request.method === 'DELETE') {
    const body = await readRequestBody(request);
    const records = await readCollection('registrations');
    const current = records.find((record) => record.id === parts[2]);
    if (!current) throw apiError(404, 'REGISTRATION_NOT_FOUND', `Không tìm thấy registration ${parts[2]}.`);
    const permissions = getResourcePermissions({
      viewerRole,
      ownerRole: current.ownerRole,
      ownerEmail: current.ownerEmail,
      viewerEmail,
    });
    if (!permissions.canDelete) throw apiError(403, 'FORBIDDEN', 'Bạn không có quyền xóa registration này.');
    await saveCollection('registrations', records.filter((record) => record.id !== parts[2]));
    sendJson(response, 200, { deleted: true });
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'course-requests' && request.method === 'GET') {
    const records = await readCollection('courseRequests');
    sendJson(response, 200, toListResponse(records, viewerRole, viewerEmail, 'courseRequest'));
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'course-requests' && !parts[2] && request.method === 'POST') {
    const body = await readRequestBody(request);
    if (viewerRole !== 'coordinator' && viewerRole !== 'chairman') {
      throw apiError(403, 'FORBIDDEN', 'Bạn không có quyền tạo yêu cầu khóa học.');
    }
    const item = {
      ...clone(body.item ?? {}),
      id: body.item?.id ?? `course-request-${Date.now()}`,
      ownerRole: viewerRole,
      ownerEmail: viewerEmail,
      createdAt: body.item?.createdAt ?? new Date().toISOString(),
    };
    const records = await readCollection('courseRequests');
    records.push(item);
    await saveCollection('courseRequests', records);
    sendJson(response, 201, { item: toResource(item, viewerRole, viewerEmail, 'courseRequest') });
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'course-requests' && parts[2] && request.method === 'PATCH') {
    const body = await readRequestBody(request);
    const records = await readCollection('courseRequests');
    const index = records.findIndex((record) => record.id === parts[2]);
    if (index < 0) throw apiError(404, 'COURSE_REQUEST_NOT_FOUND', `Không tìm thấy course request ${parts[2]}.`);
    const current = records[index];
    const permissions = getResourcePermissions({
      viewerRole,
      ownerRole: current.ownerRole,
      ownerEmail: current.ownerEmail,
      viewerEmail,
    });
    if (!permissions.canEdit) throw apiError(403, 'FORBIDDEN', 'Bạn không có quyền chỉnh sửa yêu cầu này.');
    const { id: ignoredId, ownerRole: ignoredRole, ownerEmail: ignoredEmail, ...patch } = clone(body.patch ?? {});
    const updated = { ...current, ...patch, updatedAt: new Date().toISOString() };
    records[index] = updated;
    await saveCollection('courseRequests', records);
    sendJson(response, 200, { item: toResource(updated, viewerRole, viewerEmail, 'courseRequest') });
    return;
  }

  if (parts[0] === 'api' && parts[1] === 'course-requests' && parts[2] && request.method === 'DELETE') {
    const body = await readRequestBody(request);
    const records = await readCollection('courseRequests');
    const current = records.find((record) => record.id === parts[2]);
    if (!current) throw apiError(404, 'COURSE_REQUEST_NOT_FOUND', `Không tìm thấy course request ${parts[2]}.`);
    const permissions = getResourcePermissions({
      viewerRole,
      ownerRole: current.ownerRole,
      ownerEmail: current.ownerEmail,
      viewerEmail,
    });
    if (!permissions.canDelete) throw apiError(403, 'FORBIDDEN', 'Bạn không có quyền xóa yêu cầu này.');
    await saveCollection('courseRequests', records.filter((record) => record.id !== parts[2]));
    sendJson(response, 200, { deleted: true });
    return;
  }

  throw apiError(404, 'NOT_FOUND', 'Không tìm thấy API endpoint.');
}

export { handleRequest };
