# Kế Hoạch Phân Công, Hạn Chót & Tiêu Chí Nghiệm Thu (Task Allocation & Acceptance Criteria)

> **Dự án:** Ứng dụng Học Tiếng Anh Phân Tích Phát Âm AI (TH3)  
> **Cơ cấu nhân sự:** **4 thành viên (Bao gồm Nhóm trưởng)**  
> **Phiên bản:** 2.0.0-REVISED (Đã phân bổ lại trách nhiệm code trực tiếp cho Nhóm trưởng)

---

## 1. Cơ Cấu Nhân Sự 4 Thành Viên & Ma Trận Trách Nhiệm RACI

Tổng quy mô nhóm là **4 thành viên**. Nhóm trưởng trực tiếp đảm nhận vai trò Trưởng nhóm kỹ thuật, chịu trách nhiệm kiến trúc và trực tiếp code một module trọng tâm.

| Thành viên | Họ tên (Dự kiến) | Vai trò chính | Module trực tiếp phụ trách | Checklist TH3 |
|---|---|---|---|:---:|
| **Thành viên 1 (Nhóm trưởng)** | *Sinh viên 1* | **Team Lead & Data/Auth Dev** | Kiến trúc hệ thống, Cơ sở dữ liệu SQLite, Đăng nhập, Danh sách bài & Lịch sử | **Mục 1** (+ Quản lý) |
| **Thành viên 2** | *Sinh viên 2* | **Progress & Motivation Dev** | Màn hình Tổng quan, Thuật toán Streak, Đo thời gian học thực tế, Cài đặt & Thông báo nhắc học | **Mục 2 & Mục 6** |
| **Thành viên 3** | *Sinh viên 3* | **Audio & AI Engine Dev** | Màn hình Luyện tập, Thu âm micro, Tích hợp Speech Recognition & Mô hình AI so sánh âm vị, Lưu kết quả | **Mục 3 & Mục 4** |
| **Thành viên 4** | *Sinh viên 4* | **Feedback UI & QA Lead** | Màn hình Kết quả, Trực quan hóa âm vị IPA, Module phản hồi/gợi ý sửa, Kế hoạch kiểm thử đa giọng nói | **Mục 5 & Mục 7** |

> *(Lưu ý linh hoạt: Nếu Nhóm trưởng mạnh về AI/Audio hơn Data, Nhóm trưởng và Thành viên 3 có thể hoán đổi module cho nhau mà không làm thay đổi các hợp đồng giao tiếp giữa các màn hình).*

---

### Ma Trận RACI Ánh Xạ 7 Mục Checklist TH3

- **R (Responsible):** Người trực tiếp code và hoàn thiện.
- **A (Accountable):** Nhóm trưởng chịu trách nhiệm nghiệm thu và ghép nối chung.
- **C (Consulted):** Người được tham vấn dữ liệu/giao diện.
- **I (Informed):** Người nhận thông báo sau khi module hoàn thành.

| Checklist TH3 | Nội dung yêu cầu đề bài | R (Trực tiếp làm) | A (Chịu trách nhiệm) | C (Phối hợp) | I (Theo dõi) |
|---|---|:---:|:---:|:---:|:---:|
| **Mục 1** | Thiết kế CSDL lưu trữ User, Lịch sử, Kết quả phát âm | **Nhóm trưởng** | Nhóm trưởng | TV3 (Schema AI) | TV2, TV4 |
| **Mục 2** | Theo dõi tiến độ: đếm Streak, thời gian học, mục tiêu ngày | **TV2** | Nhóm trưởng | Nhóm trưởng (Query DB) | TV3, TV4 |
| **Mục 3** | Thu âm và Speech Recognition (STT) | **TV3** | Nhóm trưởng | TV4 (Format audio) | Nhóm trưởng |
| **Mục 4** | Mô hình AI / thuật toán so sánh âm vị (Phoneme comparison) | **TV3** | Nhóm trưởng | TV4 (Cấu trúc âm vị) | TV2 |
| **Mục 5** | Module phản hồi: hiển thị điểm, tô màu âm sai, đề xuất bài tập | **TV4** | Nhóm trưởng | TV3 (Dữ liệu chấm) | TV2 |
| **Mục 6** | Hệ thống thông báo nhắc nhở hàng ngày & hiển thị tiến độ | **TV2** | Nhóm trưởng | Nhóm trưởng (Lưu cài đặt) | TV3, TV4 |
| **Mục 7** | Kiểm thử ứng dụng đa người dùng & nhiều giọng đọc khác nhau | **TV4** | Nhóm trưởng | Cả nhóm (Góp giọng) | Cả nhóm |

---

## 2. Phiếu Giao Việc Chi Tiết Cho 4 Thành Viên (Task Cards)

---

### 📋 Phiếu Giao Việc: Thành Viên 1 (Nhóm Trưởng)
- **Họ tên & Vai trò:** **Nhóm trưởng (Team Lead & Data/Auth Dev)**
- **Checklist phụ trách:** **Mục 1** (Cơ sở dữ liệu người dùng, lịch sử, kết quả) + Quản trị dự án.
- **Màn hình phụ trách:**
  1. `LoginScreen` (`/login`): Chọn tài khoản demo, nhập tên người học.
  2. `LessonListScreen` (`/lessons`): Danh sách bài học, lọc theo cấp độ (Cơ bản / Trung cấp / Nâng cao), xem phiên âm IPA câu mẫu.
  3. `HistoryScreen` (`/history`): Danh sách lịch sử các lượt luyện theo thời gian thực, bấm vào xem lại chi tiết kết quả cũ.
- **Nhiệm vụ kỹ thuật:**
  1. Quản lý kho Git, review Pull Request của 3 thành viên, giữ nhánh `main` luôn "Green Build".
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

### 📋 Phiếu Giao Việc: Thành Viên 2
- **Họ tên & Vai trò:** **Thành viên 2 (Progress & Motivation Dev)**
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

### 📋 Phiếu Giao Việc: Thành Viên 3
- **Họ tên & Vai trò:** **Thành viên 3 (Audio & AI Engine Dev)**
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

### 📋 Phiếu Giao Việc: Thành Viên 4
- **Họ tên & Vai trò:** **Thành viên 4 (Feedback UI & QA Lead)**
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

## 3. Quy Trình Phối Hợp Nhóm & Tích Hợp Sớm

1. **Quy tắc phân nhánh Git (4 người):**
   - Nhóm trưởng: `feature/lead-database-auth-lessons`
   - TV2: `feature/tv2-dashboard-streak-settings`
   - TV3: `feature/tv3-practice-audio-ai-service`
   - TV4: `feature/tv4-result-feedback-testing`
2. **Quy trình tích hợp:**
   - Hết Sprint 1 (Ngày 3): Nhóm trưởng ghép nối luồng Data + Auth + Dashboard + Streak.
   - Hết Sprint 2 (Ngày 5): Ghép nối luồng Thu âm + AI Phân tích + Kết quả phản hồi.
   - Ngày 6: Chạy kiểm thử End-to-End từ Đăng nhập $\rightarrow$ Chọn bài $\rightarrow$ Thu âm $\rightarrow$ Chấm AI $\rightarrow$ Xem kết quả $\rightarrow$ Cập nhật Streak $\rightarrow$ Xem Lịch sử.
   - Ngày 7: TV4 hoàn thiện báo cáo kiểm thử đa giọng nói, Nhóm trưởng đóng gói nộp bài.
