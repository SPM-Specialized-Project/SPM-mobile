# TSSA — triển khai theo báo cáo Autism

Cập nhật 04/10/2026. Đặc tả nguồn: [main.tex](../reports/main.tex) và [business-feasibility-autism-tutor-matching-vi.tex](../reports/business-feasibility-autism-tutor-matching-vi.tex). Bảng đối chiếu: [18 stories / 86 AC](acceptance-traceability.md).

## Phần đã có trong code

- Tài khoản TSSA riêng cho learner, guardian, tutor; scope coordinator theo nhóm; governance/privacy/safety theo quyền có thời hạn.
- Guardian link có bằng chứng và review, quyền theo mục đích, expiry, objection/dispute/revoke. Coordinator có thể gắn tài khoản learner đã xác minh để learner tự tham gia.
  Guardian chỉ có feedback/requests được xem booking receipt và phần tương ứng; giờ/địa điểm và nút quản lý lịch được ẩn khi thiếu schedule scope. Guardian chỉ có consent vẫn quản lý consent mà không được xem giá trị profile.
- Profile học tập, bản nháp, lịch sử trước/sau sửa, bản xem trước chia sẻ; không yêu cầu chẩn đoán. Consent theo purpose, field và thời hạn.
- Tutor registry, evidence reference, verification, expiry, availability, capacity, pause và từ chối ca. Family chỉ thấy hồ sơ giới thiệu tối thiểu.
- Request → lọc/ranking → coordinator review → family choice → proposal → tutor confirm. Có no-match, request-info, override, close, lịch sử, reschedule hai bên và chống trùng lịch trong hệ thống.
- Agenda/note phiên bản bổ sung, buổi không diễn ra, feedback riêng từng actor/phạm vi chia sẻ, pictogram/SKIP và rematch case mới.
- Case safety/quality có receipt ID, handler/status và audit; inbox, mute, public information offline, secure draft TTL 24 giờ và giảm chuyển động.
- Export/delete có handler, status, scope/ngoại lệ; inventory; audit append-only; role review/lock; metrics, công/chi phí điều phối thực tế; model card và kill switch.

AI mặc định tắt. Baseline TF-IDF và MANUAL chỉ chạy sau khi admin cấu hình quy trình và bằng chứng review luật. SHADOW không đổi thứ tự giới thiệu. MODEL_ASSISTED vẫn bắt buộc coordinator duyệt rồi gia đình lựa chọn. Provider/output lỗi, safety review hoặc chênh lệch no-match vượt ngưỡng được duyệt sẽ tắt AI và dùng baseline.

## Mở trong app

1. Dùng **Tạo tài khoản TSSA** ở màn đăng nhập để đăng ký learner/guardian/tutor. Đăng ký không tự xác minh tutor hoặc quan hệ guardian.
2. Đăng nhập bằng tài khoản vừa tạo: app mở workspace TSSA theo vai trò.
3. Tài khoản SPM hiện có mở biểu tượng **Hỗ trợ học tập TSSA** trên thanh đầu trang. Lecturer muốn tham gia dịch vụ chọn onboarding tutor; vai trò này chưa được verified.
4. Admin mở **Quản trị**, cấu hình nhóm dịch vụ và quy trình guardian/tutor/consent, người và tham chiếu duyệt luật. Cấp group + expiry cho coordinator; cấp privacy/safety scopes cho người xử lý.
5. Guardian tạo/link hồ sơ → coordinator xác minh → family hoàn thiện profile và consent → tạo request. Learner có tài khoản riêng tự tạo profile hoặc được coordinator gắn vào hồ sơ đã xác minh.
6. Tutor hoàn thiện registry → coordinator review. Coordinator lọc request, duyệt shortlist. Family chọn tutor/giờ → tutor xác nhận → ghi nhận/feedback/rematch.

Quản trị hiển thị **D-01…D-12** và release gates từ báo cáo. Các mục mặc định OPEN/PENDING_REVIEW. Điền tham chiếu trong app là ghi lại bằng chứng tổ chức đã thực hiện; app không tạo bằng chứng xác minh thực tế.

