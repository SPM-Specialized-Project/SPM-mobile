# Đối chiếu nghiệp vụ TSSA với báo cáo Autism

Ngày cập nhật: 04/10/2026. Nguồn: `docs/reports/main.tex` (bản ngày 03/10/2026) và `docs/reports/business-feasibility-autism-tutor-matching-vi.tex`.

Đã đối chiếu **18 user stories / 86 acceptance criteria**. Kiểm thử ngày 04/10/2026: **114 Flutter test, 99 node test, 1 integration Android đều qua**; analyzer/APK thành công, browser đã lưu agenda. “Các kịch bản liên quan đã qua” chỉ xác nhận các test được dẫn, **không khẳng định mọi điều kiện của AC đã hoàn tất**. Mã A/W/G/M/E/F/S/UI/CUI và giới hạn từng nhóm được giải thích trong [báo cáo kiểm thử](validation-report.md). Không đóng gate pilot bằng bằng chứng tổng hợp.

Flutter presentation ở `lib/features/tssa/presentation/`; backend ở sibling `C:/disk D/SPM-frontend/backend/`. Một số AC vừa có code vừa cần evidence bên ngoài: verification thật, usability, provider, backup/retention và fairness.

## US-TSS-01 — Auth, role và phiên

Flutter: `auth_controller.dart, api_client.dart, auth_session.dart`. Backend: `auth.mjs, routes.mjs, tssa/access.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 01a ([nguồn dòng 641](../reports/main.tex)) | Với thông tin xác thực hợp lệ, app tạo phiên và gọi API hồ sơ; thông tin sai trả lỗi chung không xác nhận tài khoản có tồn tại. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | A01; Android |
| 01b ([nguồn dòng 642](../reports/main.tex)) | Khi token hết hạn/không hợp lệ, app yêu cầu xác thực lại và không hiển thị dữ liệu cache đã hết quyền. | 401/locked xóa token và nháp, đổi epoch API, đóng màn hình cũ; logout thu hồi session ở server. Session server còn dùng Map 8 giờ. | Các kịch bản liên quan đã qua | A06; S01/S03; UI03; Android logout |
| 01c ([nguồn dòng 643](../reports/main.tex)) | API từ chối truy cập resource không thuộc account, learner link hoặc scope coordinator; thay đổi URL/request body ở client không vượt quyền. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | A02/A04/G02/W07 |
| 01d ([nguồn dòng 644](../reports/main.tex)) | Role không nhận diện được chỉ xem màn hình an toàn tối thiểu; app không tự nâng quyền. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | A01; UI02; auth model tests |
| 01e ([nguồn dòng 645](../reports/main.tex)) | API role tutor được phân biệt trong domain TSSA; việc hiện tại ánh xạ tutor sang lecturer không được xem là kiểm soát đủ cho release. | Tài khoản mới tssa_tutor riêng; lecturer SPM chọn onboarding mới trở thành tutor TSSA. Không dùng lecturer làm bằng chứng xác minh. | Các kịch bản liên quan đã qua | A01; Android tutor |

## US-TSS-02 — Guardian–learner

Flutter: `tssa_profiles.dart: TssaLinks`. Backend: `tssa/profiles.mjs, access.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 02a ([nguồn dòng 652](../reports/main.tex)) | App yêu cầu bằng chứng/liên kết theo quy trình tổ chức đã chọn; không tự liên kết bằng họ tên hoặc email giống nhau. | Bằng chứng tham chiếu, coordinator review, quy trình guardian trong policy. Tổ chức phải xác minh bằng chứng thật. | Test một phần; cần bằng chứng bổ sung | A04; CUI links. Bằng chứng xác minh quan hệ thật cần tổ chức review. |
| 02b ([nguồn dòng 653](../reports/main.tex)) | Guardian chỉ mở learner đang có link còn hiệu lực; link bị thu hồi chặn request tiếp theo và chia sẻ mới. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | A05; E03 |
| 02c ([nguồn dòng 654](../reports/main.tex)) | Tổ chức có thể cấp quyền theo mục đích (hồ sơ, lịch, feedback); mỗi quyền hiển thị trạng thái và thời hạn. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | A04; W14; CUI links |
| 02d ([nguồn dòng 655](../reports/main.tex)) | Learner thấy thông tin giải thích phù hợp độ tuổi/cách giao tiếp và có thể bày tỏ không muốn chia sẻ khi quy trình cho phép. | Learner tự OBJECT liên kết; guardian không thực hiện OBJECT thay learner. Cách giải thích theo tuổi cần review đại diện. | Test một phần; cần bằng chứng bổ sung | A05 OBJECT; CUI links. Chưa review cách giải thích/assent theo tuổi với learner đại diện. |
| 02e ([nguồn dòng 656](../reports/main.tex)) | Thay đổi người đại diện hoặc tranh chấp quyền sở hữu được chuyển coordinator xử lý, không tự động giải quyết bằng AI. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | E09 DISPUTE |

