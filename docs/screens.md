# Đặc Tả Luồng Màn Hình & Phân Công Trách Nhiệm (Screen Flow & Ownership)

> **Dự án:** Ứng dụng Học Tiếng Anh Phân Tích Phát Âm AI (TH3)  
> **Phiên bản:** 1.0.0-PROPOSAL  
> **Người biên soạn:** Nhóm trưởng (Team Lead)

---

## 1. Sơ Đồ Điều Hướng Tổng Thể (Navigation Architecture)

```
                     ┌───────────────────────┐
                     │   Màn hình Đăng nhập  │ (TV1)
                     │     (LoginScreen)     │
                     └───────────┬───────────┘
                                 │ Đăng nhập thành công
                                 ▼
                     ┌───────────────────────┐
                     │   Màn hình Tổng quan  │ (TV2)
                     │   (DashboardScreen)   │
                     └─────┬───────────┬─────┘
          Chọn bài học     │           │ Xem thống kê / Cài đặt
          hoặc Luyện nhanh │           │
                           ▼           ▼
       ┌──────────────────────┐    ┌──────────────────────┐
       │  Danh sách bài học   │    │  Cài đặt & Nhắc nhở  │ (TV2)
       │  (LessonListScreen)  │    │   (SettingsScreen)   │
       └──────────┬───────────┘    └──────────────────────┘
                  │ Chọn `lessonId`
                  ▼
       ┌──────────────────────┐
       │  Màn hình Luyện tập  │ (TV3) ◄────────┐
       │   (PracticeScreen)   │                │ Luyện lại
       └──────────┬───────────┘                │ (Retry)
                  │ Thu âm -> AI chấm -> Lưu   │
                  │ Truyền `PracticeResult`    │
                  ▼                            │
       ┌──────────────────────┐                │
       │   Màn hình Kết quả   │ (TV4) ─────────┘
       │    (ResultScreen)    │
       └──────────┬───────────┘
                  │ Xem lại lịch sử
                  ▼
       ┌──────────────────────┐
       │   Lịch sử luyện tập  │ (TV1)
       │   (HistoryScreen)    │
       └──────────────────────┘
```

---

## 2. Bảng Ma Trận Màn Hình & Người Phụ Trách

| Tên Màn hình | Tên Route | Người phụ trách | Dữ liệu đầu vào (Input) | Hành động người dùng | Màn hình đích (Output Target) |
|---|---|---|---|---|---|
| **Đăng nhập** | `/login` | **TV1** | Không | Bấm "Bắt đầu học" hoặc chọn tài khoản demo | `/dashboard` (Clear stack) |
| **Tổng quan** | `/dashboard` | **TV2** | `UserProfile`, `DailyProgress` | 1. Bấm "Luyện ngay"<br>2. Bấm "Danh sách bài"<br>3. Bấm "Lịch sử"<br>4. Bấm "Cài đặt" | 1. `/practice` (`lessonId` ưu tiên)<br>2. `/lessons`<br>3. `/history`<br>4. `/settings` |
| **Danh sách bài**| `/lessons` | **TV1** | Bộ lọc cấp độ (Tùy chọn) | Chọn một thẻ bài học cụ thể | `/practice` (truyền `Lesson` hoặc `lessonId`) |
| **Luyện tập** | `/practice` | **TV3** | `Lesson` object hoặc `lessonId: String` | 1. Bấm nghe mẫu (TTS)<br>2. Bấm giữ/chạm thu âm<br>3. Bấm "Chấm điểm AI" | `/result` (truyền `PracticeResult`) |
| **Kết quả** | `/result` | **TV4** | `PracticeResult` object | 1. Chạm vào từ để xem lỗi âm vị<br>2. Bấm "Luyện lại"<br>3. Bấm "Về trang chủ" | 1. Mở BottomSheet phân tích âm vị<br>2. `/practice` (`lessonId`)<br>3. `/dashboard` (Pop to root) |
| **Lịch sử** | `/history` | **TV1** | `userId: String` | Bấm vào 1 mục trong danh sách lịch sử | `/result` (mở lại kết quả cũ đã lưu) |
| **Cài đặt** | `/settings` | **TV2** | `UserProfile` | 1. Chọn số phút mục tiêu (3-15p)<br>2. Đổi giờ nhắc học (TimePicker)<br>3. Bật/tắt Mock Mode | Lưu cấu hình, quay lại `/dashboard` |

