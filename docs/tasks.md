# Kế Hoạch Phân Công, Hạn Chót & Tiêu Chí Nghiệm Thu (Task Allocation & Acceptance Criteria)

> **Dự án:** Ứng dụng Học Tiếng Anh Phân Tích Phát Âm AI (TH3)  
> **Phiên bản:** 1.0.0-PROPOSAL  
> **Người biên soạn:** Nhóm trưởng (Team Lead)

---

## 1. Ma Trận Trách Nhiệm RACI & Ánh Xạ 7 Checklist TH3

- **R (Responsible):** Người trực tiếp thực hiện nhiệm vụ chính.
- **A (Accountable):** Nhóm trưởng chịu trách nhiệm chung về tính tương thích và hoàn thiện.
- **C (Consulted):** Người được tham vấn, phối hợp dữ liệu.
- **I (Informed):** Người nhận thông báo sau khi module hoàn thành.

| Checklist TH3 | Nội dung công việc | R (Phụ trách) | C (Phối hợp) | Giao diện liên quan |
|---|---|:---:|:---:|---|
| **Mục 1** | Thiết kế CSDL lưu trữ User, Lịch sử, Kết quả phát âm | **TV1** | TV3 (Schema kết quả) | Data Layer & HistoryScreen |
| **Mục 2** | Theo dõi tiến độ: đếm Streak, thống kê thời gian, mục tiêu ngày | **TV2** | TV1 (Query DB) | DashboardScreen |
| **Mục 3** | Tích hợp thu âm và Speech Recognition (STT) | **TV3** | TV4 (Định dạng audio) | PracticeScreen |
| **Mục 4** | Mô hình AI / thuật toán so sánh âm vị (Phoneme Comparison) | **TV3** | TV4 (Cấu trúc âm vị) | Phoneme AI Service |
| **Mục 5** | Module phản hồi: hiển thị điểm, tô màu âm sai, đề xuất bài tập | **TV4** | TV3 (Dữ liệu chấm) | ResultScreen |
| **Mục 6** | Hệ thống thông báo nhắc nhở hàng ngày & hiển thị tiến độ | **TV2** | TV1 (Lưu cài đặt) | SettingsScreen & Local Notifications |
| **Mục 7** | Kiểm thử ứng dụng đa người dùng & nhiều giọng đọc khác nhau | **TV4** | Cả nhóm (Test cases) | Test Reports & QA Run |

---

## 2. Phiếu Giao Việc Chi Tiết Cho Từng Thành Viên (Task Cards)

---

