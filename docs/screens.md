# Đặc Tả Luồng Màn Hình & Phân Công Trách Nhiệm (Screen Flow & Ownership)

> **Dự án:** Ứng dụng Học Tiếng Anh Phân Tích Phát Âm AI (TH3)  
> **Nhóm thực hiện:** **Nguyên Anh (Lead), Hoài (TV1), Cẩm Ly (TV2), Thái (TV3)**  
> **Repository:** [https://github.com/DuongNguyenAnhh-3185/thuchanh3](https://github.com/DuongNguyenAnhh-3185/thuchanh3)

---

## 1. Sơ Đồ Điều Hướng Tổng Thể (Navigation Architecture)

```
                     ┌───────────────────────┐
                     │   Màn hình Đăng nhập  │ (Nguyên Anh)
                     │     (LoginScreen)     │
                     └───────────┬───────────┘
                                 │ Đăng nhập thành công
                                 ▼
                     ┌───────────────────────┐
                     │   Màn hình Tổng quan  │ (Hoài)
                     │   (DashboardScreen)   │
                     └─────┬───────────┬─────┘
          Chọn bài học     │           │ Xem thống kê / Cài đặt
          hoặc Luyện nhanh │           │
                           ▼           ▼
       ┌──────────────────────┐    ┌──────────────────────┐
       │  Danh sách bài học   │    │  Cài đặt & Nhắc học  │ (Hoài)
       │  (LessonListScreen)  │    │   (SettingsScreen)   │
       └──────────┬───────────┘    └──────────────────────┘
                  │ (Nguyên Anh)
                  │ Chọn `lessonId`
                  ▼
       ┌──────────────────────┐
       │  Màn hình Luyện tập  │ (Cẩm Ly) ◄────────────┐
       │   (PracticeScreen)   │                       │ Luyện lại
       └──────────┬───────────┘                       │ (Retry)
                  │ Thu âm -> AI chấm -> Lưu vào DB   │
                  │ Truyền `PracticeResult`           │
                  ▼                                   │
       ┌──────────────────────┐                       │
       │   Màn hình Kết quả   │ (Thái) ───────────────┘
       │    (ResultScreen)    │
       └──────────┬───────────┘
                  │ Xem lại lịch sử
                  ▼
       ┌──────────────────────┐
       │   Lịch sử luyện tập  │ (Nguyên Anh)
       │   (HistoryScreen)    │
       └──────────────────────┘
```

---

## 2. Bảng Ma Trận Màn Hình & Người Phụ Trách (4 Thành Viên)

| Tên Màn hình | Tên Route | Người phụ trách | Nhánh Git | Dữ liệu đầu vào (Input) | Hành động người dùng | Màn hình đích (Output Target) |
|---|---|---|---|---|---|---|
| **Đăng nhập** | `/login` | **Nguyên Anh** | `feature/nguyen-anh-data-auth-lessons` | Không | Bấm "Bắt đầu học" hoặc chọn tài khoản demo | `/dashboard` (Clear stack) |
| **Tổng quan** | `/dashboard` | **Hoài** | `feature/hoai-dashboard-streak-settings` | `UserProfile`, `DailyProgress` | 1. Bấm "Luyện ngay"<br>2. Bấm "Danh sách bài"<br>3. Bấm "Lịch sử"<br>4. Bấm "Cài đặt" | 1. `/practice` (`lessonId` ưu tiên)<br>2. `/lessons`<br>3. `/history`<br>4. `/settings` |
| **Danh sách bài**| `/lessons` | **Nguyên Anh** | `feature/nguyen-anh-data-auth-lessons` | Bộ lọc cấp độ (Tùy chọn) | Chọn một thẻ bài học cụ thể | `/practice` (truyền `Lesson` hoặc `lessonId`) |
| **Luyện tập** | `/practice` | **Cẩm Ly** | `feature/cam-ly-practice-audio-ai` | `Lesson` object hoặc `lessonId: String` | 1. Bấm nghe mẫu (TTS)<br>2. Bấm giữ/chạm thu âm<br>3. Bấm "Chấm điểm AI" | `/result` (truyền `PracticeResult`) |
| **Kết quả** | `/result` | **Thái** | `feature/thai-result-feedback-testing` | `PracticeResult` object | 1. Chạm vào từ để xem lỗi âm vị<br>2. Bấm "Luyện lại"<br>3. Bấm "Về trang chủ" | 1. Mở BottomSheet phân tích âm vị<br>2. `/practice` (`lessonId`)<br>3. `/dashboard` (Pop to root) |
| **Lịch sử** | `/history` | **Nguyên Anh** | `feature/nguyen-anh-data-auth-lessons` | `userId: String` | Bấm vào 1 mục trong danh sách lịch sử | `/result` (mở lại kết quả cũ đã lưu) |
| **Cài đặt** | `/settings` | **Hoài** | `feature/hoai-dashboard-streak-settings` | `UserProfile` | 1. Chọn số phút mục tiêu (3-15p)<br>2. Đổi giờ nhắc học (TimePicker)<br>3. Bật/tắt Mock Mode | Lưu cấu hình, quay lại `/dashboard` |

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
