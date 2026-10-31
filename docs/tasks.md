# Kế Hoạch Phân Công, Hạn Chót & Tiêu Chí Nghiệm Thu (Task Allocation & Acceptance Criteria)

> **Dự án:** Ứng dụng Học Tiếng Anh Phân Tích Phát Âm AI (TH3)  
> **Cơ cấu nhân sự:** **4 thành viên (Bao gồm Nhóm trưởng)**  
> **Repository GitHub:** [https://github.com/DuongNguyenAnhh-3185/thuchanh3](https://github.com/DuongNguyenAnhh-3185/thuchanh3)

---

## 1. Cơ Cấu Nhân Sự 4 Thành Viên & Ma Trận Trách Nhiệm RACI

| STT | Thành viên | Họ và tên | Vai trò kỹ thuật | Module & Checklist TH3 trực tiếp code | Nhánh Git riêng (Feature Branch) |
|:---:|---|---|---|---|---|
| **1** | **Nhóm trưởng** | **Nguyên Anh** | **Team Lead & Data/Auth Dev** | **Mục 1**: Cơ sở dữ liệu SQLite, Đăng nhập, Danh sách bài & Lịch sử | `feature/nguyen-anh-data-auth-lessons` |
| **2** | **Thành viên 1** | **Hoài** | **Progress & Motivation Dev** | **Mục 2 & Mục 6**: Đếm Streak, đo thời gian học thực tế, Mục tiêu ngày, Cài đặt & Thông báo nhắc học | `feature/hoai-dashboard-streak-settings` |
| **3** | **Thành viên 2** | **Cẩm Ly** | **Audio & AI Engine Dev** | **Mục 3 & Mục 4**: Thu âm micro, Tích hợp Speech Recognition & AI so sánh âm vị, Lưu kết quả | `feature/cam-ly-practice-audio-ai` |
| **4** | **Thành viên 3** | **Thái** | **Feedback UI & QA Lead** | **Mục 5 & Mục 7**: Màn hình Kết quả, Trực quan hóa lỗi âm vị IPA, Gợi ý sửa lỗi, Kế hoạch kiểm thử đa giọng nói | `feature/thai-result-feedback-testing` |

---

### Ma Trận RACI Ánh Xạ 7 Mục Checklist TH3

- **R (Responsible):** Người trực tiếp code và hoàn thiện.
- **A (Accountable):** Nhóm trưởng Nguyên Anh chịu trách nhiệm nghiệm thu và ghép nối chung.
- **C (Consulted):** Người được tham vấn dữ liệu/giao diện.
- **I (Informed):** Người nhận thông báo sau khi module hoàn thành.

| Checklist TH3 | Nội dung yêu cầu đề bài | R (Trực tiếp làm) | A (Chịu trách nhiệm) | C (Phối hợp) | I (Theo dõi) |
|---|---|:---:|:---:|:---:|:---:|
| **Mục 1** | Thiết kế CSDL lưu trữ User, Lịch sử, Kết quả phát âm | **Nguyên Anh** | Nguyên Anh | Cẩm Ly (Schema AI) | Hoài, Thái |
| **Mục 2** | Theo dõi tiến độ: đếm Streak, thời gian học, mục tiêu ngày | **Hoài** | Nguyên Anh | Nguyên Anh (Query DB) | Cẩm Ly, Thái |
| **Mục 3** | Thu âm và Speech Recognition (STT) | **Cẩm Ly** | Nguyên Anh | Thái (Format audio) | Nguyên Anh |
| **Mục 4** | Mô hình AI / thuật toán so sánh âm vị (Phoneme comparison) | **Cẩm Ly** | Nguyên Anh | Thái (Cấu trúc âm vị) | Hoài |
| **Mục 5** | Module phản hồi: hiển thị điểm, tô màu âm sai, đề xuất bài tập | **Thái** | Nguyên Anh | Cẩm Ly (Dữ liệu chấm) | Hoài |
| **Mục 6** | Hệ thống thông báo nhắc nhở hàng ngày & hiển thị tiến độ | **Hoài** | Nguyên Anh | Nguyên Anh (Lưu cài đặt) | Cẩm Ly, Thái |
| **Mục 7** | Kiểm thử ứng dụng đa người dùng & nhiều giọng đọc khác nhau | **Thái** | Nguyên Anh | Cả nhóm (Góp giọng) | Cả nhóm |

---

## 2. Phiếu Giao Việc Chi Tiết Cho Từng Thành Viên (Task Cards)

---

### 📋 Phiếu Giao Việc: Nhóm Trưởng (Nguyên Anh)
- **Họ tên & Vai trò:** **Nguyên Anh (Team Lead & Data/Auth Dev)**
- **Nhánh Git làm việc:** `feature/nguyen-anh-data-auth-lessons`
- **Checklist phụ trách:** **Mục 1** (Cơ sở dữ liệu người dùng, lịch sử, kết quả) + Quản trị dự án.
- **Màn hình phụ trách:**
  1. `LoginScreen` (`/login`): Chọn tài khoản demo, nhập tên người học.
  2. `LessonListScreen` (`/lessons`): Danh sách bài học, lọc theo cấp độ (Cơ bản / Trung cấp / Nâng cao), xem phiên âm IPA câu mẫu.
  3. `HistoryScreen` (`/history`): Danh sách lịch sử các lượt luyện theo thời gian thực, bấm vào xem lại chi tiết kết quả cũ.
- **Nhiệm vụ kỹ thuật:**
  1. Quản lý kho Git, review Pull Request của Hoài, Cẩm Ly, Thái; giữ nhánh `main` luôn "Green Build".
  2. Triển khai tầng cơ sở dữ liệu SQLite cục bộ (hoặc In-memory/Hive) theo đúng lược đồ tại [docs/data-contract.md](file:///d:/adrstu/th3/docs/data-contract.md).
  3. Cung cấp triển khai của `LessonRepository`, `AuthRepository`, `PracticeRepository`.
- **Dữ liệu phát triển:** `mocks/lessons.json`, `mocks/history_multi_days.json`, `mocks/user_profile.json`.
- **Tiêu chí nghiệm thu (Acceptance Criteria):**
  - Chạy mượt mà độc lập với mock data.
  - Thao tác CRUD Database không bị crash, không deadlock.
  - Lịch sử hiển thị chuẩn xác ngày giờ địa phương (không lệch múi giờ UTC).
  - Code sạch, tuân thủ `flutter analyze` 0 issues.
- **Hạn chót hoàn thành:** Sprint 1 (Ngày 3)

---

### 📋 Phiếu Giao Việc: Thành Viên 1 (Hoài)
- **Họ tên & Vai trò:** **Hoài (Progress & Motivation Dev)**
- **Nhánh Git làm việc:** `feature/hoai-dashboard-streak-settings`
- **Checklist phụ trách:** **Mục 2** (Theo dõi tiến độ, streak, thời gian học, mục tiêu) + **Mục 6** (Hệ thống thông báo nhắc nhở).
- **Màn hình phụ trách:**
  1. `DashboardScreen` (`/dashboard`):
     - Huy hiệu ngọn lửa Streak 🔥 với câu chúc khích lệ.
     - Thanh tiến trình mục tiêu ngày (% và thời gian đã học / mục tiêu).
     - Biểu đồ cột thống kê 7 ngày gần nhất.
     - Nút CTA chuyển nhanh sang bài tập hôm nay.
  2. `SettingsScreen` (`/settings`):
     - Chọn mục tiêu ngày (3, 5, 10, 15 phút).
     - Bật/tắt và chọn giờ thông báo nhắc học (TimePicker).
     - Công tắc chuyển đổi chế độ Mock Mode / Real Mode.
- **Nhiệm vụ kỹ thuật:**
  1. Cài đặt thuật toán tính Streak chuẩn:
     - Đạt mục tiêu ngày (active duration $\ge$ daily goal) $\rightarrow$ ghi nhận hoàn thành.
     - Học nhiều bài trong ngày không tăng thêm số ngày streak.
     - Có ngày bỏ học $\rightarrow$ reset streak về 1 khi bắt đầu ngày mới đạt mục tiêu.
  2. Tích hợp `ReminderNotificationService` (Local Notifications) để đặt lịch thông báo hàng ngày.
- **Dữ liệu phát triển:** `mocks/history_multi_days.json`, `mocks/history_with_gaps.json`, `mocks/user_profile.json`.
- **Tiêu chí nghiệm thu (Acceptance Criteria):**
  - Tính đúng streak cho cả 2 bộ test case (streak 7 ngày liên tục và streak bị đứt quãng).
  - Không tăng streak khi người dùng chưa học đủ số phút mục tiêu.
  - Lên lịch thông báo chính xác theo giờ đã chọn.
- **Hạn chót hoàn thành:** Sprint 1 (Ngày 3)

---

### 📋 Phiếu Giao Việc: Thành Viên 2 (Cẩm Ly)
- **Họ tên & Vai trò:** **Cẩm Ly (Audio & AI Engine Dev)**
- **Nhánh Git làm việc:** `feature/cam-ly-practice-audio-ai`
- **Checklist phụ trách:** **Mục 3** (Thu âm & Speech Recognition) + **Mục 4** (Mô hình AI so sánh âm vị).
- **Màn hình phụ trách:**
  - `PracticeScreen` (`/practice`):
    - Thẻ câu mẫu in to, phiên âm IPA, bản dịch nghĩa.
    - Nút nghe người bản xứ đọc mẫu (TTS / Audio Sample).
    - Bộ nút micro (hiệu ứng sóng âm pulsing khi thu âm), đồng hồ đếm `activeDurationSeconds`.
    - Hộp công cụ kiểm thử nhanh dữ liệu giả (chuyển đổi Điểm cao / Điểm thấp / Mô phỏng lỗi AI).
- **Nhiệm vụ kỹ thuật:**
  1. Tích hợp dịch vụ thu âm `AudioRecordingService` (đo chính xác thời gian thu âm thực tế).
  2. Tích hợp `SpeechAiService`:
     - Mock Mode: Trả về kết quả phân tích âm vị mẫu từ `mocks/`.
     - Real Mode: Gửi audio đến API AI (Gemini Multimodal / Whisper) để nhận dạng và bóc tách âm vị đối chiếu với IPA chuẩn.
  3. **Chịu trách nhiệm lưu kết quả duy nhất:** Khi AI trả về thành công $\rightarrow$ gọi `PracticeRepository.savePracticeResult(result)` lưu vào DB $\rightarrow$ chuyển sang `ResultScreen` kèm `PracticeResult`.
  4. Xử lý triệt để các mã lỗi: `AUDIO_EMPTY`, `SPEECH_NOT_DETECTED`, `AI_TIMEOUT`. Không bao giờ tạo điểm giả khi có lỗi.
- **Dữ liệu phát triển:** `mocks/practice_result_high.json`, `mocks/practice_result_low.json`, `mocks/api_error_responses.json`.
- **Tiêu chí nghiệm thu (Acceptance Criteria):**
  - Chỉ tính thời gian đang thu âm, không tính thời gian chờ AI phản hồi.
  - Không phát sinh điểm giả khi AI báo lỗi; hiển thị thông báo và nút "Thử lại".
  - Lưu kết quả vào DB chính xác 1 lần, không tạo bản ghi trùng lặp.
- **Hạn chót hoàn thành:** Sprint 2 (Ngày 5)

---

### 📋 Phiếu Giao Việc: Thành Viên 3 (Thái)
- **Họ tên & Vai trò:** **Thái (Feedback UI & QA Lead)**
- **Nhánh Git làm việc:** `feature/thai-result-feedback-testing`
- **Checklist phụ trách:** **Mục 5** (Module phản hồi, đánh dấu âm sai, gợi ý) + **Mục 7** (Kiểm thử đa giọng nói).
- **Màn hình phụ trách:**
  - `ResultScreen` (`/result`):
    - Vòng tròn điểm tổng thể (0 - 100), chuyển màu theo mức điểm (Xanh $\ge 80$, Vàng $60-79$, Đỏ $< 60$).
    - Bảng chỉ số phụ: Accuracy, Fluency, Completeness (ẩn an toàn nếu `null`).
    - Bản đồ câu tương tác: Tô màu từng từ (Xanh: đúng, Vàng: cần chú ý, Đỏ: sai âm vị).
    - BottomSheet đối chiếu âm vị: Khi bấm vào từ (VD: `think`), hiển thị âm vị chuẩn `/θ/` vs âm vị phát âm thực tế `/s/`.
    - Danh sách mẹo khẩu hình miệng, môi, răng, lưỡi do AI đề xuất.
    - Nút "Luyện lại bài này" (Retry) và nút "Về trang chủ".
- **Nhiệm vụ kỹ thuật:**
  1. Xây dựng giao diện hiển thị thụ động (Read-only view), tuyệt đối không gọi lệnh ghi đè database tại màn hình này.
  2. Xây dựng Kế hoạch Kiểm thử Đa giọng nói (Checklist Mục 7):
     - Thiết lập ma trận thử nghiệm: Giọng nam, giọng nữ, người mới bắt đầu, người phát âm tốt, người nói giọng vùng miền.
     - Lập bảng tổng kết độ chính xác nhận diện âm vị và biên bản nghiệm thu sản phẩm.
- **Dữ liệu phát triển:** `mocks/practice_result_high.json`, `mocks/practice_result_low.json`, `mocks/practice_result_missing_metrics.json`, `mocks/practice_result_empty.json`.
- **Tiêu chí nghiệm thu (Acceptance Criteria):**
  - Hiển thị mượt mà không crash với cả 4 ca kiểm thử: Điểm cao, Điểm thấp có lỗi âm vị, Thiếu chỉ số phụ (`null`), và Danh sách từ rỗng.
  - Giao diện đẹp mắt, dễ hiểu với người học tiếng Anh.
  - Bàn giao báo cáo kiểm thử đa giọng đọc hoàn chỉnh cho nhóm.
- **Hạn chót hoàn thành:** Sprint 2 (Ngày 5)

---

## 3. Quy Trình Phối Hợp Nhánh Git (Git Branching Strategy)

1. **Nhánh chính (`main`):**
   - Được bảo vệ, luôn ở trạng thái chạy được 100%.
2. **Quy tắc phân nhánh riêng:**
   - **Nguyên Anh (Lead):** `git checkout -b feature/nguyen-anh-data-auth-lessons`
   - **Hoài (TV1):** `git checkout -b feature/hoai-dashboard-streak-settings`
   - **Cẩm Ly (TV2):** `git checkout -b feature/cam-ly-practice-audio-ai`
   - **Thái (TV3):** `git checkout -b feature/thai-result-feedback-testing`
3. **Quy trình gửi Pull Request (PR):**
   - Trước khi tạo PR: Chạy `flutter analyze` và `flutter test` đảm bảo 0 lỗi.
   - Nhóm trưởng Nguyên Anh review, kiểm tra Data Contract và merge vào `main`.