---

## 3. Quy Ước Truyền Dữ Liệu Giữa Các Màn Hình (Navigation Contract)

Để tránh tình trạng "màn hình này đợi `lessonId` nhưng màn hình kia lại truyền `filePath`", nhóm thống nhất các cấu trúc đối tượng trung gian (Route Arguments) như sau:

### 3.1. Truyền vào Màn hình Luyện tập (`/practice`)
- **Kiểu dữ liệu:** `PracticeScreenArgs`
  ```dart
  class PracticeScreenArgs {
    final String lessonId;
    final Lesson? initialLesson; // Tùy chọn truyền trước để tránh tải lại
    PracticeScreenArgs({required this.lessonId, this.initialLesson});
  }
  ```
- **Hành vi:** Màn hình tự nạp thông tin bài học từ `LessonRepository.getLessonById(lessonId)` nếu `initialLesson == null`.

### 3.2. Truyền vào Màn hình Kết quả (`/result`)
- **Kiểu dữ liệu:** `ResultScreenArgs`
  ```dart
  class ResultScreenArgs {
    final PracticeResult result; // Đã chấm và đã được lưu ở PracticeScreen
    final bool isFromHistory;    // True nếu mở từ lịch sử (ẩn nút 'Luyện lại' hoặc đổi nhãn)
    ResultScreenArgs({required this.result, this.isFromHistory = false});
  }
  ```
- **Hành vi:** Màn hình chỉ nhận kết quả để hiển thị. Tuyệt đối không gọi lệnh insert database tại màn hình này.

---

## 4. Chi Tiết Từng Màn Hình & Trạng Thái Xử Lý

### 4.1. Màn hình Đăng nhập (LoginScreen) - Phụ trách: TV1
- **Mục tiêu:** Cho phép người dùng đăng nhập bằng tên hoặc tài khoản demo nhanh.
- **Thành phần UI:**
  - Logo ứng dụng học phát âm AI.
  - Trường nhập tên người dùng / Chọn profile có sẵn (`usr_dev_01`, `usr_dev_02`).
  - Nút "Bắt đầu luyện tập".
- **Trạng thái:**
  - `Loading`: Hiển thị vòng xoay tải thông tin người dùng.
  - `Success`: Điều hướng sang `/dashboard`.

### 4.2. Màn hình Tổng quan (DashboardScreen) - Phụ trách: TV2
- **Mục tiêu:** Kích hoạt động lực, hiển thị chuỗi ngày học (Streak) và mục tiêu ngày.
- **Thành phần UI:**
  - Header: Lời chào người dùng + Avatar.
  - **Streak Badge:** Biểu tượng ngọn lửa 🔥 kèm số ngày học liên tiếp và ghi chú (VD: "5 ngày liên tiếp! Đừng để lửa tắt!").
  - **Daily Goal Progress Card:** Thanh tiến trình tròn hoặc thanh ngang hiển thị `thời gian đã luyện / mục tiêu` (VD: "3/5 phút - Đạt 60%").
  - Nút CTA lớn: "Luyện bài gợi ý hôm nay".
  - Thống kê tuần: Biểu đồ cột nhỏ hiển thị số phút luyện từng ngày trong tuần.
  - Danh sách 2-3 bài học gần nhất hoặc lịch sử vừa hoàn thành.

### 4.3. Màn hình Danh sách bài học (LessonListScreen) - Phụ trách: TV1
- **Mục tiêu:** Duyệt kho bài học theo cấp độ và chủ đề âm vị.
- **Thành phần UI:**
  - Thanh tìm kiếm bài học.
  - Filter Tabs: `Tất cả`, `Cơ bản (Beginner)`, `Trung cấp (Intermediate)`, `Nâng cao (Advanced)`.
  - Danh sách thẻ bài học (`LessonCard`): Tiêu đề, câu mẫu tiếng Anh, phiên âm IPA, tag âm trọng tâm (VD: `/θ/`, `/ð/`, `/ʃ/`).
  - Trạng thái đã hoàn thành (Icon check xanh và điểm cao nhất đạt được nếu đã từng luyện).

