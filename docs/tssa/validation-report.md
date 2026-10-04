# Báo cáo kiểm thử và chạy thử SPM-mobile / TSSA

Ngày: **04/10/2026**. Workspace: `C:\disk D\SPM-mobile`; backend: `C:\disk D\SPM-frontend\backend`.
Đặc tả: [báo cáo Autism](../reports/main.tex), [18 stories / 86 AC](acceptance-traceability.md).
Kiến trúc: [bản đồ module và luồng dữ liệu](../architecture/module-map.md).

## 1. Kết quả đã thực hiện

| Kiểm tra | Kết quả | Bằng chứng |
|---|---|---|
| Flutter unit/widget + coverage | **114/114 qua**, không skip | [flutter-final.log](../../output/tssa-validation-20261004/flutter-final.log) |
| Backend toàn bộ `node --test` | **99/99 qua**, không skip; 11 là test cha, 88 là case lá | [backend-final.log](../../output/tssa-validation-20261004/backend-final.log) |
| Flutter analyzer cho `lib test integration_test` | **Không có lỗi/cảnh báo/lint** | [analyze-final.log](../../output/tssa-validation-20261004/analyze-final.log) |
| APK debug của app chính | **Build thành công** | [apk-build-final.log](../../output/tssa-validation-20261004/apk-build-final.log) |
| Android integration trên emulator | **1/1 kịch bản tổng hợp qua** | [android-integration-final.log](../../output/tssa-validation-20261004/android-integration-final.log) |
| Flutter web trên browser, 390 × 844 | Login learner/tutor, logout, mở booking, gửi agenda và thấy bản ghi đã lưu | [ảnh agenda đã lưu](../../output/tssa-validation-20261004/browser-agenda-saved.png) |
| `git diff --check` ở mobile/backend | Không phát hiện lỗi whitespace; Git có cảnh báo chuyển LF/CRLF | Kiểm tra local, không commit/push |

Flutter 3.47.6, Dart 3.13.5, Node v24.16.0, Windows; emulator `emulator-5554`, Android 17 / API 37.
APK chính ở `build/app/outputs/flutter-apk/app-debug.apk`. Đây là bản debug, chưa là release ký để phát hành.

64 test Flutter và 22 test backend đã có trước lượt kiểm thử này. Lượt này bổ sung **50 test Flutter**, **77 test node TSSA** (gồm test cha), và một integration test Android.
Các luồng SPM có test unit/widget và API hiện có; chạy UI live trong lượt này tập trung TSSA, không chứng minh toàn bộ luồng SPM `/course/13` trên thiết bị.

## 2. Cách cô lập dữ liệu

- Mỗi bộ test backend tạo Node HTTP server thật và SQLite riêng trong `%TEMP%\spm-tssa-test-*`, port riêng, tài khoản `@example.test` và dữ liệu học tập giả lập. Teardown chờ child process đóng rồi xóa thư mục tạm.
- Helper `backend/testing/tssa-control.mjs` chỉ chạy khi `NODE_ENV=test` và data directory thuộc đúng nhóm thư mục tạm. Helper không được import vào server; không có endpoint HTTP cho thao tác này.
- Các tình huống expiry/past session cập nhật bản ghi fixture, không thay đổi đồng hồ Windows. Restart test chỉ restart tiến trình backend của fixture.
- `test://...` trong policy/model/verification là bằng chứng giả để kiểm tra gate của fixture. Không dùng chúng làm phê duyệt tổ chức thật.
- Chạy live dùng backend port **4317**, Flutter web port **4318**, SQLite fixture riêng. Không chạy mutation lên dữ liệu backend người dùng ở port 4000.
- Android chạy bản sao project có package **`com.example.spm_mobile.validation`**, label **SPM Validation**; test chỉ xóa secure storage của package riêng này. App chính dùng package khác.
- Dịch vụ test port 4317/4318 và tab browser tạm đã dừng/đóng sau khi lấy bằng chứng; viewport browser đã reset. Android validation package không còn trong danh sách package của emulator sau chạy. Thư mục `output/.../android-app` và `%TEMP%\spm-tssa-test-vt8Io1` vẫn còn: công cụ tự động chặn lệnh xóa đệ quy dù đã kiểm tra đường dẫn chính xác. Chưa xác nhận cleanup filesystem. Muốn chạy lại Android nên tạo fixture mới; metadata cũ không phải dịch vụ vẫn đang chạy.

## 3. Các test nghiệp vụ TSSA

Mã ở đầu tên test giúp đối chiếu [bảng AC](acceptance-traceability.md). “Có test liên quan” không đồng nghĩa mọi điều kiện của một AC đã được chứng minh.