## US-TSS-03 — Hồ sơ mục tiêu học

Flutter: `tssa_profiles.dart, tssa_form.dart`. Backend: `tssa/profiles.mjs, access.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 03a ([nguồn dòng 663](../reports/main.tex)) | Profile có môn, khối lớp, mục tiêu học, format, lịch và các điều chỉnh tự chọn; các trường bắt buộc được ghi rõ trước khi lưu. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | A02; F01; CUI profile |
| 03b ([nguồn dòng 664](../reports/main.tex)) | Chẩn đoán lâm sàng không bắt buộc để tạo yêu cầu; nếu trường nhạy cảm được thêm sau này, nó có mục đích, consent, visibility riêng. | Allowlist học tập; không có trường chẩn đoán. Thêm trường sau này phải thay schema và consent rõ ràng. | Các kịch bản liên quan đã qua | A02 field allowlist |
| 03c ([nguồn dòng 665](../reports/main.tex)) | Guardian/learner xem trước những trường sẽ chia sẻ với coordinator, ứng viên và tutor ở từng giai đoạn. | Bản xem trước theo coordinator/tutor/matching/notifications/analytics; ứng viên tutor chưa nhận booking không thấy hồ sơ learner. | Test một phần; cần bằng chứng bổ sung | A03/A04; CUI consent preview. Chưa xác nhận người dùng đại diện hiểu consent/preview. |
| 03d ([nguồn dòng 666](../reports/main.tex)) | Người có quyền sửa profile nhìn thấy thời điểm và nội dung thay đổi; sửa profile không tự chia sẻ trường mới khi chưa được consent. | History lưu actor, thời điểm, trường, before/after. Consent vẫn là allowlist trường; cập nhật profile khóa run/shortlist cũ. | Các kịch bản liên quan đã qua | A02; CUI profile |
| 03e ([nguồn dòng 667](../reports/main.tex)) | Màn hình cho phép lưu nháp và quay lại mà không mất dữ liệu đã nhập. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | F05/F06; Draft |

## US-TSS-04 — Hồ sơ và xác minh tutor

Flutter: `tssa_profiles.dart: TssaTutors`. Backend: `tssa/profiles.mjs, matching.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 04a ([nguồn dòng 674](../reports/main.tex)) | Profile tách môn/khối, hình thức dạy, availability, kinh nghiệm khai báo và minh chứng được yêu cầu. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W02; CUI tutors |
| 04b ([nguồn dòng 675](../reports/main.tex)) | Trạng thái xác minh là pending/verified/rejected/expired; chỉ verified và active mới vào danh sách ứng viên. | Xác minh expired được suy ra từ expiresAt trong response; hard filter luôn kiểm tra thời hạn, active, role và tải ca. | Các kịch bản liên quan đã qua | W02; M01 |
| 04c ([nguồn dòng 676](../reports/main.tex)) | Guardian không xem giấy tờ gốc/PII verification; chỉ xem thông tin tutor được duyệt để giới thiệu. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W03/W04 |
| 04d ([nguồn dòng 677](../reports/main.tex)) | Tutor được sửa availability, tạm dừng hồ sơ và từ chối lời mời với lý do tùy chọn. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W02/W15 |
| 04e ([nguồn dòng 678](../reports/main.tex)) | Tiêu chí xác minh, người duyệt, ngày duyệt và ngày hết hạn có thể kiểm tra trong audit. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Test một phần; cần bằng chứng bổ sung | W02/G07. Verification học thuật/safeguarding thật và tiêu chuẩn tổ chức chưa xác nhận. |

## US-TSS-05 — Yêu cầu tìm tutor