## Chạy local

Backend vẫn ở `C:/disk D/SPM-frontend`. Module mới: `backend/tssa/`. Máy hiện tại có Node `24.16.0`; implementation dùng `node:sqlite` và `DatabaseSync` ([Node documentation](https://nodejs.org/api/sqlite.html)).

```powershell
Set-Location 'C:\disk D\SPM-frontend'
node backend/server.mjs
```

Nếu backend đang chạy bằng watcher, các thay đổi module được nạp lại khi watcher restart. Session hiện tại dùng Map trong memory và hết hiệu lực sau restart hoặc 8 giờ; endpoint logout mới thu hồi bearer session ngay.

```powershell
Set-Location 'C:\disk D\SPM-mobile'
flutter run -d emulator-5554
```

APK debug dùng API mặc định `http://10.0.2.2:4000` cho Android emulator. Máy thật hoặc host khác cần `--dart-define=API_BASE_URL=https://<backend>` lúc run/build. Không mở phiên Flutter mới nếu máy đang có phiên debug cần giữ; dùng hot restart trong phiên đó để nạp thay đổi.

## Dữ liệu và quyền

- SQLite riêng `BACKEND_DATA_DIRECTORY/tssa.sqlite`, WAL + transaction cho mutation/state/idempotency. Mutation cần `idempotencyKey`; payload khác với key cũ trả 409. Replay vẫn kiểm tra scope/consent hiện hành.
- Record và idempotency payload dùng AES-256-GCM; record/actor lookup dùng HMAC index. Audit mới mã hóa actor/resource/metadata; triggers chặn UPDATE/DELETE audit, correction là event mới.
- Local development sinh `.tssa-data-key` trong data directory khi cần. File key và DB được ignore. **Không xóa/thay key khi còn DB cần đọc.** Trên Windows, quyền file local phụ thuộc ACL thư mục; review ACL/managed key là điều kiện production.
- Production yêu cầu `TSSA_DATA_KEY` gồm 64 ký tự hex, được cấp qua secret manager/environment của deployment. Không lưu key trong source hoặc log. Backup/rotation/khôi phục key phải được tổ chức review và diễn tập.
- Prototype record/response cũ được migrate payload/index khi mở DB, không đổi business revision. Audit cũ giữ nguyên để không sửa dấu vết; cần migration/archive được duyệt nếu đã có dữ liệu thật. Không coi migration payload là bằng chứng đã xóa page/WAL/backup cũ.
- Delete loại hồ sơ vận hành, request/match/booking/note/feedback/decision/effort và bản sao export/retry. Audit, căn cứ consent/link và safety case có ngoại lệ được giải thích. Backup/provider retention vẫn cần tổ chức thực hiện theo policy; không có scheduler tự xóa backup hoặc dữ liệu provider.
- Mobile không lưu profile server để xem offline. Nháp dùng platform secure storage, TTL 24 giờ, xóa khi logout hoặc server từ chối quyền. Trạng thái gửi chỉ thành công sau response server.

## API và source

Prefix chuẩn `/api/v1`; dùng auth bearer hiện tại, role TSSA và resource checks ở backend.

| Nhóm | Routes chính |
|---|---|
| Identity | `POST /accounts`, `GET /me`, `POST /onboarding`; auth login/me/logout ở `/api/auth/` |
| Learner | `GET/POST /learners`, `GET/PATCH /learners/:id/profile`, `GET /learners/:id/sharing` |
| Guardian/consent | `GET/POST/PATCH /guardian-links`, `GET/POST/PATCH /consents` |
| Tutor | `GET/POST/PATCH /tutors`, `PATCH /tutors/:id/verification` |
| Request/review | `/requests`, `/requests/:id/matches`, `/matches/:id`, `/matches/:id/decision`, `/requests/:id/decisions`, `/requests/:id/choice`, `/requests/:id/close`, `/requests/:id/effort` |
| Booking | `/bookings`, `/bookings/:id/respond`, `/reschedule`, `/accept-change`, `/notes`, `/feedback`, `/rematch` dưới booking ID |
| Privacy/safety | `/safety-cases`, `/privacy/:learnerId`, `/privacy/requests` và `/:id` |
| Governance | `/governance/policy`, `/bindings`, `/audit`, `/audit/correction`, `/models`, `/metrics?start=<ISO>&end=<ISO>` |
| Inbox/preferences | `/notifications`, `/preferences` |

Nguồn Flutter: `lib/features/tssa/{data,presentation}`; auth/network/cache hooks ở `lib/features/auth`, `lib/core/networking`, `lib/core/security`, `lib/app/app.dart`.

## Định nghĩa đo lường

- Cohort gồm request tạo trong khoảng `start/end`; dashboard ghi mẫu số và missingness. Bản hiện tại hiển thị từ đầu dữ liệu đến thời điểm hiện tại; API hỗ trợ chọn period.
  Mode counts dùng `effectiveMode` thực chạy, tách số run đang chờ; requested mode được giữ để đối soát fallback.
- Eligibility/no-match dùng lần lọc hoàn tất mới nhất của từng request, không chia tổng tài khoản hoặc số lần retry.
- Time-to-shortlist: `finishedAt - readyAt`; `readyAt` được ghi khi request đầy đủ/consent được gửi, nháp bị loại khỏi phép tính. Kết quả sẵn cho coordinator review, chưa phải thời điểm approve.
- Override đếm run được review có thứ tự/tập ứng viên/quyết định thay đổi. Family acceptance chia số request đã được giới thiệu shortlist; ghi riêng decline/chưa phản hồi.
- Buổi đầu hoàn tất chia booking đã có tutor nhận, loại proposal chưa nhận. Rematch sau buổi đầu chia request đã có buổi được ghi COMPLETED; nhóm lý do giữ trong case mới.
- Tỷ lệ phản hồi chia booking đã ghi COMPLETED/NOT_HELD. Safety response ghi thời gian tới IN_REVIEW, công bố số case có response.
- Metrics không chứng minh cải thiện học tập hay fairness. Hai subgroup hình thức học chỉ công bố khi có consent analytics, cả hai đủ tối thiểu 10 ca và privacy/fairness review; nhóm nhỏ bị ẩn.
- Effort/cost chỉ cộng ghi nhận vận hành đã nhập, có sample size/coverage. Khảo sát willingness-to-pay, economics, phỏng vấn và số liệu thị trường chưa được thực hiện.

## Ranh giới hoàn thành và bằng chứng

Kiểm thử ngày 04/10/2026: **114/114 test Flutter, 99/99 test backend, 1/1 integration Android đều qua**; analyzer sạch lỗi; APK debug build thành công. Luồng learner/tutor đã chạy với backend HTTP/SQLite cô lập; Android kiểm tra secure storage platform, logout route con, booking và agenda đọc lại từ API. Flutter web cũng đã lưu agenda qua UI và thấy bản ghi sau gửi.

Xem [báo cáo kiểm thử, coverage và cách chạy lại](validation-report.md), [bản đồ module](../architecture/module-map.md) và [bằng chứng test cho 86 AC](acceptance-traceability.md). APK: `build/app/outputs/flutter-apk/app-debug.apk`.

Coverage unit/widget TSSA là **824/1459 dòng (56,5%)**; nhiều nhánh/action còn chưa có test trực tiếp. AI test dùng provider embedding mô phỏng. Usability đại diện, benchmark NFR, model inference thực, security review và backup/delete rehearsal chưa thực hiện. Vì vậy **không đánh dấu toàn bộ 86 AC đã pass** hoặc đủ điều kiện phát hành pilot.

Push ngoài app chưa có provider/delivery được tích hợp; hiện có inbox bền vững và preview chung. Ngưỡng NFR của báo cáo, retention provider/backup, kênh khẩn/SLA, quan hệ guardian/verification tutor thật và quy trình theo độ tuổi cần evidence của tổ chức. Policy approval/model activation được khóa theo gate tương ứng trong app.