| Mã | File backend | Nội dung được kiểm tra |
|---|---|---|
| A01–A07 | `test/tssa-access.test.mjs` | Role mới/legacy, ownership, field allowlist, completeness, stale revision, consent, guardian scope/expiry/objection, cached retry, logout/lock, dữ liệu mã hóa sau restart, audit bất biến |
| JSON body | `test/tssa-access.test.mjs` | JSON hỏng/null/array/scalar trả 400 thay vì 500 |
| W01–W06 | `test/tssa-workflows.test.mjs` | Draft → submit; tutor verification/pause; hard filters; quyết định coordinator; family choice và idempotency; thu hồi consent chặn đọc/replay |
| W07–W15 | `test/tssa-workflows.test.mjs` | Quyền mở profile sau booking; đổi giờ hai bên; note append-only và chia sẻ; hoàn tất/feedback riêng; rematch; mẫu số metrics/effort; conflict; guardian receipt hạn chế; tutor rút ca và replay ACCEPT bị chặn |
| G01–G09 | `test/tssa-governance.test.mjs` | Safety receipt/handler/privacy scope, inbox/mute/idempotency, export/delete gates, redaction/cache/ngoại lệ, audit/correction, role/model release gates, khóa account với token đang có |
| M01–M05 | `test/tssa-matching.test.mjs` | Từng điều kiện tutor, lịch/calendar invalid, manual/no-match, queue concurrency và restart resume |
| M06–M09 | `test/tssa-matching.test.mjs` | AI gate đóng; shadow giữ baseline; model-assisted không tự publish; operator rollback; provider revision/vector lỗi trở về baseline |
| E01–E08 | `test/tssa-edge-cases.test.mjs` | Các nhánh review/family choice, scope hết hạn, timezone tương đương, cohort nhỏ/fairness threshold, invitation redaction/capacity, confirmation conflict và chặn sửa shortlist cũ sau booking |
| E09–E11 | `test/tssa-session-exceptions.test.mjs` | Guardian DISPUTE khóa access/chuyển review; NOT_HELD bắt buộc lý do và rollback note lỗi; safety report tắt AI ngay và audit fallback |

**AI dùng HTTP embedding provider mô phỏng do test dựng**, không chạy BGE-M3 thật. Kết quả chứng minh wiring, gate, fallback và rollback trong môi trường kiểm thử; không chứng minh chất lượng xếp hạng hay fairness trên người dùng thật.

## 4. Flutter và Android

| Mã/nhóm | Source test | Nội dung |
|---|---|---|
| F01–F06 | `test/features/tssa/tssa_form_test.dart` | Validation nháp/gửi, chờ acknowledgement, chặn gửi đôi, retry key giữ nguyên/đổi khi đổi payload, thứ tự shortlist, restore draft và dialog khi rời form |
| Draft | `test/features/tssa/draft_storage_test.dart` | Xóa nhiều draft, phân tách owner/form, TTL và loại draft hết hạn |
| Repository | `test/features/tssa/tssa_repository_test.dart` | URL/payload/idempotency key, hiển thị lỗi API |
| S01–S04 | `test/core/networking/session_expiry_test.dart` | 401/account locked, epoch phiên; login sai; response 401 cũ không logout phiên mới; scoped 403 xóa draft nhưng giữ token còn hợp lệ |
| UI01–UI03 | `test/features/tssa/tssa_screen_test.dart` | Đúng tab cho 5 vai trò, role chưa cấp quyền, background che dữ liệu, denied refresh bỏ dữ liệu cũ |
| CUI: 28 case | `test/features/tssa/tssa_contract_screens_test.dart` | 27 màn hình/vai trò có payload backend tại 390 px + text 150%; public info không cần API/session |
| Android | `integration_test/tssa_smoke_test.dart` | Secure storage platform write/read/delete thật; learner/tutor login và tab; mở booking; logout đang ở route con; nhập agenda, gửi và đọc lại từ API |

`test/fixtures/tssa-contracts.json` được tạo bằng HTTP backend thật với dữ liệu tổng hợp cho 5 vai trò và 27 route, không chứa token/password. Widget test dùng payload capture này qua repository giả; không phải live HTTP end-to-end.
Các màn hình được cuộn để dựng các child/nested view ở cuối danh sách và kiểm tra exception/overflow. Không thay thế đánh giá contrast/focus/screen reader hoặc usability với learner/guardian đại diện.

### Coverage unit/widget

| File TSSA | Dòng có thực thi / dòng trong LCOV |
|---|---|
| Repository | 23 / 25 |
| Form | 206 / 364 |
| Profiles | 118 / 233 |
| Workflows | 144 / 320 |
| Governance | 169 / 313 |
| UI chung | 99 / 103 |
| Screen | 65 / 101 |
| **TSSA tổng** | **824 / 1459 = 56,5%** |

[Chi tiết coverage](../../output/tssa-validation-20261004/flutter-coverage.json); LCOV ở `coverage/lcov.info`.
Coverage là dòng Dart thực thi trong unit/widget, không phải branch coverage hoặc tỷ lệ AC. Không cộng integration Android vào con số này. Nhiều action form chuyên biệt và nhánh màn hình còn chưa có test trực tiếp.
Unit/widget mock secure storage; test Android xác nhận plugin platform roundtrip thật, chưa là audit Keystore/encryption của thiết bị.

## 5. Lỗi được sửa khi kiểm thử

