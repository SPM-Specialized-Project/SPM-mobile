# Backend routes: input and output

Tài liệu này mô tả route trong `backend/routes.mjs` và `backend/codepulse.mjs` được đưa vào repo mobile ở commit khởi tạo backend. Các path bên dưới là URL đầy đủ trên server; frontend web đặt `baseURL` mặc định là `/api`.

## Quy tắc chung

- Body và response dùng JSON. Body rỗng được hiểu là `{}`.
- Ngoại trừ `GET /api/health`, `POST /api/auth/login` và `POST /api/auth/logout`, API yêu cầu `Authorization: Bearer <accessToken>`.
- Token là session trong bộ nhớ, hết hạn sau 8 giờ và mất hiệu lực khi restart server.
- Lỗi có dạng `{ "code": "...", "message": "...", "errors"?: { "field": "reason" } }`.
- Role, email và quyền truy cập được lấy từ session; các trường role/email do client tự gửi không cấp thêm quyền.
- `GET /api/codepulse/*` dùng query `courseId`, mặc định `13`. Dữ liệu CodePulse được giới hạn theo membership, classroom và role.
- `OPTIONS` được dùng cho CORS preflight. Server mặc định chỉ bind `127.0.0.1:4000`.

## Health và đăng nhập

| Method và route | Input | Output thành công |
| --- | --- | --- |
| `GET /api/health` | Không có | `200 { "ok": true, "service": "spm-backend" }` |
| `POST /api/auth/login` | `{ "email": "...", "password": "..." }` | `200 { "accessToken": "...", "user": { ... }, "role": "student\|lecturer\|coordinator\|chairman\|admin" }` |
| `GET /api/auth/me` | Bearer token | `200 { "user": { ... }, "role": "..." }` |
| `POST /api/auth/logout` | Bearer token; nếu thiếu/không hợp lệ response vẫn thành công với `revoked: false` | `200 { "revoked": true\|false }`; thu hồi đúng session trong bộ nhớ. |

Logout có tính idempotent: gọi lại với token đã thu hồi trả `{ "revoked": false }`.

## Trợ lý hướng dẫn

| Method và route | Input | Output / quyền |
| --- | --- | --- |
| `POST /api/assistant/messages` | `{ "question": "..." }`; tối đa 1.000 ký tự | Student và lecturer: hướng dẫn có nguồn từ kho tri thức theo đúng vai trò. Response gồm `status`, `answer`, `sources`, `mode` và `destination` tùy đoạn hướng dẫn; câu hỏi cần dữ liệu trực tiếp trả `unsupported`. |

Trợ lý không nhận role từ client và không truy cập dữ liệu lịch/hồ sơ riêng. `destination` chỉ là gợi ý điều hướng tới một tab đã có; app chỉ mở khi người dùng chạm nút, không sửa hoặc gửi dữ liệu. Khi đặt `ASSISTANT_OLLAMA_MODEL`, backend chỉ sinh câu trả lời cho đoạn `design` đã truy xuất bằng Ollama cục bộ; lỗi hoặc thiếu model sẽ trả nguyên đoạn truy xuất. Nếu không đặt model, `mode` là `retrieval`.

## Course API

| Method và route | Input | Output thành công / quyền |
| --- | --- | --- |
| `GET /api/courses` | Không có | `200 { items, viewerRole, permissions, meta }`; danh sách course mà session được phép xem. Admin chỉ nhận course DSA (13), khớp với route chi tiết được backend cho phép. |
| `GET /api/courses/:courseId/detail` | `courseId` trên path | `200 { course, detail }`; student cần membership ACTIVE, lecturer cần được phân công, coordinator/chairman xem được các khóa trong danh mục; admin chỉ xem chi tiết DSA course 13. |
| `PATCH /api/courses/:courseId/detail` | `{ "content": [section], "expectedRevision": 0 }` | Lecturer sở hữu khóa học hoặc manager được phép: `200 { course, detail }`; nội dung được lưu ở `course-details.json`, tăng `contentRevision`; trả `409 REVISION_CONFLICT` nếu revision đã cũ. Không xóa mục bài tập đã có bài nộp (`409 ASSIGNMENT_HAS_SUBMISSIONS`). |
| `GET /api/courses/:courseId/tutor-feedback` | `courseId` trên path | Lecturer được phân công: `200 { item: { courseComment, studentComments, revision } }`; nhận xét được lưu riêng theo khóa học. |
| `PATCH /api/courses/:courseId/tutor-feedback` | `{ "courseComment": "...", "studentComments": { "student@example.com": "..." }, "expectedRevision": 0 }` | Chỉ lecturer sở hữu khóa học; comment khóa học tối đa 5.000 ký tự, comment học viên tối đa 2.000 ký tự và chỉ nhận email trong roster. Thành công tăng `revision`; stale revision trả `409 REVISION_CONFLICT`. |
| `GET /api/courses/:courseId/submissions?assignmentId=:id` | Bắt buộc `assignmentId`; student có thể gửi `studentId`/`studentEmail` để kiểm tra scope | `200 { items, viewerRole, permissions, meta }`; student chỉ nhận bài của mình, lecturer nhận danh sách theo lớp. |
| `PATCH /api/submissions/:submissionId` | Student: `{ "submittedAt": "ISO-8601", "fileUrl": "..." }`; lecturer: `{ "score": 0, "feedback": "..." }` | `200 { "item": submission }`; quyền và các field được cập nhật phụ thuộc role. |