Flutter: `tssa_workflows.dart: TssaRequests`. Backend: `tssa/workflows.mjs, store.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 05a ([nguồn dòng 685](../reports/main.tex)) | Request lưu được môn, khối lớp, format, khoảng lịch, địa bàn ở mức cần thiết, mục tiêu và consentVersion. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W01/W03 |
| 05b ([nguồn dòng 686](../reports/main.tex)) | Nếu thiếu trường bắt buộc hoặc consent hết hạn, backend không đưa yêu cầu vào matching và app nói rõ việc cần làm. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W01/A03/W06 |
| 05c ([nguồn dòng 687](../reports/main.tex)) | Request có trạng thái: nháp, đã gửi, chờ bổ sung, matching, coordinator review, chờ gia đình chọn, đã đặt lịch hoặc đã đóng. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W01/W04/W05/W15; E01/E02/E08 |
| 05d ([nguồn dòng 688](../reports/main.tex)) | Guardian có thể xem trạng thái và sửa yêu cầu trước khi coordinator bắt đầu review; thay đổi được version hóa. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W01/A02 |
| 05e ([nguồn dòng 689](../reports/main.tex)) | Gửi lặp do mất mạng không tạo duplicate request; client có thể thử lại an toàn. | Idempotency lưu SQLite cùng transaction; đổi nội dung với cùng key trả 409, replay kiểm tra lại quyền hiện hành. | Test một phần; cần bằng chứng bổ sung | F03; W05; M05. Đã test retry key/choice/queue; chưa case HTTP riêng retry create-request và mọi mutation. |

## US-TSS-06 — Điều kiện bắt buộc

Flutter: `tssa_workflows.dart: TssaMatchReview`. Backend: `tssa/matching.mjs, policy.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 06a ([nguồn dòng 696](../reports/main.tex)) | Chỉ tutor active, verified, đúng môn và khối lớp theo rule đã duyệt mới đủ điều kiện. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | M01/W03 |
| 06b ([nguồn dòng 697](../reports/main.tex)) | Lịch, format/địa bàn, consent và giới hạn ca được kiểm tra theo dữ liệu hiện hành; mỗi lượt ghi timestamp/snapshot cần thiết. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | M01/M02; E07; W13/W06 |
| 06c ([nguồn dòng 698](../reports/main.tex)) | Candidate bị loại có reason code; thiếu dữ liệu tạo trạng thái review thay vì mặc định là phù hợp. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Test một phần; cần bằng chứng bổ sung | M01/M03. Đã test calendar/null và exclusions; chưa test riêng mọi cấu hình dữ liệu thiếu → NEEDS_REVIEW. |
| 06d ([nguồn dòng 699](../reports/main.tex)) | Nếu không còn candidate hợp lệ, kết quả là no-match; không nới hard filter ngầm để đủ số lượng. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | M04/E07 |
| 06e ([nguồn dòng 700](../reports/main.tex)) | Quy tắc hard filter có owner/version và không thể sửa bởi model inference. | ruleOwner, ruleVersion, ruleApprovedBy, ruleReviewRef bắt buộc trước matching; thay version giữa job trả lỗi review. | Test một phần; cần bằng chứng bổ sung | M01/G08. Gate/version có test liên quan; chưa kiểm chứng chủ sở hữu/review luật thật. |

## US-TSS-07 — Shortlist có giải thích

Flutter: `tssa_workflows.dart: TssaMatchReview`. Backend: `tssa/matching.mjs, safety-monitor.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 07a ([nguồn dòng 707](../reports/main.tex)) | Mỗi candidate có reason codes gắn với field đã chia sẻ; không hiển thị score đơn độc như xác suất thành công. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W03; CUI matching review |
| 07b ([nguồn dòng 708](../reports/main.tex)) | Kết quả lưu algorithm/model version, input field versions, thời điểm, trạng thái và uncertainty/data gaps. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W03/M07 |
| 07c ([nguồn dòng 709](../reports/main.tex)) | Nếu AI provider lỗi, timeout hoặc trả output sai schema, workflow giữ trạng thái; coordinator có baseline/manual fallback. | Provider có timeout/schema/revision/vector check; lỗi dùng baseline và tắt model. Adapter thật chưa chạy lượt này. | Test một phần; cần bằng chứng bổ sung | M09 simulated provider. Provider revision/vector fallback đã test; chưa inference thật hoặc từng lỗi network/timeout end-to-end. |
| 07d ([nguồn dòng 710](../reports/main.tex)) | UI gắn nhãn gợi ý AI và nói rõ coordinator chưa duyệt/đã duyệt. | mode và effectiveMode tách chế độ yêu cầu/phương án thực chạy; fallback rõ khi model gate đóng. | Test một phần; cần bằng chứng bổ sung | CUI matching review; W03. Đã render lý do/giới hạn; chưa đánh giá người dùng hiểu uncertainty. |
| 07e ([nguồn dòng 711](../reports/main.tex)) | Không có AI-generated diagnosis, personality trait hoặc kết luận về năng lực trẻ trong output. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Test một phần; cần bằng chứng bổ sung | A02/W03; source allowlist. Allowlist/source đã kiểm tra; chưa kiểm định output model thật. |

## US-TSS-08 — Coordinator review

Flutter: `tssa_workflows.dart`. Backend: `tssa/workflows.mjs, access.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 08a ([nguồn dòng 718](../reports/main.tex)) | Coordinator có thể approve, reject, reorder, request-info, no-match và close theo quyền được cấp. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | E01/W04 |
| 08b ([nguồn dòng 719](../reports/main.tex)) | Mọi quyết định/override lưu actor, thời gian, candidate/run, lý do và dữ liệu/version dùng lúc quyết định. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W04/G07 |
| 08c ([nguồn dòng 720](../reports/main.tex)) | Khi consent không còn hiệu lực, hồ sơ chi tiết và hành động giới thiệu bị khóa cho đến khi có consent mới. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W06/A05 |
| 08d ([nguồn dòng 721](../reports/main.tex)) | Tutor chưa xác minh bị chặn khỏi shortlist chính thức. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W02/W04 |
| 08e ([nguồn dòng 722](../reports/main.tex)) | Queue cho biết tuổi yêu cầu, trạng thái, người phụ trách, chờ bổ sung hay lỗi; role khác không thể xem toàn bộ queue. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Test một phần; cần bằng chứng bổ sung | W01; CUI requests/review. Có scope/render queue; chưa đo công bằng phân công/backlog hoặc SLA. |

