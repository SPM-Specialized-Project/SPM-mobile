# Kho tri thức RAG — Tutor Support System

Bản tiếng Việt dựa trên [specification Prism](https://prism.openai.com/?u=a2be7451-b86c-491f-9e0b-f3b6eee1edc2&pg=1&m=main.tex), đối chiếu với bản xuất LaTeX ngày 08/11/2026. Mỗi mục cấp 2 là một đoạn truy xuất. Nội dung mô tả nghiệp vụ trong thiết kế, chưa xác nhận nút, màn hình hay tích hợp trên app hiện tại.

- `design`: mô tả thiết kế HCMUT.
- `proposed`: đề xuất mở rộng mobile, chưa xác nhận triển khai.
- `unresolved`: tài liệu có quy tắc chưa nhất quán; chỉ nêu điểm cần chốt.

## UC-1 — Đăng nhập
Vai trò: student, tutor
Trạng thái: design
Nguồn: UC-1 · Functional Requirements → Common (a)
Câu hỏi mẫu: đăng nhập thế nào | tài khoản nào dùng để đăng nhập | đăng nhập bằng HCMUT SSO | tài khoản HCMUT SSO để đăng nhập | không đăng nhập được

1. Mở chức năng đăng nhập và chọn phương thức tài khoản trường theo thiết kế.
2. Xác thực qua HCMUT SSO. Sau khi thành công, hệ thống hiển thị chức năng theo vai trò.
3. Nếu hệ thống báo sai thông tin, kiểm tra lại dữ liệu đăng nhập. Nếu dịch vụ xác thực lỗi hoặc không truy cập được, thử lại khi dịch vụ hoạt động.

HCMUT SSO và DATACORE là tích hợp được đề xuất trong đặc tả. Không chia sẻ mật khẩu với trợ lý.

## UC-3.1 — Tìm lớp phụ đạo
Vai trò: student
Trạng thái: design
Màn hình app: courses
Nguồn: UC-3.1 · Functional Requirements → Manage Enrollment (c)
Câu hỏi mẫu: tìm lớp | tìm lớp phụ đạo theo môn | tìm lớp theo giờ hoặc khoa | lọc lớp theo tutor | tìm lớp không có kết quả

1. Sau khi đăng nhập, mở chức năng tìm lớp phụ đạo.
2. Nhập môn hoặc chọn tiêu chí như thời gian, khoa hoặc tutor.
3. Xem danh sách phù hợp và chọn lớp để xem trước khi đăng ký.
4. Nếu không có kết quả, điều chỉnh bộ lọc. Nếu vẫn không có lớp phù hợp, xem hướng dẫn yêu cầu mở lớp (UC-3.3).

## UC-3.2 — Đăng ký tham gia lớp
Vai trò: student
Trạng thái: design
Màn hình app: more
Nguồn: UC-3.2 · Functional Requirements → Manage Enrollment (c)
Câu hỏi mẫu: đăng ký lớp | đăng ký lớp phụ đạo | tham gia lớp phụ đạo | đăng ký vào lớp mới thế nào | lớp đầy có đăng ký được không | đăng ký bị trùng lịch | đăng ký chưa được tutor duyệt | đăng ký lớp đang chờ duyệt

1. Chọn một lớp đang mở đăng ký.
2. Gửi đăng ký. Hệ thống kiểm tra chỗ trống, lịch trùng và điều kiện tiên quyết của lớp.
3. Nếu hợp lệ, yêu cầu vào danh sách chờ tutor duyệt. Chờ duyệt chưa có nghĩa là đã vào lớp.
4. Khi tutor chấp thuận, hệ thống thông báo xác nhận. Nếu bị từ chối, bạn có thể tìm lớp khác.

Lớp không được vượt sĩ số tối đa. Nếu lịch bị trùng hoặc không đủ điều kiện, hãy chọn lớp phù hợp khác.

## UC-3.2-T — Duyệt đăng ký của sinh viên
Vai trò: tutor
Trạng thái: design
Nguồn: UC-3.2 · Functional Requirements → Manage Enrollment (c)
Câu hỏi mẫu: duyệt đăng ký lớp | tutor duyệt đơn tham gia | chấp thuận sinh viên vào lớp | từ chối đăng ký sinh viên

Theo luồng đăng ký, tutor xem yêu cầu đang chờ của lớp và quyết định chấp thuận hoặc từ chối. Sau khi chấp thuận, hệ thống xác nhận ghi danh và thông báo cho sinh viên. Nếu từ chối, sinh viên không được ghi danh vào lớp đó. Đặc tả chưa xác nhận vị trí nút duyệt trên mobile.

## UC-3.3 — Gửi yêu cầu mở lớp mới
Vai trò: student
Trạng thái: design
Màn hình app: more
Nguồn: UC-3.3 · Functional Requirements → Manage Enrollment (c)
Câu hỏi mẫu: yêu cầu mở lớp | không có lớp phù hợp | xin mở lớp mới | tạo yêu cầu lớp mới | gửi đề xuất mở lớp

1. Nếu đã tìm nhưng chưa thấy lớp phù hợp, mở chức năng yêu cầu mở lớp.
2. Xem các yêu cầu đang chờ. Nếu đã có yêu cầu phù hợp, tham gia yêu cầu đó thay vì tạo trùng.
3. Nếu chưa có, nhập tên môn, lịch mong muốn và thông tin cần thiết rồi gửi.
4. Khi dữ liệu hợp lệ, yêu cầu được lưu ở trạng thái chờ để khoa xem xét và sinh viên khác có thể tham gia.

Nếu biểu mẫu thiếu dữ liệu hoặc lịch bị trùng, sửa thông tin rồi gửi lại. Gửi yêu cầu không bảo đảm lớp sẽ được mở.

## UC-3.4 — Tham gia yêu cầu mở lớp đang chờ
Vai trò: student
Trạng thái: design
Màn hình app: more
Nguồn: UC-3.4 · Functional Requirements → Manage Enrollment (c)
Câu hỏi mẫu: tham gia yêu cầu mở lớp | join yêu cầu mở lớp đã có | có yêu cầu trùng thì làm sao | tham gia đề xuất mở lớp của bạn khác

1. Mở danh sách yêu cầu mở lớp đang chờ.
2. Chọn yêu cầu phù hợp và xác nhận tham gia. Hệ thống cập nhật số người tham gia.

Chỉ tham gia một lần cho mỗi yêu cầu; không tham gia được yêu cầu đã đóng. Tham gia một yêu cầu mở lớp khác với đăng ký vào lớp đã có.

## UC-3.5 — Rút khỏi yêu cầu mở lớp
Vai trò: student
Trạng thái: design
Màn hình app: more
Nguồn: UC-3.5 · Functional Requirements → Manage Enrollment (c)
Câu hỏi mẫu: rút khỏi yêu cầu mở lớp | hủy yêu cầu mở lớp đang chờ | bỏ tham gia đề xuất mở lớp

1. Mở yêu cầu đang chờ mà bạn đã tạo hoặc tham gia.
2. Chọn rút tham gia và xác nhận. Hệ thống cập nhật số thành viên.
3. Nếu không còn thành viên, đặc tả quy định hệ thống xóa yêu cầu đó.

Luồng này chỉ áp dụng cho yêu cầu mở lớp, không phải hủy ghi danh khỏi một lớp đang học.

## UC-5 — Xem lịch học hoặc lịch dạy
Vai trò: student, tutor
Trạng thái: design
Màn hình app: schedule
Nguồn: UC-5 · Functional Requirements → Common (a)
Câu hỏi mẫu: xem lịch học | xem lịch dạy | xem thời khóa biểu ở đâu | mở lịch học của tôi | tìm lịch các buổi của lớp | chuyển tuần trong lịch

1. Mở mục xem lịch sau khi đăng nhập.
2. Chọn khoảng thời gian hoặc bộ lọc lớp. Lịch chỉ hiển thị các buổi của lớp bạn đã ghi danh hoặc được phân công.
3. Chọn buổi cần xem để biết chủ đề, ngày giờ, địa điểm và thông tin liên quan.

Đây là hướng dẫn tìm lịch; kho tri thức không chứa lịch cá nhân, giờ học hiện tại hoặc thay đổi theo thời gian thực.

## UC-4.1 — Xem thông tin một buổi học
Vai trò: student, tutor
Trạng thái: design
Màn hình app: schedule
Nguồn: UC-4.1 · Functional Requirements → Organize Session (d)
Câu hỏi mẫu: xem chi tiết buổi học | xem phòng học ở đâu | xem link học online | xem bài đăng buổi học | xem nội dung chuẩn bị buổi học

1. Mở bài đăng của buổi học từ thông báo hoặc danh sách buổi học của lớp.
2. Xem ngày giờ, phòng hoặc đường dẫn học online, nội dung buổi học và tài liệu chuẩn bị nếu có.
3. Có thể đọc phần đính kèm hoặc bình luận trong phạm vi quyền của bạn.

## NIUC-5 — Thời điểm nhắc buổi học chưa thống nhất
Vai trò: student, tutor
Trạng thái: unresolved
Nguồn: UC-4.1 · Organize Session (d); NIUC-5 · Non-interactive Functional Requirements
Câu hỏi mẫu: nhắc buổi học trước bao lâu | bao giờ có thông báo buổi học | nhắc lịch học trước 24 giờ hay 2 ngày | khi nào sinh bài đăng buổi học | nhắc buổi học lúc nào

Chưa thể khẳng định một mốc cố định. UC-4.1 mô tả tạo bài đăng trước hai ngày trong luồng chính, nhưng quy tắc của cùng mục ghi 24 giờ. Bảng tổng hợp NIUC-5 còn nhắc mốc 2 ngày và 2 giờ. Cần nhóm sản phẩm xác nhận lịch tạo bài đăng và lịch gửi nhắc riêng trước khi dùng làm hướng dẫn chính thức.

## UC-2.1 — Tutor tạo lớp
Vai trò: tutor
Trạng thái: design
Màn hình app: courses
Nguồn: UC-2.1 · Functional Requirements → Organize Class (b)
Câu hỏi mẫu: tutor tạo lớp | mở lớp phụ đạo được phân công | thêm lớp mới cho tutor | tạo lớp cần nhập gì

1. Mở chức năng quản lý lớp và chọn tạo lớp.
2. Chọn môn được khoa phân công, điền thông tin lớp, lịch, ngày bắt đầu và sĩ số tối thiểu/tối đa.
3. Kiểm tra và lưu thông tin lớp. Tạo lớp và kích hoạt lớp là hai bước khác nhau.

Tutor chỉ tạo lớp cho môn được phân công; ngày bắt đầu không được trước ngày hiện tại.

## UC-2.2 — Tutor chỉnh sửa thông tin lớp
Vai trò: tutor
Trạng thái: design
Màn hình app: courses
Nguồn: UC-2.2 · Functional Requirements → Organize Class (b)
Câu hỏi mẫu: sửa thông tin lớp | đổi sĩ số lớp | thay lịch lớp đã kích hoạt được không | chỉnh sửa lớp tutor

Mở lớp đã tạo, cập nhật thông tin được phép rồi lưu. Sau khi lớp đã kích hoạt, đặc tả không cho đổi lịch lớp hoặc giới hạn sĩ số qua luồng này. Giới hạn mới không được thấp hơn số sinh viên đã đăng ký. Đổi lịch một buổi học là luồng riêng.

## UC-2.3 — Tutor kích hoạt lớp
Vai trò: tutor
Trạng thái: design
Màn hình app: courses
Nguồn: UC-2.3 · Functional Requirements → Organize Class (b)
Câu hỏi mẫu: kích hoạt lớp | điều kiện kích hoạt lớp | lớp thiếu sĩ số tối thiểu có kích hoạt được không

Mở lớp đã tạo và yêu cầu kích hoạt. Chỉ có thể kích hoạt vào hoặc sau ngày bắt đầu và khi đã đủ sĩ số tối thiểu. Nếu chưa đủ điều kiện, kiểm tra lại ngày bắt đầu và số đăng ký.

## UC-2.4 — Tutor xóa lớp
Vai trò: tutor
Trạng thái: design
Màn hình app: courses
Nguồn: UC-2.4 · Functional Requirements → Organize Class (b)
Câu hỏi mẫu: xóa lớp chưa hoạt động | xóa lớp đã kích hoạt | tutor muốn xóa lớp

Trong danh sách lớp phụ trách, chọn lớp chưa hoạt động để thực hiện luồng xóa. Nếu đã có sinh viên đăng ký, hệ thống yêu cầu xác nhận. Không được xóa lớp đang hoạt động theo luồng này.

## UC-4.2 — Tutor tạo buổi học
Vai trò: tutor
Trạng thái: design
Màn hình app: schedule
Nguồn: UC-4.2 · Functional Requirements → Organize Session (d)
Câu hỏi mẫu: tạo buổi học | lên lịch buổi dạy mới | đặt lịch buổi học mới | tỷ lệ xác nhận mở buổi học | sinh viên không xác nhận buổi học

1. Trong lớp phụ trách, chọn tạo buổi học, nhập ngày, giờ, chủ đề và thời lượng.
2. Hệ thống kiểm tra lịch trùng. Nếu có xung đột, đổi thông tin hoặc dùng gợi ý lịch.
3. Hệ thống gửi đề xuất cho sinh viên xác nhận. Use case quy định phải đạt ít nhất 70% xác nhận để mở buổi học; sau một ngày kể từ thông báo, không phản hồi được tính là đồng ý.
4. Khi đủ điều kiện, hệ thống cập nhật lịch và thông báo. Nếu dưới ngưỡng, đề xuất không được mở và các bên được thông báo.

## UC-4.3 — Tutor hủy buổi học
Vai trò: tutor
Trạng thái: design
Màn hình app: schedule
Nguồn: UC-4.3 · Functional Requirements → Organize Session (d)
Câu hỏi mẫu: hủy buổi học | hủy buổi học trước bao lâu | hủy buổi dạy | tại sao không hủy được buổi học | hủy buổi học trước 2 ngày được không

1. Mở buổi học đã lên lịch và chọn chức năng hủy.
2. Theo use case, yêu cầu phải gửi ít nhất 3 ngày trước ngày học; không hủy được buổi đã bắt đầu hoặc kết thúc.
3. Nếu hợp lệ, hệ thống cập nhật lịch và thông báo cho sinh viên. Nếu quá hạn hoặc buổi đã bị hủy, hệ thống báo không xử lý được.

## UC-4.4 — Dùng gợi ý khung giờ
Vai trò: tutor
Trạng thái: design
Nguồn: UC-4.4 · Functional Requirements → Organize Session (d)
Câu hỏi mẫu: gợi ý lịch học | gợi ý khung giờ | đổi lịch dùng giờ gợi ý | tìm khung giờ khác khi lịch trùng

Khi đề xuất lịch, yêu cầu hệ thống gợi ý khung giờ. Hệ thống xét lịch rảnh, lịch sinh viên và quy tắc thời gian/phòng. Tutor xem và chọn một khung giờ để tạo đề xuất xác nhận. Nếu sửa khung giờ đã gợi ý, hệ thống phải kiểm tra lại. Nếu không có khung giờ hợp lệ, đặc tả cho phép nhập tay hoặc cân nhắc buổi bù tuần khác.

## UC-4.5 — Thêm nội dung vào bài đăng buổi học
Vai trò: tutor
Trạng thái: design
Nguồn: UC-4.5 · Functional Requirements → Organize Session (d)
Câu hỏi mẫu: sửa nội dung bài đăng buổi học | thêm ghi chú chuẩn bị cho buổi học | cập nhật tóm tắt buổi học | thêm tài liệu vào bài đăng buổi học

Tutor được phân công mở bài đăng của buổi học đã tạo. Thêm nội dung chuẩn bị, tóm tắt bài học hoặc tài liệu bổ sung và gửi cập nhật. Nếu tệp không được hỗ trợ hoặc nội dung quá dài, sửa lại trước khi gửi. Luồng này sửa nội dung bài đăng, không tự đổi ngày giờ của buổi học.

## UC-7 — Xem hoặc chia sẻ tài liệu lớp
Vai trò: student, tutor
Trạng thái: design
Màn hình app: courses
Nguồn: UC-7 · Functional Requirements → Participate and Report (e)
Câu hỏi mẫu: xem tài liệu lớp | tải tài liệu học tập ở đâu | tutor chia sẻ tài liệu | tải tài liệu lên lớp | nhập tài liệu từ thư viện

- Sinh viên: mở lớp đã ghi danh, vào phần tài nguyên, chọn tệp hoặc liên kết để xem/tải xuống nếu có.
- Tutor: mở phần tài nguyên của lớp phụ trách, tải tệp lên hoặc chọn tài liệu từ thư viện nếu tích hợp thư viện khả dụng.

Tài liệu nhập từ HCMUT LIBRARY được mô tả là chỉ đọc. Tích hợp thư viện chưa được xác nhận trên app hiện tại.

## UC-6.1 — Đăng bài trong lớp
Vai trò: student, tutor
Trạng thái: design
Nguồn: UC-6.1 · Functional Requirements → Participate and Report (e)
Câu hỏi mẫu: đăng bài trong lớp | đặt câu hỏi cho tutor trong lớp | tạo bài viết thảo luận | đăng thông báo cho lớp

1. Mở cộng đồng của lớp mà bạn được quyền truy cập.
2. Chọn tạo bài viết, nhập nội dung và đính kèm nếu phù hợp.
3. Kiểm tra nội dung trước khi gửi. Sau khi hệ thống lưu, bài hiển thị trong cộng đồng lớp.

## UC-6.2 — Bình luận bài đăng
Vai trò: student, tutor
Trạng thái: design
Nguồn: UC-6.2 · Functional Requirements → Participate and Report (e)
Câu hỏi mẫu: bình luận bài đăng | bình luận bài viết của tutor | trả lời bài viết trong lớp | gửi comment cho tutor | thêm bình luận

Mở bài đăng trong cộng đồng lớp, nhập bình luận rồi chọn gửi. Nếu nhập nội dung bằng giọng nói trong tính năng mobile đề xuất, hãy kiểm tra bản nháp trước khi chèn và tự xác nhận gửi.

## UC-8.1 — Tutor điểm danh
Vai trò: tutor
Trạng thái: design
Màn hình app: schedule
Nguồn: UC-8.1 · Functional Requirements → Participate and Report (e); NIUC-14 · Non-interactive Functional Requirements
Câu hỏi mẫu: điểm danh | điểm danh sinh viên thế nào | sửa điểm danh sau bao lâu | đánh dấu đi trễ | sinh viên vắng 3 buổi liên tiếp

1. Mở chi tiết buổi học của lớp bạn được phân công và chọn điểm danh.
2. Đánh dấu từng sinh viên có mặt, vắng hoặc đến muộn, rồi lưu danh sách.
3. Đặc tả cho sửa điểm danh trong 24 giờ sau khi buổi học kết thúc. Nếu lưu lỗi, thử lại sau khi kiểm tra trạng thái đã lưu.

Theo NIUC-14, hệ thống cảnh báo tutor khi một sinh viên vắng ba buổi liên tiếp.

## UC-8.2 — Tutor theo dõi tiến độ sinh viên
Vai trò: tutor
Trạng thái: design
Màn hình app: courses
Nguồn: UC-8.2 · Functional Requirements → Participate and Report (e)
Câu hỏi mẫu: theo dõi tiến độ sinh viên | xem mức độ tham gia của sinh viên | ghi nhận xét tiến độ

Mở lớp được phân công, vào chức năng theo dõi sinh viên, chọn sinh viên đã ghi danh để xem mức tham gia và phản hồi. Tutor có thể lưu nhận xét khi cần. Chỉ truy cập dữ liệu sinh viên của lớp mình phụ trách theo quyền được cấp.

## UC-8.3 — Tutor xem báo cáo lớp
Vai trò: tutor
Trạng thái: design
Màn hình app: courses
Nguồn: UC-8.3 · Functional Requirements → Participate and Report (e)
Câu hỏi mẫu: xem báo cáo lớp | xuất báo cáo lớp | xem thống kê điểm danh và phản hồi | thống kê chuyên cần

Mở báo cáo của lớp phụ trách để xem tổng hợp chuyên cần, mức tham gia và phản hồi. Dùng bộ lọc nếu cần; có thể xuất báo cáo theo thiết kế. Nếu dữ liệu buổi học chưa đầy đủ, báo cáo có thể hiển thị cảnh báo.

## UC-9 — Phản hồi về lớp
Vai trò: student
Trạng thái: design
Màn hình app: courses
Nguồn: UC-9 · Use Case List; NIUC-8 · Non-interactive Functional Requirements
Câu hỏi mẫu: phản hồi về lớp | gửi đánh giá buổi học | đánh giá lớp ở đâu | phản hồi có ẩn danh không

Đặc tả có chức năng phản hồi lớp và mô tả việc gửi biểu mẫu định kỳ. Nếu nhận được thông báo yêu cầu phản hồi, mở biểu mẫu được cung cấp và gửi nhận xét. Tài liệu chưa xác nhận tên nút mobile hoặc điều kiện ẩn danh của từng biểu mẫu; hãy kiểm tra thông tin hiển thị trước khi gửi.

## UC-6.6 — Đọc thành tiếng
Vai trò: student, tutor
Trạng thái: proposed
Nguồn: UC-6.6 · Proposed Mobile Communication and Accessibility Use Cases
Câu hỏi mẫu: đọc thành tiếng | đọc bài viết bằng giọng nói | đọc bình luận bằng TTS | nghe nội dung thay vì đọc | tắt đọc thành tiếng

Trong thiết kế mobile đề xuất, bạn có thể chọn đọc thành tiếng cho bài viết, bình luận hoặc nội dung được hỗ trợ, rồi tạm dừng, tiếp tục hoặc dừng. Văn bản vẫn hiển thị và có thể sử dụng với trình đọc màn hình. Đây là tùy chọn; không cần bật để dùng trợ lý bằng text.

## UC-6.7 — Nhập nội dung bằng giọng nói
Vai trò: student, tutor
Trạng thái: proposed
Nguồn: UC-6.7 · Proposed Mobile Communication and Accessibility Use Cases
Câu hỏi mẫu: nhập bằng giọng nói | viết bình luận bằng giọng nói | dùng STT để viết bình luận | nói thay vì gõ bài viết | microphone bị từ chối khi đọc chính tả | chuyển giọng nói thành text

1. Trong ô soạn nội dung có hỗ trợ STT, chọn nhập bằng giọng nói và cấp quyền microphone khi được hỏi.
2. Nói nội dung, dừng và kiểm tra bản chép. Có thể sửa, nói lại hoặc bỏ.
3. Xác nhận chèn bản chép vào ô soạn; chọn gửi riêng khi đã sẵn sàng.

STT không tự đăng nội dung. Nếu không muốn cấp microphone hoặc nhận dạng lỗi, tiếp tục nhập text.

## UC-6.3-4 — Phát và xem buổi học trực tiếp
Vai trò: student, tutor
Trạng thái: proposed
Nguồn: UC-6.3 và UC-6.4 · Proposed Mobile Communication and Accessibility Use Cases
Câu hỏi mẫu: phát livestream buổi học | xem livestream lớp | xem lại livestream được không | tham gia buổi phát trực tiếp

- Tutor: theo thiết kế đề xuất, chỉ tutor được phân công mới có thể bắt đầu và kết thúc phát trực tiếp cho buổi đủ điều kiện.
- Sinh viên: mở buổi đang phát của lớp đã ghi danh. Máy chủ kiểm tra quyền trước khi cho xem.

Buổi phát trực tiếp không tự ghi hình hoặc tạo video xem lại. Chỉ xem lại được nếu có bản ghi được phép và được xuất bản riêng.

## UC-6.5 — Video bài giảng
Vai trò: student, tutor
Trạng thái: proposed
Nguồn: UC-6.5 · Proposed Mobile Communication and Accessibility Use Cases
Câu hỏi mẫu: xem video bài giảng | tutor tải video bài giảng | đăng video lớp | video đang xử lý có xem được không

Tutor có thể tải video lên, chờ kiểm tra và xử lý, rồi chủ động xuất bản. Sinh viên đã ghi danh chỉ xem được video đã xuất bản và được phép truy cập. Nếu tải hoặc xử lý thất bại, video chưa được công bố.
