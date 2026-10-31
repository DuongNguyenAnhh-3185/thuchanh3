# Tài liệu Yêu cầu Nghiệp vụ & Phạm vi Dự án (Requirements & Scope)

> **Dự án:** Ứng dụng Học Tiếng Anh Phân Tích Phát Âm AI (TH3)  
> **Phiên bản:** 1.0.0-PROPOSAL  
> **Người biên soạn:** Nhóm trưởng (Team Lead)  
> **Trạng thái:** Đã chốt dùng chung cho toàn đội ngũ phát triển (TV1, TV2, TV3, TV4)

---

## 1. Mục tiêu Dự án & Bối cảnh

Dự án TH3 hướng tới xây dựng một ứng dụng di động hoàn chỉnh nhằm giải quyết hai rào cản lớn nhất của người học tiếng Anh:
1. **Thiếu tính kỷ luật & động lực duy trì:** Khắc phục bằng hệ thống theo dõi chuỗi ngày học liên tục (Streak), thống kê thời gian học thực tế, đặt mục tiêu hàng ngày và hệ thống thông báo nhắc nhở thông minh.
2. **Phát âm sai nhưng không nhận biết được:** Khắc phục bằng công nghệ AI so sánh âm vị (Phoneme Comparison) theo thời gian thực, đối chiếu giọng đọc người dùng với phiên âm quốc tế chuẩn IPA (`en-US`), trực quan hóa lỗi sai đến từng ký tự/âm vị và đề xuất bài tập khắc phục.

---

## 2. Checklist 7 Yêu Cầu Cốt Lõi (Theo Đề Bài TH3)

| Mục | Yêu cầu nghiệp vụ TH3 | Trách nhiệm chính | Trách nhiệm phối hợp |
|---|---|---|---|
| **1** | Thiết kế cơ sở dữ liệu lưu trữ thông tin người dùng, lịch sử luyện tập và kết quả phân tích phát âm | **Nhóm trưởng** (Database & Auth) | TV3 (Cung cấp schema kết quả AI) |
| **2** | Xây dựng tính năng theo dõi tiến độ học tập: đếm số ngày liên tiếp (streak), thống kê thời gian học, đặt mục tiêu hàng ngày | **TV2** (Dashboard & Progress) | Nhóm trưởng (Lấy dữ liệu từ lịch sử) |
| **3** | Tích hợp API nhận dạng giọng nói (Speech Recognition) để thu âm và xử lý phát âm người dùng | **TV3** (Audio & Speech AI) | TV4 (Định dạng âm thanh đầu vào) |
| **4** | Sử dụng mô hình AI hoặc thuật toán so sánh âm vị (Phoneme Comparison) để phân tích độ chính xác và chấm điểm | **TV3** (Phoneme AI Engine) | TV4 (Nhận diện lỗi chi tiết) |
| **5** | Xây dựng module phản hồi: hiển thị điểm số, đánh dấu âm phát âm sai, đề xuất bài tập cải thiện | **TV4** (Result & Feedback UI) | TV3 (Cung cấp dữ liệu điểm từ AI) |
| **6** | Tạo hệ thống thông báo nhắc nhở luyện tập hàng ngày và giao diện hiển thị tiến độ học tập | **TV2** (Settings & Notifications) | Nhóm trưởng (Lưu cấu hình nhắc nhở) |
| **7** | Kiểm thử ứng dụng với nhiều người dùng và các giọng nói khác nhau để đảm bảo độ chính xác của phân tích AI | **TV4** (Testing & QA Lead) | Cả nhóm (Thu thập dữ liệu mẫu) |

---

## 3. Quy Tắc Nghiệp Vụ Chốt Dùng Chung (Business Rules)

### 3.1. Nền tảng & Môi trường thực thi
- **Nền tảng chính:** Flutter (Android API 26+). Hỗ trợ chạy giả lập mượt mà trên Windows Desktop và Android Emulator.
- **Tiêu chuẩn ngôn ngữ & ngữ âm:** Tiếng Anh Mỹ (`en-US`), bảng ký hiệu ngữ âm quốc tế **IPA (International Phonetic Alphabet)**.

### 3.2. Cấu trúc và Nội dung bài học (Lesson)
- Mỗi bài học bắt buộc chứa các thuộc tính:
  - `id`: Mã định danh duy nhất (VD: `les_001`).
  - `title`: Tiêu đề bài học (nêu rõ âm trọng tâm, ví dụ: "Voiceless TH /θ/ - Think & Thought").
  - `level`: Cấp độ (`Beginner`, `Intermediate`, `Advanced`).
  - `text`: Câu mẫu tiếng Anh hoàn chỉnh.
  - `ipa`: Phiên âm IPA chuẩn tương ứng với toàn bộ câu mẫu.
  - `translationVi`: Bản dịch nghĩa tiếng Việt dễ hiểu.
  - `audioSampleUrl`: Đường dẫn âm thanh mẫu người bản xứ phát âm chuẩn.

