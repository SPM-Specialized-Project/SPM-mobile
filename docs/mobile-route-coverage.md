# Mobile route coverage

This map follows the web inventory in SPM-frontend/docs/flutter-mobile-plan/00-system-discovery/web-screen-inventory.md.
The Flutter app uses a role-aware tab shell and Navigator pages instead of
copying the web URLs as deep links. It is reconciled against the current
`SPM-frontend/frontend/src/routeTree.gen.ts` route tree (30 registered paths;
route aliases are grouped below).

| Web route | Mobile entry | Current behavior and boundary |
| --- | --- | --- |
| /, /course, /dashboard | Auth gate → Courses tab | Role-specific course list from /api/courses; admin sees only DSA course 13, the only course detail route allowed to that role. |
| /login | Login screen | Email/password login; no incomplete Google OAuth button. |
| /course/:id | Course card → course detail | Student, lecturer, and manager detail use their API-scoped views. Tutor content edits persist through revision-checked `PATCH /api/courses/:id/detail`; assignment IDs with submission history are preserved. |
| /course/:id/roster | Course detail → Roster tab | Student read-only list; lecturer can manage membership when the API grants permission; manager sees the API roster. |
| /course/:id/rating | Course detail → Feedback tab | Student feedback is encrypted on this device; tutor feedback is saved through the owner-only, revision-checked `/api/courses/:id/tutor-feedback` endpoint. |
| /course/:id/rating/:ratingid/:index | Feedback tab → Xem đánh giá đã lưu | Opens a read-only detail of the signed-in student's own local assessment; there is no shared student-rating endpoint. |
| /course/:id/submissions | Course detail → Submissions tab | Student submissions are scoped to their account; lecturer review follows per-record permissions. |
| /course/:id/:name | Course submissions → assignment filter | Student and tutor submission lists can select a specific assignment; the filter uses the API assignment ID when available and narrows the list before opening a submission detail. |
| /course/:id/:name/:stuname | Submission card → detail/review | Opens the selected student's submission; lecturer grading uses API permissions and the response shows only the student fields returned for that course. |
| /course/:id/stastical | Student course → Tiến độ; lecturer course → Xem thống kê | Student sees personal submission progress; tutor sees grade distribution grouped from API-returned scores within 0–10, not sample charts. |
| CodePulse within /course/13 | Course detail → Luyện code / CodePulse tabs | Entry is based on the course code and CodePulse API permissions. |
| /schedule | Schedule tab | Student, lecturer, and coordinator/chairman views use the signed-in role. |
| /schedule/:id | Session card → details | Shows the server session; mutations are enabled only when returned permissions allow them. |
| /schedule/request | Lecturer or manager schedule → create session | Persists through POST /api/sessions. |
| /schedule/request/new | Student More → Yêu cầu buổi học | Students submit new-session, makeup, or absence requests to `POST /api/session-requests`; drafts remain account-scoped and local until submitted. The linked request history shows server statuses separately from local drafts. |
| Session request review | Lecturer/coordinator/chairman More → Yêu cầu buổi học | `GET /api/session-requests` is role-scoped; authorized reviewers can approve or decline pending requests. Approval confirms the request only; creating a dated session remains a separate action in the schedule flow. |
| /schedule/history | More → Lịch sử buổi học | Reads API sessions and role-scoped session requests, with independent loading/error states and filters for the session list. |
| /schedule/history/:id | History item → session or request detail sheet | Opens the selected API-backed session or request, including review status and response reason; reviewers process pending requests from Yêu cầu buổi học. |
| /register-session | More → registration screen → create form | Student and lecturer registration forms create API records; managers review records or create course requests. |
| /registration-history | More → registrations | Own-request or management queue is scoped by role and backend permissions. |
| /overview | Coordinator/chairman More → Ghép lớp | Shows API sessions grouped by course and pending student/tutor requests with explicit subject, language, format, and location matching; no persisted assignment is claimed. |
| /library, /library/:query | Library tab → search/details | Clearly marked sample catalog; no live HCMUT catalog API is available. |
| /profile | Account button | Shows identity and role from the authenticated session; no profile-edit API exists. |
| /profile/:id | Roster member or tutor submission detail → profile | Shows only name/email and course membership returned by the roster or submission API; no additional profile API exists. |
| /statistical | Coordinator/chairman Courses tab | Lists courses returned by the API. |
| /statistical/overview | More → Thống kê theo khóa học | Shows API-backed member, assignment, session counts, and latest session time for each course. |
| /statistical/reports | More → Báo cáo hoạt động | Shows counts from courses, sessions, and registrations returned to the account. No grades/period aggregate endpoint exists, so report charts are not fabricated. |
| /statistical/:id | Report card → course report detail | Shows course roster, session, and related-registration counts; links to the course detail. |
| /system-monitoring | Admin More → Giám sát hệ thống | Checks /api/health only. CPU, memory, uptime, and logs are not exposed by the backend. |

Notifications and chat have interactive More screens based on the web UI.
The sample notices and contacts are explicitly labeled; read states, groups,
and message drafts are saved only on this device and are not sent to others.

## RAG assistant reference

The Vietnamese retrieval-only assistant follows the knowledge and retrieval
prototype from [the referenced commit](https://github.com/Tung-Quan/mobile-HCMUT/commit/8ee8d54b5cf436de96e10d853f8cb90f7d438e0e).
The Flutter app reads assets/assistant/knowledge_vi.md and includes source IDs.
It calls the authenticated `/api/assistant/messages` endpoint for optional
Ollama generation; when the endpoint is unavailable, it falls back to local
retrieval. The backend filters guides by the signed-in role and never claims
live data access or executes actions on the user's behalf. Verified guide
metadata can offer a user-confirmed shortcut to the matching existing app tab;
the shortcut only navigates and cannot mutate data.

## Report-originated TSSA screens

TSSA is a proposed service described in the report, not a route in the current
SPM-frontend inventory. The app includes its role-specific screens, but they
require `/api/v1/me` and other `/api/v1/*` resources that the current Node
backend snapshot does not provide. When identity loading fails, the entry now
shows an explicit unavailable state and an offline service-principles page;
it does not show fixture profiles or claim that TSSA requests are live.