### 4.4. Màn hình Luyện tập (PracticeScreen) - Phụ trách: TV3
- **Mục tiêu:** Thu âm giọng nói, đo đạc thời gian học thực tế và kích hoạt AI chấm điểm.
- **Thành phần UI:**
  - Header: Tiêu đề bài học, cấp độ.
  - Thẻ câu mẫu trọng tâm: Câu tiếng Anh in đậm kích thước lớn, phiên âm IPA bên dưới, bản dịch tiếng Việt mờ hơn.
  - Nút loa phát âm thanh mẫu (Audio Sample / TTS) để người dùng nghe trước.
  - Khu vực thu âm:
    - Nút Micro to ở trung tâm (kèm hiệu ứng sóng âm nhấp nháy khi đang ghi âm).
    - Đồng hồ đếm thời gian thu âm thực tế (`activeDurationSeconds`).
    - Nút "Nghe lại bản thu" (Review recording).
    - Nút "Gửi chấm điểm AI" (Submit for Evaluation).
- **Trạng thái:**
  - `Idle`: Chờ người dùng nhấn thu âm.
  - `Recording`: Đang thu âm, đếm giây, chặn thoát màn hình đột ngột.
  - `Recorded`: Đã thu âm xong, cho phép nghe lại hoặc xóa thu lại.
  - `Analyzing`: Đang gửi âm thanh tới AI (hiển thị hiệu ứng AI đang phân tích âm vị, vô hiệu hóa nút gửi trùng).
  - `Error`: Báo lỗi micro hoặc lỗi AI, hiển thị nút "Thử lại".

### 4.5. Màn hình Kết quả (ResultScreen) - Phụ trách: TV4
- **Mục tiêu:** Trực quan hóa điểm số, phát hiện âm sai và hướng dẫn cải thiện.
- **Thành phần UI:**
  - **Vòng tròn Điểm Tổng Thể (Overall Score Gauge):** 0 - 100 điểm, chuyển màu linh hoạt (Xanh lá > 80, Vàng 60-79, Đỏ < 60).
  - **Chỉ số chi tiết (Sub-scores):** Accuracy (Độ chính xác), Fluency (Độ lưu loát), Completeness (Độ hoàn chỉnh). Nếu chỉ số nào là `null`, tự động ẩn khéo léo.
  - **Bản đồ câu tương tác (Word Analysis View):**
    - Toàn bộ câu được hiển thị từng từ với mã màu (Xanh: chuẩn, Vàng: cần chú ý, Đỏ: sai âm).
    - Chạm vào từng từ sẽ bung ra thẻ chi tiết hiển thị: Phiên âm mong đợi vs Phiên âm thực tế của người dùng (VD: Kỳ vọng `/θɪŋk/` - Thực tế người đọc phát âm `/sɪŋk/`).
  - **Lời khuyên cải thiện phát âm (Feedback & Tips):** Danh sách mẹo đặt khẩu hình môi, răng, lưỡi do AI đề xuất.
  - Thanh nút điều hướng dưới cùng: Nút "Luyện lại bài này" (Retry) và nút "Bài tiếp theo" / "Về trang chủ".

### 4.6. Màn hình Lịch sử (HistoryScreen) - Phụ trách: TV1
- **Mục tiêu:** Xem lại quá trình rèn luyện theo thời gian.
- **Thành phần UI:**
  - Danh sách sắp xếp theo ngày giờ mới nhất giảm dần.
  - Mỗi hàng hiển thị: Tên bài, ngày giờ (format giờ địa phương), điểm số, thời lượng luyện tập.
  - Chạm vào hàng bất kỳ $\rightarrow$ Mở `/result` với dữ liệu chi tiết của lượt đó.

### 4.7. Màn hình Cài đặt & Nhắc học (SettingsScreen) - Phụ trách: TV2
- **Mục tiêu:** Cấu hình mục tiêu học tập và thiết lập giờ thông báo nhắc nhở.
- **Thành phần UI:**
  - Chọn mục tiêu ngày: Chips chọn `3 phút`, `5 phút` (mặc định), `10 phút`, `15 phút`.
  - Công tắc bật/tắt nhắc nhở hàng ngày (Daily Reminder Switch).
  - Khung chọn giờ nhắc nhở (Time Picker, ví dụ `20:00` tối).
  - Công tắc chuyển chế độ dữ liệu: `Sử dụng Dữ liệu giả (Mock Mode)` vs `Dịch vụ AI Thật (Real Mode)`.
  - Nút lưu cấu hình và khôi phục cài đặt gốc.
