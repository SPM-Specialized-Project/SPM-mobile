# Tutor course workspace

Reference: `http://localhost:3000/course/13`, inspected while signed in as the
seeded lecturer account. The mobile detail page follows the DSA LAB tabs:

- Tổng quan: view the complete section payload; enable Chỉnh sửa to add, edit,
  reorder or remove sections, then save or discard the draft.
- Danh sách lớp: load memberships, add provisioned students, revoke access and
  reactivate the same membership. Mutations require edit mode and API permission.
- Đánh giá: edit a separate comment per active student and a course comment.
- Terms and classrooms: filter terms; select an assigned classroom; edit its
  name/description/status; author, verify and publish assignments; create LABs
  with ordered published versions; change LAB states and per-problem practice
  windows.
- Bài nộp: view and grade submissions for this course only.
- Xem thống kê: calculate submission counts and average scores from the course
  submission response. No synthetic attendance or rating metrics are generated.

Other tutor courses have the same tabs except Terms and classrooms. Term and
classroom creation remain admin functions according to the existing backend.
Materials use source paths/URLs; there is no multipart upload contract.

## API support

The sibling backend at `C:\disk D\SPM-frontend` adds:

- `PATCH /api/courses/:id/detail`: `{content, expectedRevision}`; returns the
  existing detail shape with `contentRevision`. GET detail/submissions use the
  persisted section content. A submission section with history cannot be removed.
- `GET /api/courses/:id/tutor-feedback`: the assigned tutor's comments/revision.
- `PATCH /api/courses/:id/tutor-feedback`:
  `{courseComment, studentComments, expectedRevision}`. Student comment keys must
  be active roster email addresses. Each tutor's feedback has its own revision.

New data is stored in `backend/data/course-workspaces.json` (runtime file ignored
by Git). The backend checks the authenticated lecturer's assignment to the course;
client-supplied roles are not used. Stale revisions return 409. CodePulse updates
retain `expectedStateVersion` and `expectedVersion` concurrency checks.

Run the sibling backend and hot restart the mobile app after updating it:

```powershell
# In C:\disk D\SPM-frontend
npm run backend:watch

# In C:\disk D\SPM-mobile (or press R in an existing flutter run session)
flutter run -d emulator-5554
```

The Android emulator uses the existing `http://10.0.2.2:4000` API default.