### 📋 Phiếu Giao Việc TV1: Database, Xác Thực, Danh Sách Bài & Lịch Sử
- **Người phụ trách:** **Thành viên 1 (TV1)**
- **Mục tiêu Checklist:** Mục 1 (Cơ sở dữ liệu) + Luồng Đăng nhập, Bài học, Lịch sử.
- **Đầu vào nhận gì:**
  - Lược đồ SQLite tại [docs/data-contract.md](file:///d:/adrstu/th3/docs/data-contract.md).
  - Tệp mẫu `mocks/lessons.json`, `mocks/history_multi_days.json`, `mocks/user_profile.json`.
- **Cần làm:**
  1. Tạo và quản lý SQLite Database cục bộ (hoặc In-memory/Hive repository): bảng `users`, `lessons`, `practice_sessions`, `daily_progress`.
  2. Xây dựng màn hình Đăng nhập (`LoginScreen`): cho phép đổi tài khoản demo hoặc nhập tên.
  3. Xây dựng màn hình Danh sách bài học (`LessonListScreen`): hiển thị danh sách, phân loại theo cấp độ (Beginner/Intermediate/Advanced), hiển thị phiên âm IPA câu mẫu.
  4. Xây dựng màn hình Lịch sử (`HistoryScreen`): hiển thị danh sách các bài đã luyện theo thời gian, bấm vào xem lại chi tiết lượt luyện cũ.
- **Điều kiện hoàn thành (Acceptance Criteria):**
  - Chạy được độc lập với mock data mà không cần backend hay mic.
  - Thêm, sửa, đọc dữ liệu DB không bị crash, không khóa bảng (deadlock).
  - Danh sách bài lọc mượt theo tab cấp độ.
  - Lịch sử hiển thị đúng ngày giờ địa phương (không bị lệch múi giờ UTC).
- **Sản phẩm bàn giao:** Source code màn hình `login`, `lessons`, `history`, module database, unit test SQLite CRUD.
- **Hạn chót hoàn thành:** Mốc Sprint 1 (Ngày 3)

---

### 📋 Phiếu Giao Việc TV2: Dashboard, Động Lực Học (Streak), Mục Tiêu & Nhắc Nhở
- **Người phụ trách:** **Thành viên 2 (TV2)**
- **Mục tiêu Checklist:** Mục 2 (Theo dõi tiến độ, streak, mục tiêu) + Mục 6 (Nhắc nhở học tập).
- **Đầu vào nhận gì:**
  - Đối tượng `UserProfile` và `DailyProgress` từ Repository.
  - Dữ liệu mẫu `mocks/history_multi_days.json` và `mocks/history_with_gaps.json`.
- **Cần làm:**
  1. Xây dựng thuật toán tính Streak chuẩn:
     - Đạt mục tiêu ngày (active duration $\ge$ daily goal) $\rightarrow$ ghi nhận ngày hoàn thành.
     - Nhiều bài trong 1 ngày không làm tăng thêm số ngày streak.
     - Có ngày bỏ học $\rightarrow$ streak reset về 1 khi bắt đầu ngày mới đạt chuẩn.
  2. Xây dựng màn hình Tổng quan (`DashboardScreen`):
     - Hiển thị huy hiệu Streak rực lửa 🔥 với lời động viên tích cực.
     - Thanh tiến trình mục tiêu ngày (Circular/Linear Progress Bar: thời gian học thực tế / thời gian mục tiêu).
     - Biểu đồ thời gian luyện tập trong tuần (7 ngày gần nhất).
     - Nút "Luyện bài hôm nay" chuyển nhanh sang bài tập phù hợp.
  3. Xây dựng màn hình Cài đặt (`SettingsScreen`) & Notification Engine:
     - Cho phép chọn mục tiêu ngày (3, 5, 10, 15 phút).
     - Cho phép chọn giờ nhắc học qua TimePicker và lên lịch thông báo đẩy (Local Notifications).
     - Công tắc chuyển đổi linh hoạt chế độ Mock Mode / Real Mode.
- **Điều kiện hoàn thành (Acceptance Criteria):**
  - Đếm đúng số ngày Streak với cả 2 bộ test case: `history_multi_days.json` (streak = 7) và `history_with_gaps.json` (streak ngắt quãng).
  - Không tăng streak khi người dùng mới chỉ mở ứng dụng mà chưa học đủ thời gian.
  - Nhắc nhở kích hoạt đúng giờ cài đặt (hoặc mô phỏng thông báo thành công).
- **Sản phẩm bàn giao:** Source code màn hình `dashboard`, `settings`, notification service, unit test thuật toán tính streak.
- **Hạn chót hoàn thành:** Mốc Sprint 1 (Ngày 3)

---

### 📋 Phiếu Giao Việc TV3: Thu Âm, Phân Tích Âm Vị AI & Lưu Kết Quả
- **Người phụ trách:** **Thành viên 3 (TV3)**
- **Mục tiêu Checklist:** Mục 3 (Thu âm & Speech Recognition) + Mục 4 (Mô hình AI so sánh âm vị).
- **Đầu vào nhận gì:**
  - Tham số `PracticeScreenArgs` chứa thông tin bài học (`Lesson`).
  - Hợp đồng `SpeechAiService` và `PracticeRepository` tại [docs/api-contract.md](file:///d:/adrstu/th3/docs/api-contract.md).
  - Dữ liệu mẫu `mocks/practice_result_high.json`, `mocks/practice_result_low.json`, `mocks/api_error_responses.json`.
- **Cần làm:**
  1. Xây dựng màn hình Luyện tập (`PracticeScreen`):
     - Hiển thị to rõ câu mẫu tiếng Anh, phiên âm IPA, bản dịch tiếng Việt.
     - Nút phát âm thanh mẫu (Audio Sample / TTS) để người học nghe chuẩn trước khi nói.
     - Nút bấm thu âm: hiển thị hiệu ứng nhấp nháy/sóng âm khi đang thu, đồng hồ đếm `activeDurationSeconds`.
  2. Tích hợp Speech Recognition & AI Phoneme Comparison:
     - Chế độ Mock: trả về kết quả mẫu tức thì từ `mocks/`.
     - Chế độ Real: gửi audio lên API AI (Gemini Multimodal Speech / Whisper + Phoneme Alignment) để đối chiếu âm vị người dùng so với âm vị chuẩn IPA.
  3. **Chịu trách nhiệm lưu kết quả duy nhất:** Sau khi nhận phản hồi AI thành công, gọi `PracticeRepository.savePracticeResult(...)`, sau đó chuyển hướng sang `ResultScreen` kèm đối tượng `PracticeResult`.
  4. Xử lý triệt để các trạng thái lỗi: Không có tiếng nói (`SPEECH_NOT_DETECTED`), ghi âm quá ngắn (`AUDIO_EMPTY`), lỗi mạng, quá tải. Cho phép bấm "Thử lại".
- **Điều kiện hoàn thành (Acceptance Criteria):**
  - Thời gian học chỉ tính lúc đang thu âm, không tính thời gian chờ phản hồi AI.
  - Phân tích đúng cấu trúc `WordEvaluation` và `PhonemeEvaluation`.
  - Không tự phát sinh điểm giả khi AI gặp lỗi.
  - Gọi lưu kết quả chính xác 1 lần, không tạo duplicate records.
- **Sản phẩm bàn giao:** Source code màn hình `practice`, audio recording service, AI comparison service, unit test xử lý lỗi AI.
- **Hạn chót hoàn thành:** Mốc Sprint 2 (Ngày 5)

---

### 📋 Phiếu Giao Việc TV4: Màn Hình Kết Quả, Phân Tích Lỗi Âm Vị & Kế Hoạch Kiểm Thử
- **Người phụ trách:** **Thành viên 4 (TV4)**
- **Mục tiêu Checklist:** Mục 5 (Module phản hồi & hướng dẫn cải thiện) + Mục 7 (Kiểm thử đa giọng nói).
- **Đầu vào nhận gì:**
  - Đối tượng `PracticeResult` từ `ResultScreenArgs`.
  - Các tệp mock: `practice_result_high.json`, `practice_result_low.json`, `practice_result_missing_metrics.json`, `practice_result_empty.json`.
- **Cần làm:**
  1. Xây dựng màn hình Kết quả (`ResultScreen`):
     - Vòng tròn hiển thị điểm tổng thể (0 - 100), chuyển màu theo thang điểm.
     - Hiển thị các chỉ số chi tiết: Accuracy, Fluency, Completeness (ẩn an toàn nếu mang giá trị `null`).
     - Câu mẫu tương tác: Tô màu từng từ (Xanh: đúng, Vàng: cảnh báo, Đỏ: sai).
     - Hộp thoại/BottomSheet chi tiết âm vị: Khi bấm vào từ (VD: `think`), hiển thị bảng so sánh âm vị mong đợi `/θ/` vs âm vị phát âm thực tế `/s/`.
     - Danh sách lời khuyên cải thiện khẩu hình môi, răng, lưỡi do AI đề xuất.
     - Nút "Luyện lại bài này" (Retry) và nút "Bài tiếp theo" / "Về trang chủ".
  2. Xây dựng Kế hoạch Kiểm thử Đa giọng nói (Checklist Mục 7):
     - Thiết lập ma trận kiểm thử với nhiều người dùng (Nam, Nữ, Người mới học, Người phát âm tốt, Người nói giọng địa phương).
     - Tổng hợp báo cáo độ chính xác của AI và các ca kiểm thử biên (Edge cases).
- **Điều kiện hoàn thành (Acceptance Criteria):**
  - Chạy mượt mà, không crash với cả 4 trường hợp dữ liệu mẫu: Điểm cao, Điểm thấp có lỗi âm vị, Thiếu chỉ số phụ (`null`), và Danh sách từ rỗng.
  - Giao diện đẹp, trực quan, dễ hiểu đối với người học ngoại ngữ.
  - Bộ tài liệu test case và biên bản nghiệm thu kiểm thử hoàn chỉnh.
- **Sản phẩm bàn giao:** Source code màn hình `result`, bottom sheet phân tích âm vị, tài liệu test report mục 7.
- **Hạn chót hoàn thành:** Mốc Sprint 2 (Ngày 5)

---

## 3. Quy Trình Phối Hợp Git & Kiểm Soát Thay Đổi (Git Workflow)

1. **Nhánh chính (`main`):**
   - Luôn ở trạng thái biên dịch thành công và chạy được ứng dụng (Green Build).
   - Nghiêm cấm push trực tiếp lên `main`.
2. **Quy tắc đặt tên nhánh tính năng:**
   - TV1: `feature/tv1-database-auth-lessons`
   - TV2: `feature/tv2-dashboard-streak-settings`
   - TV3: `feature/tv3-practice-audio-ai-service`
   - TV4: `feature/tv4-result-feedback-testing`
3. **Quy trình gửi Pull Request (PR):**
   - Mỗi PR chỉ tập trung vào một nhóm màn hình hoặc module đã được giao.
   - Trước khi tạo PR: Bắt buộc chạy lệnh kiểm tra cú pháp và lỗi cảnh báo:
     ```bash
     flutter analyze
     flutter test
     ```
   - Nhóm trưởng review mã nguồn, kiểm tra xem có vi phạm Data Contract hay không trước khi merge vào `main`.
4. **Quản lý thay đổi hợp đồng (Contract Change Management):**
   - Nếu bất kỳ thành viên nào phát hiện cần bổ sung trường dữ liệu mới trong Model hoặc API: **Phải thông báo cho Nhóm trưởng**.
   - Nhóm trưởng cập nhật đồng thời vào `docs/data-contract.md`, cập nhật các file JSON mẫu trong `mocks/`, thông báo cho các thành viên bị ảnh hưởng trước khi code tiếp.

---

## 4. Lộ Trình Phát Triển (Milestones & Deadlines)

```
[Ngày 1]: Nhóm trưởng ban hành Bộ tài liệu + Khung dự án chạy được (Clean Architecture + Mock Services)
   │
   ├─► [Ngày 2 - 3] (Sprint 1): TV1 & TV2 hoàn thiện Khung dữ liệu, Auth, Dashboard, Streak, Settings
   │
   ├─► [Ngày 4 - 5] (Sprint 2): TV3 & TV4 hoàn thiện Module Luyện tập, Thu âm, AI so sánh âm vị, Kết quả
   │
   ├─► [Ngày 6] (Tích hợp & Ghép nối): Tích hợp luồng chạy hoàn chỉnh end-to-end từ Đăng nhập -> Luyện -> Kết quả -> Lịch sử
   │
   └─► [Ngày 7] (QA & Hoàn tất): Kiểm thử đa giọng đọc (Checklist 7), đóng gói ứng dụng, hoàn tất báo cáo nộp bài.
```