1. **Xóa nhiều nháp gây ConcurrentModification**: chụp danh sách key trước khi xóa trong `draft_storage.dart`.
2. **JSON hỏng và body không phải object gây lỗi server**: phân loại thành 400 `INVALID_JSON` / `INVALID_BODY` ở backend `http.mjs`.
3. **Replay rematch của guardian dùng nhầm schedule scope**: dùng requests scope; guardian không có quyền lịch vẫn retry yêu cầu ghép lại được khi có requests scope.
4. **Replay cũ sau mất quyền có thể trả dữ liệu đã được cache**: matching replay kiểm tra consent hiện tại; tutor ACCEPT replay chứa learner ID chỉ trả khi booking/consent vẫn cho phép.
5. **Ngày rollover/lịch không hợp lệ và slot null**: timestamp kiểm tra ngày/giờ/timezone; timeWindows từ chối invalid slot bằng lỗi 400.
6. **Metrics khác nhau với cùng thời gian viết bằng UTC hoặc +07**: normalize start/end sang UTC trước lọc cohort.
7. **Coordinator sửa shortlist cũ khi request đã BOOKED**: chặn ngoài trạng thái review/waiting-family/needs-info.
8. **Teardown test backend trên Windows gặp SQLite file lock**: chờ child exit, retry cleanup. Không tính helper process thành một test nghiệp vụ.

Các lần test đầu có lỗi harness: mock secure storage chưa khởi tạo, form Android chưa dựng child ở cuối ListView/keyboard còn mở, test Links thiếu container cuộn. Đã sửa harness và chạy lại toàn bộ; không bỏ qua assertion hoặc disable test để làm xanh.

## 6. Chạy lại

### Bộ test local

```powershell
Set-Location 'C:\disk D\SPM-mobile'
flutter analyze lib test integration_test
flutter test --coverage --reporter expanded
flutter build apk --debug
Set-Location 'C:\disk D\SPM-frontend\backend'
node --test
```

Để tạo lại contract capture (test backend tự dọn môi trường):

```powershell
Set-Location 'C:\disk D\SPM-frontend\backend'
node testing/tssa-widget-fixtures.mjs 'C:\disk D\SPM-mobile\test\fixtures\tssa-contracts.json'
```

### Android với package cô lập

1. Bật emulator. Kiểm tra port 4317 không bị dịch vụ khác dùng.
2. Tạo fixture mới, rồi khởi động backend bằng đúng directory mà script vừa trả trong metadata:

```powershell
Set-Location 'C:\disk D\SPM-frontend\backend'
$fixtureFile = 'C:\disk D\SPM-mobile\output\tssa-validation-20261004\preview-fixture.json'
node testing/tssa-preview-seed.mjs $fixtureFile
$fixture = Get-Content -LiteralPath $fixtureFile -Raw | ConvertFrom-Json
$env:NODE_ENV = 'test'
$env:BACKEND_PORT = '4317'
$env:BACKEND_DATA_DIRECTORY = $fixture.directory
$env:BACKEND_CORS_ORIGIN = 'http://localhost:4318'
node server.mjs
```

3. Trong terminal khác:

```powershell
Set-Location 'C:\disk D\SPM-mobile'
.\scripts\run-android-validation.ps1 -Device emulator-5554
```

Runner tạo bản sao dưới `output/.../android-app`, đổi applicationId của bản sao rồi chạy integration test. Script dừng khi pub get/test lỗi. Không chạy trực tiếp integration test bằng package chính: kịch bản kiểm tra logout/storage và cần fixture riêng.
Sau chạy, dừng backend terminal vừa tạo và dọn đúng directory/package validation. App chính và dịch vụ port 3000/4000 không thuộc cleanup.

## 7. Chưa được xác nhận

- Chưa xác nhận **toàn bộ 86 AC**, mọi nhánh UI, pilot hay độ phù hợp với nhóm người dùng Autism. Bảng traceability nêu test liên quan và khoảng trống riêng từng AC.
- Chưa chạy model inference BGE-M3 thật, đánh giá ranking/fairness bằng dataset hợp lệ hoặc thực nghiệm kết quả học tập.
- Chưa có push provider/delivery ngoài app; inbox đã test, không suy ra email/SMS/push hoạt động.
- Verification guardian/tutor, consent/assent theo tuổi, quy trình emergency/SLA, security/privacy/safeguarding và bằng chứng tổ chức thật còn cần review.
- Mã hóa payload và redaction test không chứng minh managed key/ACL/TLS/data residency production hay xóa vật lý trên SSD/backups. Backup restore/deletion rehearsal/provider retention chưa chạy.
- Availability 99,5%, P95 API ≤ 1 giây, P95 shortlist ≤ 3 giây, RPO 24 giờ, RTO 8 giờ là mục tiêu báo cáo; **chưa benchmark/diễn tập**. Thời gian test chạy không được dùng thay cho phép đo các NFR này.

**Kết luận:** các test đã thực hiện đều qua; APK build và luồng Android/browser đã chạy thành công với dữ liệu cô lập. Chưa đủ bằng chứng để xác nhận release/pilot hoặc đóng mọi điều kiện nghiệp vụ bên ngoài.
