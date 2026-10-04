# Báo cáo nghiên cứu

Thư mục này lưu các báo cáo nguồn LaTeX của dự án. Mỗi báo cáo nên là một tệp
TeX tự chứa để có thể mở trực tiếp trong LaTeX editor tích hợp; nguồn và
trích dẫn được giữ cùng một tệp để dễ kiểm tra và di chuyển.

## Báo cáo hiện có

- [main.tex](main.tex): tài liệu gốc cho Tutor Support System for Autism trên
  mobile (32 trang sau lần render 2026-10-03), gồm source review backend Node.js
  và code Flutter theo module/luồng, kiến trúc mục tiêu, số liệu bằng chứng,
  18 user story, 86 acceptance criteria, AI matching có coordinator kiểm soát,
  privacy và kế hoạch pilot. Bản PDF render:
  [tutor-support-system-autism-main.pdf](../../output/pdf/tutor-support-system-autism-main.pdf).

- [business-feasibility-autism-tutor-matching-vi.tex](business-feasibility-autism-tutor-matching-vi.tex):
  nghiên cứu ban đầu về feasibility kinh doanh, giới hạn dữ liệu thị trường,
  mô hình AI hỗ trợ ghép tutor–student và vai trò duyệt của coordinator.
  Bản PDF đã render: [business-feasibility-autism-tutor-matching-vi.pdf](../../output/pdf/business-feasibility-autism-tutor-matching-vi.pdf).

Báo cáo feasibility mở rộng thành 18 trang, gồm số liệu Việt Nam và quốc tế có ghi rõ
phạm vi, năm, phương pháp và giới hạn suy rộng; kịch bản kinh tế đơn vị chỉ
mang tính minh họa; kiến trúc mục tiêu, luồng coordinator, mô-đun/API, nguyên
tắc xếp hạng có giải thích, kế hoạch pilot, quyền riêng tư và quản trị rủi ro.

## Quy ước bằng chứng

- Ghi ngày chốt dữ liệu và ngày truy cập nguồn.
- Phân biệt số liệu Việt Nam với số liệu quốc tế; nêu tuổi, địa bàn, năm khảo
  sát và phương pháp khi các con số có thể bị hiểu sai.
- Không coi tỷ lệ hiện mắc là số người sẵn sàng mua dịch vụ.
- Đánh dấu rõ mọi giá, chi phí, tỷ lệ chuyển đổi và ngưỡng pilot chưa được đo
  là giả định cần xác thực.
- Với sản phẩm liên quan trẻ em và dữ liệu sức khỏe/khuyết tật, thiết kế luồng
  consent, tối thiểu hóa dữ liệu, bảo vệ riêng tư và human oversight ngay từ
  đầu.