## US-TSS-09 — Gia đình lựa chọn

Flutter: `tssa_workflows.dart: TssaRequestPage`. Backend: `tssa/workflows.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 09a ([nguồn dòng 729](../reports/main.tex)) | Chỉ candidate đã coordinator duyệt được trình bày cho gia đình. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W03/W04 |
| 09b ([nguồn dòng 730](../reports/main.tex)) | Thông tin hiển thị gồm môn/lớp, cách dạy do tutor khai báo, hình thức, lịch phù hợp và trạng thái xác minh; không lộ PII dư thừa. | Public tutor có opaque tutorId, tên giới thiệu, môn/khối, cách dạy, lịch, xác minh; không trả email account hay evidence gốc. | Test một phần; cần bằng chứng bổ sung | W04; CUI request detail. Đã test server và render; chưa đánh giá khả năng hiểu lý do với đại diện. |
| 09c ([nguồn dòng 731](../reports/main.tex)) | Gia đình/learner có lựa chọn accept, decline, ask-question hoặc request-another; decline không làm mất quyền tiếp tục dịch vụ. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | E02/W05 |
| 09d ([nguồn dòng 732](../reports/main.tex)) | Chưa có accept cuối thì tutor chưa nhận hồ sơ chi tiết và không tạo booking. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | E06/W03/W07 |
| 09e ([nguồn dòng 733](../reports/main.tex)) | Mọi phản hồi chuyển trạng thái request và thông báo cho coordinator theo quyền. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | E02/G03 |

## US-TSS-10 — Booking và thay đổi

Flutter: `tssa_workflows.dart: TssaBookingPage`. Backend: `tssa/workflows.mjs, matching.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 10a ([nguồn dòng 740](../reports/main.tex)) | Booking chỉ được xác nhận khi tutor chấp thuận khung giờ và gia đình chọn; backend kiểm tra không trùng lịch trong scope hệ thống. | Family chọn, proposal, tutor ACCEPT mới CONFIRMED; kiểm tra conflict/capacity lần nữa trong transaction. Chỉ biết lịch trong hệ thống. | Các kịch bản liên quan đã qua | W07/W13; E07 |
| 10b ([nguồn dòng 741](../reports/main.tex)) | Mỗi bên nhìn thấy múi giờ, địa điểm/format và chính sách thay đổi trước khi xác nhận. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W13; Android booking; browser |
| 10c ([nguồn dòng 742](../reports/main.tex)) | Hủy/đổi lịch lưu actor, timestamp và trạng thái; không xóa lịch sử booking. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W08/W15 |
| 10d ([nguồn dòng 743](../reports/main.tex)) | Khi tutor rút khỏi ca, request quay về coordinator review/rematch; app không tự gán người mới. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W15 |

## US-TSS-11 — Chuẩn bị và ghi nhận buổi

