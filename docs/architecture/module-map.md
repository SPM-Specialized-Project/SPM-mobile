# Bản đồ module SPM-mobile và TSSA

Đối chiếu source và kiểm thử ngày **04/10/2026**. Kết quả chạy nằm trong [báo cáo kiểm thử](../tssa/validation-report.md). TSSA là domain hỗ trợ học tập theo báo cáo Autism; SPM là các luồng lớp/môn học hiện có.

## 1. App Flutter

```mermaid
flowchart TB
    Main[main.dart · ProviderScope] --> App[MyApp · AuthenticationGate]
    App --> Auth[AuthController · login / restore / logout]
    Auth --> Session[AuthSession · vai trò]
    Session --> SPM[AuthenticatedAppShell]
    Session -->|tssa_learner / guardian / tutor| TSSA[TssaScreen]
    SPM -->|Biểu tượng Hỗ trợ học tập TSSA| TSSA

    subgraph Existing[Module SPM]
      SPM --> Student[Student · lớp / lịch / bài nộp / đăng ký]
      SPM --> Tutor[Tutor SPM · lớp dạy / chỉnh sửa môn / roster / DSA]
      SPM --> Management[Management · khóa học / lịch / yêu cầu môn]
      SPM --> Admin[Admin · CodePulse · term / classroom / assignment / LAB]
      SPM --> Account[Tài khoản · dữ liệu AuthSession]
      Learning[Learning · model Course / Session / Submission]
      Student --> Learning
      Tutor --> Learning
      Catalog[Component catalog · showcase riêng]
      Catalog --> Health[Backend status · health API]
    end

    subgraph Autism[Module TSSA]
      TSSA --> Profiles[Hồ sơ · guardian link · consent · xác minh tutor]
      TSSA --> Workflows[Yêu cầu · matching review · booking · notes · feedback · rematch]
      TSSA --> Governance[Safety · privacy · inbox · policy · audit · metrics · model card]
      Profiles --> Forms[TssaForm · validate / nháp / retry key / server acknowledgement]
      Workflows --> Forms
      Governance --> Forms
      Profiles --> Repo[TssaRepository · API v1]
      Workflows --> Repo
      Governance --> Repo
      Forms --> Repo
    end

    Student --> Core[Dio · Bearer token · session epoch]
    Tutor --> Core
    Management --> Core
    Admin --> Core
    Health --> Core
    Repo --> Core
    Auth --> Core
    Core --> API[Node REST backend]
    Security[Secure storage · token và nháp TTL 24h] --> Auth
    Security --> Forms
```

### Source và trách nhiệm

| Module | Source | Trách nhiệm thực tế |
|---|---|---|
| Bootstrap/theme | `lib/main.dart`, `lib/app/` | ProviderScope, auth gate, theme, reset toàn bộ route khi logout/expiry, reduce motion |
| Core | `lib/core/{config,networking,security}/` | API base URL, Dio, token, 401/locked, draft TTL, đổi epoch để loại dữ liệu phiên cũ |
| Auth | `lib/features/auth/` | Login, restore session, logout server/local, chuẩn hóa role SPM và role TSSA riêng |
| Navigation/account | `lib/features/navigation/` | Tab SPM theo role; `IndexedStack` giữ màn hình; account hiện dùng AuthSession, chưa là module profile CRUD riêng |
| Student | `lib/features/student/` | Lớp, lịch, bài nộp, đăng ký của student |
| Tutor SPM | `lib/features/tutor/` | Các lớp được giao, nội dung môn có quyền sửa, danh sách lớp, bài nộp/điểm, thống kê/đánh giá, DSA assignment/LAB |
| Management | `lib/features/management/` | Courses, sessions, registrations, course requests cho coordinator/chairman |
| Admin CodePulse | `lib/features/admin/` | Term/classroom và thao tác CodePulse theo backend authorization |
| Learning | `lib/features/learning/domain/` | Model dùng chung; không phải màn hình hay dịch vụ tự chạy |
| TSSA profiles | `lib/features/tssa/presentation/tssa_profiles.dart` | Learner profile, guardian purpose scopes, consent preview, tutor registry/verification |
| TSSA workflows | `lib/features/tssa/presentation/tssa_workflows.dart` | Requests, coordinator decisions, family choices, bookings, notes, feedback, rematch |
| TSSA governance | `lib/features/tssa/presentation/tssa_governance.dart` | Case receipt, privacy export/delete, inbox/preferences, policy/roles/audit/model/metrics |
| TSSA common/data | `tssa_form.dart`, `tssa_ui.dart`, `data/tssa_repository.dart` | Form, draft/retry, polling/lifecycle, trạng thái và gọi `/api/v1` |
| Health/showcase | `lib/features/{backend_status,component_catalog}/` | Health API và UI tham khảo riêng; dữ liệu showcase không phải hồ sơ nghiệp vụ |

SPM dùng các lớp `presentation → application → data/domain`. TSSA hiện dùng `presentation → TssaRepository` với Map payload; chưa có lớp typed domain/application tách riêng. Đây là cấu trúc hiện có, không phải đề xuất đã được triển khai.

## 2. Backend và dữ liệu