### Membership của lớp

Hai prefix `/api/classrooms/:classroomId/memberships` và `/api/courses/:courseId/memberships` được chấp nhận.

| Method và route | Input | Output thành công / quyền |
| --- | --- | --- |
| `GET /api/classrooms/:classroomId/memberships` | Không có | `200 { items, classroomId, viewerRole, permissions, availableStudents, meta }`; student cần membership ACTIVE của chính mình nhưng được xem danh sách lớp. |
| `POST /api/classrooms/:classroomId/memberships` | `{ "studentEmail": "..." }` hoặc `{ "email": "..." }` | Lecturer được phân công: `201` khi tạo mới, `200` khi đã tồn tại/kích hoạt lại; body `{ item, created, reactivated }`. |
| `PATCH /api/classrooms/:classroomId/memberships/:membershipId` | `{ "status": "ACTIVE" }` hoặc `{ "status": "REVOKED" }`; bỏ `status` mặc định là `REVOKED` | Lecturer được phân công: `200 { "item": membership }`. |
| `DELETE /api/classrooms/:classroomId/memberships/:membershipId` | Không cần body | Tương đương revoke; `200 { "item": membership }`. |

## Session, registration và course request

Các endpoint list trả `{ items, viewerRole, permissions, meta }`. Mutation trả `{ item }`, ngoại trừ delete trả `{ "deleted": true }`. `item` và `patch` là object nghiệp vụ; backend tự đặt ID, owner và thời gian khi thiếu.

| Resource | List và query | Create body | Update body | Quyền chính |
| --- | --- | --- | --- | --- |
| Session | `GET /api/sessions?courseId=:id` (`courseId` tùy chọn) | `POST /api/sessions` — `{ "item": { ... } }` | `PATCH /api/sessions/:id` — `{ "patch": { ... } }` | Lecturer/coordinator/chairman tạo; owner hoặc manager sửa/xóa. Student chỉ xem session thuộc lớp mình. |
| Registration | `GET /api/registrations?registrationType=:role` (`registrationType` tùy chọn) | `POST /api/registrations` — `{ "registrationType": "student\|lecturer", "item": { ... } }` | `PATCH /api/registrations/:id` — `{ "patch": { ... } }` | Coordinator/chairman tạo cho role bất kỳ; student/lecturer tạo registration cùng role; owner hoặc manager sửa/xóa. |
| Course request | `GET /api/course-requests` | `POST /api/course-requests` — `{ "item": { ... } }` | `PATCH /api/course-requests/:id` — `{ "patch": { ... } }` | Coordinator/chairman tạo; owner hoặc manager sửa/xóa. |

### Yêu cầu buổi học

| Method và route | Input | Output thành công / quyền |
| --- | --- | --- |
| `GET /api/session-requests` | Không có | `200 { items, viewerRole, permissions, meta }`; student chỉ xem yêu cầu của mình, lecturer chỉ xem yêu cầu thuộc khóa được phân công, coordinator/chairman xem toàn bộ. |
| `POST /api/session-requests` | `{ "courseId": "...", "requestType": "new\|makeup\|absent", "title": "...", "description": "...", "proposedAt": "ISO-8601" }` | Student có membership ACTIVE; thời gian phải trong tương lai và tối đa một năm; `201 { item }`. Ghi vào `session-requests.json`. |
| `PATCH /api/session-requests/:id` | `{ "status": "approved\|declined", "reason"?: "..." }` | Lecturer được phân công hoặc coordinator/chairman; chỉ xử lý yêu cầu `pending`; từ chối cần lý do. Trả `409` nếu đã được xử lý. Duyệt yêu cầu không tự tạo lịch buổi học. |