Flutter: `tssa_workflows.dart: TssaBookingPage`. Backend: `tssa/workflows.mjs, access.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 11a ([nguồn dòng 750](../reports/main.tex)) | Tutor chỉ đọc phần learner profile còn consent và gắn với booking được nhận. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W07; E06; W15 |
| 11b ([nguồn dòng 751](../reports/main.tex)) | Agenda/summary tập trung vào môn học, hoạt động, điều chỉnh được dùng và bước tiếp theo; không bắt tutor đưa chẩn đoán/lời khuyên điều trị. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W09; Android agenda; browser |
| 11c ([nguồn dòng 752](../reports/main.tex)) | Không ghi âm/video mặc định; nếu tổ chức sau này cần ghi, phải là feature riêng có consent, mục đích và retention review. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Test một phần; cần bằng chứng bổ sung | Source + CUI booking detail. Không có flow ghi âm/video trong source đã đọc; chưa audit thiết bị/quyền runtime toàn diện. |
| 11d ([nguồn dòng 753](../reports/main.tex)) | Summary lưu người tạo, thời gian và lịch sử chỉnh sửa; guardian nhìn thấy đúng phần đã chia sẻ. | Bổ sung note tạo phiên bản có supersedesId, bản gốc giữ lại. Gia đình chỉ đọc sharedWithFamily. | Các kịch bản liên quan đã qua | W09 |
| 11e ([nguồn dòng 754](../reports/main.tex)) | Tutor có thể đánh dấu buổi không diễn ra và nêu lý do mà không giả tạo kết quả học. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | E10 NOT_HELD |

## US-TSS-12 — Feedback và rematch

Flutter: `tssa_workflows.dart: TssaBookingPage`. Backend: `tssa/workflows.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 12a ([nguồn dòng 761](../reports/main.tex)) | Feedback hỏi rõ trải nghiệm, mức phù hợp lịch/cách học, điều gì nên tiếp tục/thay đổi; không bắt chấm điểm tính cách trẻ. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W10 |
| 12b ([nguồn dòng 762](../reports/main.tex)) | Learner có lựa chọn phản hồi ngắn/phi ngôn ngữ nếu thiết kế hỗ trợ và guardian không trả lời thay mọi lựa chọn. | Cảm nhận ngắn/pictogram và SKIP; actor riêng, checkbox phạm vi chia sẻ. Usability cần người dùng đại diện. | Test một phần; cần bằng chứng bổ sung | W10 SKIP; CUI booking detail. SKIP/chia sẻ độc lập đã test; usability pictogram theo nhóm tuổi chưa xác nhận. |
| 12c ([nguồn dòng 763](../reports/main.tex)) | Request rematch tạo case mới liên kết booking cũ nhưng không xóa lịch sử hoặc chia sẻ feedback ngoài scope. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W11/W14 |
| 12d ([nguồn dòng 764](../reports/main.tex)) | Coordinator xem lý do và điều phối; model chỉ dùng field feedback được phép, không tự loại tutor hay gắn nhãn learner. | Feedback không đưa vào ranker hiện tại; coordinator xem phần được người gửi cho phép. | Test một phần; cần bằng chứng bổ sung | W10/W11; source model input. Luồng feedback/rematch đã test; tác động học tập và mọi policy review chưa đo. |

## US-TSS-13 — Hỗ trợ và safety

Flutter: `tssa_governance.dart: TssaSupport`. Backend: `tssa/governance.mjs, safety-monitor.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 13a ([nguồn dòng 771](../reports/main.tex)) | Form có loại sự cố, mô tả, booking liên quan tùy chọn, mức riêng tư và cách liên hệ; chỉ thu nội dung cần xử lý. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | G01/G02 |
| 13b ([nguồn dòng 772](../reports/main.tex)) | Sau khi gửi, app xác nhận đã nhận và cung cấp mã case; không hứa đã giải quyết nếu chưa có handler. | Server trả case id + status + handlerAssigned; list hiện mã và trạng thái, không hứa đã giải quyết. | Các kịch bản liên quan đã qua | G01; CUI support |
| 13c ([nguồn dòng 773](../reports/main.tex)) | Case chỉ hiển thị cho người xử lý được phân công và privacy/safety role được cấp; tất cả lần xem/chuyển trạng thái được audit. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | G02/G07; CUI case detail |
| 13d ([nguồn dòng 774](../reports/main.tex)) | UI phân biệt hỗ trợ vận hành thông thường với trường hợp cần hỗ trợ khẩn; kênh khẩn phải được tổ chức xác minh trước khi phát hành. | UI tách NORMAL/URGENT; chỉ công bố kênh khẩn khi có reviewer + evidence. Kênh/SLA thật còn là gate tổ chức. | Test một phần; cần bằng chứng bổ sung | G08; CUI support. Gate có test; kênh khẩn, SLA và quy trình tổ chức thật chưa xác minh. |
| 13e ([nguồn dòng 775](../reports/main.tex)) | Report không làm mất quyền yêu cầu rematch/đóng dịch vụ; policy chống trả đũa được hiển thị. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | G01/W11 |

## US-TSS-14 — Thông báo

Flutter: `tssa_governance.dart: TssaNotifications`. Backend: `tssa/access.mjs, governance.mjs, store.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 14a ([nguồn dòng 782](../reports/main.tex)) | Thông báo gửi theo event: trạng thái request, hỏi bổ sung, quyết định, booking, đổi lịch, consent và case được phép xem. | Có event và inbox bền vững trong app. Push ngoài app chưa tích hợp; tổ chức phải chọn provider/kênh được duyệt. | Test một phần; cần bằng chứng bổ sung | G03; CUI notifications. Inbox/events fixture đã test; chưa kiểm tra riêng từng event ở mọi role. |
| 14b ([nguồn dòng 783](../reports/main.tex)) | Push preview không chứa diagnosis, learner note, chi tiết incident hoặc địa điểm riêng tư. | Mọi preview hiện tại là câu chung, không mang note/incident/địa điểm. Không có push provider đang hoạt động. | Test một phần; cần bằng chứng bổ sung | G03 inbox. Chỉ inbox/preview trong app; chưa tích hợp/kiểm thử delivery push ngoài app. |
| 14c ([nguồn dòng 784](../reports/main.tex)) | Người dùng có thể tắt nhóm thông báo không bắt buộc; thông báo an toàn quan trọng dùng kênh đã được policy xác nhận. | Có mute theo nhóm, safety không mute inbox. Delivery safety ngoài app cần provider và quy trình đã được xác minh. | Test một phần; cần bằng chứng bổ sung | G03; CUI preferences. Mute trong app đã test; kênh hỗ trợ ngoài app còn cần tổ chức xác nhận. |
| 14d ([nguồn dòng 785](../reports/main.tex)) | Mất/nhận trùng event không tạo booking hoặc quyết định trùng; trạng thái chính đọc từ API. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Test một phần; cần bằng chứng bổ sung | W05/M05/F03. Đã test key/queue/choice retry; chưa chứng minh mọi tổ hợp lỗi mạng/mutation. |