```mermaid
flowchart LR
  Mobile[Flutter · Dio] --> HTTP[server.mjs / http.mjs]
  Web[React web SPM] --> HTTP
  HTTP --> Auth[auth.mjs · Bearer session Map · 8 giờ]
  Auth --> Routes[routes.mjs · role / resource dispatch]
  Routes --> Legacy[SPM routes · CodePulse · matching/service.mjs]
  Legacy --> JSON[Seed/catalog và JSON collections]
  Routes --> V1[tssa/routes.mjs · actor / transaction / replay guard]
  V1 --> Profiles[tssa/profiles.mjs]
  V1 --> Workflows[tssa/workflows.mjs]
  V1 --> Governance[tssa/governance.mjs]
  Profiles --> Access[tssa/access.mjs · link / group / consent / field scope]
  Workflows --> Access
  Governance --> Access
  Workflows --> Queue[SQLite match record · QUEUED / RUNNING / lease]
  Queue --> Worker[tssa/matching.mjs · worker mỗi giây]
  Worker --> Rules[Hard constraints + TF-IDF / MANUAL]
  Worker -.->|Có gate và cấu hình| Embedding[Adapter BGE-M3 · HTTP]
  Worker --> Monitor[tssa/safety-monitor.mjs · rollback / kill switch]
  Governance --> Monitor
  Profiles --> Store[tssa/store.mjs]
  Workflows --> Store
  Governance --> Store
  Worker --> Store
  Access --> Store
  Store --> SQLite[SQLite WAL · AES-256-GCM payload · HMAC index]
  Store --> Integrity[Revision / idempotency / append-only audit]
```

- Các module backend trên chạy trong **một tiến trình Node**, không phải microservices riêng.
- Matching SPM cũ và matching TSSA là hai đường xử lý khác nhau. TSSA có job bền vững trong SQLite và worker nội bộ; không dùng message broker bên ngoài.
- Web tham chiếu `/course/13` là UI SPM. Không suy ra web đã có toàn bộ màn hình TSSA từ việc backend có `/api/v1`.
- SQLite lưu account, binding, learner, tutor, link, consent, request, run, decision, booking, note, feedback, case, privacy request, inbox, preferences, effort, policy và model card. Audit/idempotency có bảng riêng.
- Session token vẫn ở RAM; restart giữ hồ sơ/job nhưng yêu cầu đăng nhập lại. Mã hóa DB không chứng minh backup, ACL hay quản lý key production đã được kiểm duyệt.

## 3. Luồng nghiệp vụ chính

```mermaid
flowchart TD
  Profile[Hồ sơ học tập] --> Consent[Consent theo purpose / field / expiry]
  Consent --> Request[Yêu cầu đầy đủ · SUBMITTED]
  Verified[Tutor active + verified + còn hạn] --> Filter[Lọc điều kiện cứng]
  Request --> Filter
  Filter -->|Không có ứng viên| NoMatch[NO_MATCH · coordinator xử lý]
  Filter --> Rank[TF-IDF / thủ công / model có gate]
  Rank --> Review[Coordinator duyệt và ghi lý do]
  Review --> Family[Gia đình xem shortlist đã duyệt]
  Family -->|Đồng ý| Proposal[Đề xuất booking · PENDING_TUTOR]
  Proposal -->|Tutor nhận + không trùng lịch| Confirm[CONFIRMED]
  Confirm --> Notes[Agenda / summary · phần được chia sẻ]
  Notes --> Outcome[COMPLETED / NOT_HELD]
  Outcome --> Feedback[Feedback riêng từng người và quyền chia sẻ]
  Feedback --> Rematch[Case ghép lại mới · liên kết booking cũ]
  Rematch --> Request
  Confirm -->|Đề xuất đổi giờ| Proposal
  Proposal -->|Tutor rút / từ chối| Review
  Consent -->|Thu hồi hoặc link không còn quyền| Block[Hủy matching / khóa chia sẻ mới / NEEDS_INFO]
```

Tutor chỉ mở learner profile sau khi nhận booking, với consent còn hiệu lực và đúng field. Guardian có quyền `feedback/requests` nhưng thiếu `schedule` chỉ thấy booking receipt; quyền `consent` không tự cấp quyền đọc giá trị profile. Mọi quyền thật được kiểm tra tại backend.

## 4. Tab TSSA theo vai trò

| Vai trò | Tab 1 | Tab 2 | Tab 3 | Tab 4 |
|---|---|---|---|---|
| Learner / Guardian | Hồ sơ | Yêu cầu | Lịch | Hỗ trợ |
| Tutor TSSA | Hồ sơ | Ca được mời | Lịch | Hỗ trợ |
| Coordinator | Queue | Xác minh | Lịch | Hỗ trợ |
| Admin | Quản trị | Audit | Chất lượng | Hỗ trợ |
| Unassigned | Chọn vai trò tự đăng ký | — | — | — |

TSSA chọn trang theo tab, có polling và reload theo lifecycle. SPM shell dùng `IndexedStack`; không gán hành vi giữ state của SPM cho TSSA.

## 5. Giới hạn đã xác định

Kiểm thử tự động và các lần chạy live được ghi riêng trong [validation-report.md](../tssa/validation-report.md). Các quyết định tổ chức, usability với người đại diện, push provider, backup/retention và chất lượng model thật chưa được chứng minh bằng các test này. Policy/model mặc định vẫn khóa theo evidence gate.