## CodePulse API

Tất cả route CodePulse đều có prefix `/api/codepulse`. `courseId` là query parameter (mặc định `13`), không phải segment của path. Response list thường là `{ "items": [...] }`; response một resource là `{ "item": ... }`.

### Term, classroom và catalogue

| Method và route | Input | Output thành công |
| --- | --- | --- |
| `GET /api/codepulse/terms?courseId=13` | Query tùy chọn | `200 { items }` |
| `POST /api/codepulse/terms?courseId=13` | `{ "name", "startDate", "endDate", "resetDate", "id"? }` | `201 { item }` |
| `PATCH /api/codepulse/terms/:termId?courseId=13` | `{ "patch": { ...term fields... } }` | `200 { item }` |
| `DELETE /api/codepulse/terms/:termId?courseId=13` | Không cần body | `200 { "deleted": true }` |
| `GET /api/codepulse/classrooms?courseId=13` | Query tùy chọn | `200 { items }`; item kèm term. |
| `POST /api/codepulse/classrooms?courseId=13` | `{ "name", "termId", "description"?, "lecturerEmail"?, "id"? }` | `201 { item }`; course được lấy từ query. |
| `GET /api/codepulse/classrooms/:classroomId` | Không có | `200 { item }` |
| `PATCH /api/codepulse/classrooms/:classroomId` | `{ "patch": { "name"?, "description"?, "status"?, "termId"?, "lecturerEmail"? } }` | `200 { item }`; lecturer chỉ sửa được field được phép. |
| `DELETE /api/codepulse/classrooms/:classroomId` | Không cần body | `200 { "deleted": true, "item": ... }`; admin only. |
| `GET /api/codepulse/classrooms/:classroomId/dashboard` | Không có | `200 { "classroom": ..., "activeMembers": number }`; manager được phân công. |
| `GET /api/codepulse/classrooms/:classroomId/problems/:problemId` | Không có | `200 { item }`; student không nhận hidden test cases/runner trace. |
| `GET /api/codepulse/classrooms/:classroomId/assignment-versions` | Không có | `200 { items }`; student chỉ nhận dữ liệu an toàn và test case public. |
| `GET /api/codepulse/classrooms/:classroomId/assignment-versions/:versionId/history` | Không có | `200 { item, submissions }`; lecturer/manager được phân công. |

### LAB và practice window

| Method và route | Input | Output thành công |
| --- | --- | --- |
| `GET /api/codepulse/classrooms/:classroomId/labs` | Không có | `200 { items }` |
| `POST /api/codepulse/classrooms/:classroomId/labs` | `{ "name", "startAt", "endAt", "assignments": [{ "assignmentVersionId", "mandatory", "openAt", "closeAt" }], "description"?, "id"? }` | `201 { item }`; cần lecturer được phân công và academic term ACTIVE. |
| `PATCH /api/codepulse/classrooms/:classroomId/labs/:labId` | `{ "status": "SCHEDULED\|LIVE\|COMPLETED\|CANCELLED", "expectedStateVersion": number }` | `200 { item }`; stale version trả `409 STALE_LAB_STATE`. |
| `PATCH /api/codepulse/classrooms/:classroomId/labs/:labId/assignments/:labAssignmentId/practice-window` | `{ "expectedVersion": number, "openAt"?: ISO-8601, "closeAt"?: ISO-8601, "status"?: "OPEN\|CLOSED", "openNow"?: boolean }` | `200 { item }`; stale version trả `409 STALE_PRACTICE_WINDOW`. Có thể bọc các field trong `{ "patch": { ... } }`. |
| `GET /api/codepulse/practice-window-audit?classroomId=:id&labId=:id` | Query tùy chọn; admin only | `200 { items }` |
| `GET /api/codepulse/practice-activities?classroomId=:id&labId=:id` | Query tùy chọn; admin/lecturer | `200 { items }` |

### Assignment, bài nộp và workspace

`/problems` là alias cũ của `/assignments` cho các route assignment tương ứng.