## US-TSS-15 — Accessibility và offline

Flutter: `tssa_form.dart, tssa_ui.dart, draft_storage.dart, app.dart`. Backend: `tssa/store.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 15a ([nguồn dòng 792](../reports/main.tex)) | Form có nhãn screen reader, text scaling, focus order, tương phản và lỗi gắn với trường; hành động chính không chỉ dựa màu. | Material labels, text scaling, field validation, biểu tượng + text. Chưa có review screen reader/contrast/usability với đại diện. | Test một phần; cần bằng chứng bổ sung | UI01; CUI 27 views. 390 px + chữ 150% đã test; contrast/focus/screen reader và usability đại diện chưa audit. |
| 15b ([nguồn dòng 793](../reports/main.tex)) | Luồng hỗ trợ câu ngắn, thông báo tiến độ, điều khiển animation/âm thanh và nút quay lại. | Có trạng thái chờ server, back/discard/save draft; reduceMotion áp dụng MediaQuery, theme và route TSSA. Không bật âm thanh. | Test một phần; cần bằng chứng bổ sung | F02/F06; G03; CUI preferences. Form/dialog/preference đã test; giảm kích thích với người đại diện chưa đánh giá. |
| 15c ([nguồn dòng 794](../reports/main.tex)) | Draft có thể lưu cục bộ an toàn và gửi lại có idempotency; app không hiển thị “đã gửi” khi server chưa xác nhận. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | F02/F03/F05 |
| 15d ([nguồn dòng 795](../reports/main.tex)) | Nếu offline, người dùng vẫn xem được dữ liệu public/static cần thiết nhưng profile nhạy cảm cache có thời hạn và bị xóa khi logout/revoke theo policy. | Thông tin public/static offline. Không lưu profile server offline; nháp secure storage TTL 24 giờ, xóa logout/403/revoke. | Các kịch bản liên quan đã qua | Draft; S04; UI03; CUI public offline |
| 15e ([nguồn dòng 796](../reports/main.tex)) | Release gate bao gồm usability review với người dùng đại diện; accessibility không được chỉ xác nhận bằng checklist tự động. | Có release gate representativeUsability bắt buộc để duyệt policy pilot. Chưa có buổi review thực tế. | Test một phần; cần bằng chứng bổ sung | G08 release gate. Gate vẫn khóa nếu thiếu evidence; chưa thực hiện usability pilot đại diện. |

## US-TSS-16 — Consent và privacy

Flutter: `tssa_profiles.dart, tssa_governance.dart`. Backend: `tssa/access.mjs, profiles.mjs, governance.mjs, store.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 16a ([nguồn dòng 803](../reports/main.tex)) | Consent UI tách mục đích chia sẻ với coordinator, tutor, matching, thông báo và nghiên cứu/analytics nếu có. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Test một phần; cần bằng chứng bổ sung | A03/A04; CUI consent. Scope/preview đã test; consent/assent theo tuổi cần review thật. |
| 16b ([nguồn dòng 804](../reports/main.tex)) | Màn hình privacy hiển thị data category, ai đã xem/nhận, thời điểm và retention policy có thể áp dụng. | Inventory + audit được lọc theo resource của learner, đủ actor/time/purpose/fields. Safety không thuộc quyền vẫn bị ẩn. | Các kịch bản liên quan đã qua | G04/G07; CUI privacy |
| 16c ([nguồn dòng 805](../reports/main.tex)) | Thu hồi consent chặn hành động chia sẻ mới; job còn chờ được hủy hoặc cách ly và kết quả được log. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | W06/A05 |
| 16d ([nguồn dòng 806](../reports/main.tex)) | Yêu cầu export/delete có trạng thái, người xử lý và phạm vi ngoại lệ được giải thích; API không xóa bừa audit bắt buộc giữ theo policy đã duyệt. | Export/delete có handler/status/ngoại lệ; delete chặn khi thiếu policy/backup hoặc booking hoạt động. Loại dữ liệu vận hành và retry/export cache; giữ audit/case có ngoại lệ. | Test một phần; cần bằng chứng bổ sung | G04/G05/G06. Logical redaction/export cache đã test; chưa physical wipe, backup/provider retention rehearsal. |
| 16e ([nguồn dòng 807](../reports/main.tex)) | Backup, logs, model provider và analytics nằm trong data inventory và có quy tắc retention/xóa được xác minh. | Inventory ghi DB/audit/backup/provider/mobile. Retention/backup/provider deletion phải được xác minh ngoài code trước pilot; chưa diễn tập. | Test một phần; cần bằng chứng bổ sung | G08; CUI privacy inventory. Inventory/gate đã render/test; provider/backup/retention/security review thật chưa thực hiện. |