### 3.3. Quy tắc tính Thời gian Học Thực tế (Active Duration)
- **Chỉ tính thời gian luyện tập thực tế:** Đồng hồ bấm giờ chỉ đếm trong lúc người dùng đang thực sự giữ/bật nút ghi âm và đọc câu mẫu.
- **Loại trừ thời gian chết:** Không tính thời gian người dùng dừng màn hình suy nghĩ, không tính thời gian chờ truyền file qua mạng và **tuyệt đối không tính thời gian chờ AI xử lý chấm điểm**.
- **Đơn vị đo:** Giây (`activeDurationSeconds`).

### 3.4. Quy tắc Mục tiêu Ngày (Daily Target) & Tính Streak
- **Mục tiêu ngày mặc định:** 5 phút (300 giây) thời gian luyện tập tích lũy. Người dùng có thể tùy chỉnh từ 1 đến 30 phút trong Cài đặt.
- **Điều kiện đạt mục tiêu ngày:** Tổng `activeDurationSeconds` trong ngày của người dùng $\ge$ `dailyGoalMinutes * 60`.
- **Múi giờ tính toán:** Căn cứ theo **múi giờ địa phương (Local Timezone)** của thiết bị người dùng (không dùng ngày UTC để chốt streak, tránh trường hợp 7h sáng hôm sau mới tính sang ngày mới).
- **Quy tắc đếm Streak:**
  - Nếu hôm nay đạt mục tiêu và hôm qua cũng đạt mục tiêu $\rightarrow$ `streakCount = streakCount + 1`.
  - Nếu trong cùng một ngày người dùng luyện tập thêm nhiều bài $\rightarrow$ `streakCount` **không tăng thêm** (chỉ tăng tối đa 1 lần/ngày).
  - Nếu ngày hôm qua người dùng không đạt mục tiêu (hoặc bỏ học) và hôm nay bắt đầu đạt mục tiêu $\rightarrow$ `streakCount` reset về `1`.
  - Nếu hôm nay chưa học xong mục tiêu $\rightarrow$ Giữ nguyên trạng thái hiển thị streak của ngày gần nhất và thông báo tiến độ còn lại (VD: "Đã học 3/5 phút").

### 3.5. Quy tắc Hoàn Thành Lượt Luyện & Trách Nhiệm Lưu Trữ (Single Source of Truth)
- Một lượt luyện chỉ được coi là hoàn thành (`status: "completed"`) khi:
  1. Bản thu âm gửi đi có tiếng nói hợp lệ.
  2. Dịch vụ AI trả về kết quả phân tích âm vị thành công.
  3. Kết quả được lưu thành công vào cơ sở dữ liệu.
- **Trách nhiệm lưu trữ duy nhất:** **Module Luyện tập (TV3)** sau khi nhận phản hồi thành công từ AI sẽ gọi hàm lưu vào Database, nhận về `sessionId`, sau đó truyền `sessionId` hoặc đối tượng `PracticeResult` sang **Màn hình Kết quả (TV4)**.
- **Quy tắc chống lưu trùng:** Màn hình Kết quả (TV4) là màn hình hiển thị thụ động (Read-only view), tuyệt đối không được tự động phát sinh thao tác ghi mới vào bảng lịch sử.

### 3.6. Quy tắc Xử lý Lỗi AI & Mạng
- Khi có lỗi (hết pin, ngắt mạng, không có giọng nói, AI quá tải):
  - Hiển thị thông báo lỗi rõ ràng, kèm gợi ý khắc phục (VD: "Không nhận thấy giọng nói, vui lòng đọc to hơn").
  - Cung cấp nút **"Thử lại" (Retry)** ngay tại màn hình luyện tập.
  - **Tuyệt đối không tạo điểm giả** (không gán bừa 50 điểm hay 100 điểm để lấp liếm).
  - **Tuyệt đối không tính lượt lỗi vào lịch sử học tập** hoặc cộng dồn thời gian vào mục tiêu ngày.
- Trường hợp thiếu chỉ số thành phần (ví dụ AI chỉ trả về điểm tổng `overall` nhưng thiếu `fluency`): Các trường còn thiếu mang giá trị `null`, giao diện phải ẩn chỉ số thiếu một cách an toàn mà không bị crash.

### 3.7. Bảo mật & Quản lý Khóa API AI
- **Chế độ Mock (Mặc định):** Mọi thành viên khi clone repository về đều chạy được ngay 100% các chức năng bằng dữ liệu giả (`assets/mocks/`), không bắt buộc có API Key AI hay backend thật.
- **Chế độ Real AI:** Khóa API (Gemini / Whisper / Azure Speech) phải được lưu trữ trong tệp cấu hình bảo mật cục bộ (ví dụ: `.env` được đưa vào `.gitignore`) hoặc thông qua backend proxy trung gian. Nghiêm cấm đưa API Key lên Git repository.