| Method và route | Input | Output thành công |
| --- | --- | --- |
| `GET /api/codepulse/classrooms/:classroomId/assignments?view=student` | Query `view` tùy chọn | `200 { items }`; student chỉ xem assignment đã publish. |
| `POST /api/codepulse/classrooms/:classroomId/assignments` | `{ "title", "description", "constraints", "inputFormat", "outputFormat", "runtime", "referenceSolution", "testCases", "comparator", "cpuTimeLimitMs"?, "memoryLimitMb"? }` | `201 { item }`; tạo ở trạng thái DRAFT. |
| `GET /api/codepulse/classrooms/:classroomId/assignments/:assignmentId` | Không có | `200 { item }` |
| `PATCH /api/codepulse/classrooms/:classroomId/assignments/:assignmentId` | `{ "patch": { ...assignment fields... } }` | `200 { item }` |
| `DELETE /api/codepulse/classrooms/:classroomId/assignments/:assignmentId` | Không cần body | `200 { "deleted": true, "item": ... }` |
| `POST /api/codepulse/classrooms/:classroomId/assignments/:assignmentId/verify` | `{ "referenceSolution"? }` | `200 { item, "verification": { "status": "VERIFIED", "testCaseCount": number } }` |
| `POST /api/codepulse/classrooms/:classroomId/assignments/:assignmentId/publish` | Không cần body | `200 { item }`; tạo version đã publish. |
| `POST /api/codepulse/classrooms/:classroomId/assignments/:assignmentId/run` | `{ "sourceCode"?, "testCaseIds"? }`; query LAB tùy chọn: `labId`, `labAssignmentId` | `200 { "item": { assignmentId, assignmentVersionId, runtime, results, passedCount, totalCount } }` |
| `GET /api/codepulse/classrooms/:classroomId/assignments/:assignmentId/submissions` | Student only | `200 { items }` — bài nộp của student hiện tại. |
| `POST /api/codepulse/classrooms/:classroomId/assignments/:assignmentId/submissions` | `{ "sourceCode": "..." }` | `201 { item }`; student nộp assignment đã publish, không dùng cho LAB. |
| `POST /api/codepulse/classrooms/:classroomId/labs/:labId/assignments/:labAssignmentId/submit` | `{ "sourceCode"? }`; nếu thiếu, backend dùng code đã lưu | `201 { item }` |
| `GET /api/codepulse/classrooms/:classroomId/labs/:labId/assignments/:labAssignmentId/submissions` | Không có | `200 { items }`; student chỉ xem bài của mình. |
| `GET /api/codepulse/classrooms/:classroomId/workspace?assignmentId=:id` | Student membership; query assignmentId | `200 { item }`; tạo workspace nếu chưa có. |
| `GET /api/codepulse/classrooms/:classroomId/workspace?labId=:id&labAssignmentId=:id` | Student membership; cả hai query cần thiết cho LAB | `200 { item, practiceWindow }` |
| `GET /api/codepulse/workspaces/:workspaceId` | Owner student hoặc manager được phép xem | `200 { item, practiceWindow? }` |
| `PATCH /api/codepulse/workspaces/:workspaceId` | `{ "sourceCode": "..." }` | `200 { item }` |
| `POST /api/codepulse/workspaces/:workspaceId/execute` | `{ "sourceCode"? }`; thiếu thì chạy code đã lưu | `200 { item }`; kết quả thực thi nằm trong item. |
| `POST /api/codepulse/workspaces/:workspaceId/hints/:hintId` | Không cần body | `200 { item }`; ghi nhận hint đã mở. |
| `PATCH /api/codepulse/memberships/:membershipId` | `{ "status": "active\|revoked" }`; admin only | `200 { "item": { "id", "status" } }` |

## Ví dụ request/response

```http
POST /api/auth/login
Content-Type: application/json
```

```json
{
  "email": "student@gmail.com",
  "password": "<development-password>"
}
```

```json
{
  "accessToken": "<session-token>",
  "user": { "id": "...", "email": "student@gmail.com", "role": "student" },
  "role": "student"
}
```

Để gọi route cần đăng nhập, gửi `Authorization: Bearer <session-token>` và `Content-Type: application/json` khi có body. Seed users trong `backend/data/seeds.mjs` chỉ dành cho development.

## Chưa được backend này cung cấp

- Flutter TSSA repository gọi `/api/v1/*` (accounts, profiles, consent, matching, bookings, privacy/governance), nhưng các route đó không có trong backend được chuyển ở đây. Các tài liệu TSSA và kết quả kiểm thử ngày 04/10/2026 thuộc snapshot backend trước; không phải xác nhận cho backend hiện tại.
- Session bị thu hồi khi gọi `POST /api/auth/logout`; token cũng hết hạn sau 8 giờ hoặc khi server restart.
- Route không được nhận diện sẽ trả error; xem mã `code` và HTTP status từ response để xử lý.