## US-TSS-17 — Metrics và model governance

Flutter: `tssa_governance.dart: TssaMetrics / TssaModels`. Backend: `tssa/governance.mjs, safety-monitor.mjs, matching.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 17a ([nguồn dòng 814](../reports/main.tex)) | Dashboard tách baseline/manual, rule-based, shadow và model-assisted; hiển thị số ca, khoảng thời gian, coverage và missingness. | Có period/cohort, số ca/run theo mode, coverage/missingness. Không có dữ liệu mẫu giả làm kết quả. | Các kịch bản liên quan đã qua | M06/M07/M08; W12; E04 |
| 17b ([nguồn dòng 815](../reports/main.tex)) | Chỉ số gồm tỷ lệ đủ điều kiện/no-match, thời gian shortlist, override, gia đình chấp nhận, hoàn tất buổi đầu, rematch, sự cố và tỷ lệ phản hồi. | Mẫu số theo định nghĩa report; time-to-shortlist từ readyAt đến finishedAt, không lấy thời điểm approve. | Các kịch bản liên quan đã qua | W12/E04 |
| 17c ([nguồn dòng 816](../reports/main.tex)) | So sánh subgroup chỉ dùng dữ liệu có căn cứ/consent, cỡ mẫu đủ và review quyền riêng tư; không công bố nhóm nhỏ có thể tái nhận dạng. | Chỉ nhóm hình thức học có consent analytics, cả hai tối thiểu 10 ca và privacy/fairness review; nhóm nhỏ bị ẩn. Chưa đo fairness thật. | Test một phần; cần bằng chứng bổ sung | E05/W12. Suppression/cohort/threshold dữ liệu tổng hợp đã test; chưa fairness trên cohort thật. |
| 17d ([nguồn dòng 817](../reports/main.tex)) | Từng release model có version, owner, model card, test cases, rollback path, incident contact và phê duyệt vận hành. | Có đăng ký model card/version/owner/evidence/rollback/contact/expiry; evidence thật và phê duyệt còn là gate. | Test một phần; cần bằng chứng bổ sung | G08/M07 simulated model. Model card/gate mô phỏng đã test; chưa model evaluation/shadow dataset được duyệt thật. |
| 17e ([nguồn dòng 818](../reports/main.tex)) | Khi fairness/safety threshold vi phạm hoặc model output không kiểm chứng được, hệ thống tắt gợi ý AI và về manual/rule baseline. | Tắt AI khi provider/output lỗi, safety report, hoặc gap no-match vượt ngưỡng được tổ chức duyệt khi đủ mẫu; về baseline. Đây là tín hiệu vận hành, không chứng minh fairness. | Các kịch bản liên quan đã qua | M08/M09; E05/E11 |

## US-TSS-18 — Audit và quyền đặc biệt

Flutter: `tssa_governance.dart: TssaAudit / TssaBindings`. Backend: `tssa/store.mjs, governance.mjs, access.mjs`.

| AC | Yêu cầu nguồn | Triển khai / giới hạn | Trạng thái kiểm thử | Test / khoảng trống |
|---|---|---|---|---|
| 18a ([nguồn dòng 825](../reports/main.tex)) | Sự kiện login, xem profile nhạy cảm, đổi consent, export/delete, match decision và safety case ghi actor, time, action, resource id và result. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | A07/G07/W04 |
| 18b ([nguồn dòng 826](../reports/main.tex)) | Log không ghi access token, mật khẩu, toàn bộ prompt hoặc dữ liệu profile không cần thiết. | Không ghi token/password/full prompt/profile trong audit. Payload mới mã hóa AES-GCM; actor/resource metadata mã hóa. Audit prototype cũ giữ nguyên để không sửa dấu vết. | Các kịch bản liên quan đã qua | G07 |
| 18c ([nguồn dòng 827](../reports/main.tex)) | Coordinator/admin có thể rà lại quyết định nhưng không sửa/xóa dấu vết gốc; correction tạo event mới có tham chiếu. | SQLite trigger chặn UPDATE/DELETE audit; correction append mới. Coordinator xem quyết định trong scope, governance lead xem audit. | Test một phần; cần bằng chứng bổ sung | A07/G07. SQLite/WAL/SHM không lộ marker và audit bất biến đã test; chưa managed key/ACL/TLS production review. |
| 18d ([nguồn dòng 828](../reports/main.tex)) | Review role định kỳ có danh sách quyền hiện hành, người duyệt và ngày hết hạn; tài khoản bị khóa thu hồi quyền truy cập theo thời hạn vận hành xác định. | Handler/UI theo scope, revision và trạng thái; xem bằng chứng test liên quan. | Các kịch bản liên quan đã qua | A06/E03/G09 |

## Bổ sung từ báo cáo feasibility

| Yêu cầu | Thực hiện / phạm vi còn lại |
|---|---|
| Ngân sách tự chọn trong intake | Field `budget` trong profile/request và consent; coordinator trao đổi, không dùng ranker làm suy luận khả năng chi trả. |
| Phút/case và chi phí điều phối | `POST /api/v1/requests/:id/effort`; dashboard sample size, coverage, tổng phút và chi phí đã khai báo. Không dùng giá giả định trong báo cáo làm số đo. |
| Concierge → rule → shadow → model-assisted | Có MANUAL/RULE_BASELINE/SHADOW/MODEL_ASSISTED, hard filter không bị model bỏ qua, coordinator review bắt buộc. AI mặc định tắt. |
| Willingness-to-pay, phỏng vấn, tutor supply, economics | Chưa có khảo sát/pilot/số liệu kế toán. Cần người tham gia, căn cứ dữ liệu và tổ chức thực hiện; không tạo kết quả thị trường. |
| Phí/refund/cancel/insurance | Quyết định D-02; policy đổi/hủy được hiển thị tại booking. Không có cổng thanh toán hay mô hình phí tự đặt. |
| API tham khảo `/api/matching/...` | Ánh xạ vào `/api/v1/requests`, `/matches/:id`, `/matches/:id/decision`, `/requests/:id/choice`, `/bookings/:id/feedback`; giữ ranh giới SPM/CodePulse cũ. |

## Điều kiện còn mở trước pilot / AI

D-01…D-12 được quản lý trong màn Quản trị, có owner, quyết định và evidenceRef; mặc định OPEN. Approval policy đòi nhóm/handlers/coordinator còn quyền, đầu mối/giờ/SLA, kênh khẩn được xác minh, retention và năm gate cốt lõi. AI còn đòi shadow/fairness evidence, model card còn hiệu lực và ngưỡng gap đã duyệt.

Cần evidence thật: xác minh tutor/guardian; giải thích consent/assent theo nhóm tuổi; usability với người dùng đại diện; privacy/security/safeguarding review; managed encryption key/ACL/TLS/data residency; backup restore và deletion rehearsal; provider retention; delivery thông báo ngoài app; model evaluation và rollback rehearsal. Những việc này chưa thể đóng bằng source code hoặc APK build thành công.

NFR availability 99,5%, P95 API 1 giây, P95 shortlist 3 giây, RPO 24 giờ, RTO 8 giờ trong báo cáo là mục tiêu đề xuất. Chưa có phép đo hoặc diễn tập để xác nhận các ngưỡng đó.
