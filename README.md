# Ứng Dụng Học Tiếng Anh Phân Tích Phát Âm AI (AI Pronunciation Coach)

> **Môn học:** Lập trình Thiết bị Di động (Mobile App Development)  
> **Bài tập lớn / Thực hành:** TH3 — Xây dựng ứng dụng học tiếng Anh với tính năng phân tích phát âm AI  
> **Nền tảng:** Flutter (Android & Cross-platform)  
> **Kiến trúc:** Clean Architecture, Contract-First, Mock-Driven Development

---

## 1. Giới Thiệu Dự Án

Ứng dụng giúp người học tiếng Anh rèn luyện kỹ năng phát âm chuẩn bản xứ (`en-US`) và xây dựng thói quen học tập kỷ luật thông qua hai trụ cột:
1. **Theo dõi tiến độ & Kỷ luật học tập:** Đếm chuỗi ngày học liên tục (**Streak**), đo thời gian luyện tập thực tế, đặt mục tiêu hàng ngày (Daily Goal) và thông báo nhắc nhở tự động.
2. **Trí tuệ Nhân tạo Phân tích Âm vị (AI Phoneme Comparison):** Thu âm giọng đọc của người dùng, phân tích chi tiết tới từng âm vị (Phoneme level) theo chuẩn quốc tế **IPA**, tô màu phát hiện âm sai (ví dụ nhầm lẫn `/θ/` thành `/s/`), chỉ dẫn trực quan khẩu hình răng-môi-lưỡi để sửa lỗi.

---

## 2. Bộ Tài Liệu Kỹ Thuật Chuẩn Bị Trước Khi Code (Bắt Buộc Đọc)

Để đảm bảo 4 thành viên (TV1, TV2, TV3, TV4) có thể **code độc lập, nhận dữ liệu gì, trả ra gì và thế nào là hoàn thành**, nhóm trưởng đã chuẩn bị đầy đủ bộ tài liệu tại thư mục `docs/`:

| Tài liệu | Nội dung chi tiết | Liên kết |
|---|---|---|
| **Yêu cầu & Quy tắc nghiệp vụ** | Phạm vi dự án, quy tắc tính streak, thời gian học thực tế, checklist 7 mục TH3 | [docs/requirements.md](file:///d:/adrstu/th3/docs/requirements.md) |
| **Luồng màn hình & Người phụ trách** | Sơ đồ điều hướng, phân công TV1-TV4, hợp đồng truyền tham số giữa các màn hình | [docs/screens.md](file:///d:/adrstu/th3/docs/screens.md) |
| **Hợp đồng Mô hình Dữ liệu** | Đặc tả Model chuẩn (`UserProfile`, `Lesson`, `PracticeResult`), quy tắc null safety, SQLite schema | [docs/data-contract.md](file:///d:/adrstu/th3/docs/data-contract.md) |
| **Hợp đồng Giao diện & Dịch vụ API** | Interface trừu tượng trong Dart, cấu hình REST API, bảng mã lỗi và cơ chế retry | [docs/api-contract.md](file:///d:/adrstu/th3/docs/api-contract.md) |
| **Phân công & Tiêu chí nghiệm thu** | Ma trận RACI, phiếu giao việc chi tiết cho từng người, tiêu chí nghiệm thu (DoD), Git Flow | [docs/tasks.md](file:///d:/adrstu/th3/docs/tasks.md) |
| **Bộ Dữ liệu Giả Dùng Chung** | Kho JSON mẫu kiểm thử điểm cao, điểm thấp, thiếu chỉ số, rỗng, streak liên tục, lỗi API | [mocks/](file:///d:/adrstu/th3/mocks) |

---

## 3. Cấu Trúc Mã Nguồn Dự Án (Clean Architecture)

```
th3/
├── android/                    # Cấu hình Android native
├── assets/
│   └── mocks/                  # Dữ liệu giả định dạng JSON đóng gói sẵn trong ứng dụng
├── docs/                       # Toàn bộ tài liệu hợp đồng và quy chuẩn nhóm trưởng ban hành
│   ├── api-contract.md
│   ├── data-contract.md
│   ├── requirements.md
│   ├── screens.md
│   └── tasks.md
├── mocks/                      # Bản sao dữ liệu giả dùng tham chiếu nhanh
├── lib/
│   ├── core/                   # Cấu hình dùng chung
│   │   ├── constants/          # Hằng số, màu sắc, font chữ, đường dẫn
│   │   ├── routes/             # Định tuyến màn hình và tham số (Named Routes & Args)
│   │   ├── services/           # Service Locator quản lý phụ thuộc (AppServices)
│   │   └── theme/              # Material 3 Theme (Light / Dark)
│   ├── data/                   # Tầng Dữ liệu (Data Layer)
│   │   ├── models/             # Toàn bộ data models khớp 100% với docs/data-contract.md
│   │   ├── repositories/       # Triển khai Mock / Real Repositories
│   │   └── sources/            # Nạp dữ liệu từ Local Assets / SQLite / Remote API
│   ├── features/               # Tầng Giao diện & Nghiệp vụ (Presentation & Domain)
│   │   ├── auth/               # [TV1] Đăng nhập & quản lý người dùng
│   │   ├── dashboard/          # [TV2] Tổng quan, streak, tiến độ ngày, biểu đồ tuần
│   │   ├── history/            # [TV1] Lịch sử các lần luyện tập
│   │   ├── lessons/            # [TV1] Danh sách bài học & bộ lọc cấp độ
│   │   ├── practice/           # [TV3] Màn hình luyện đọc, thu âm, đếm thời gian, gọi AI
│   │   ├── result/             # [TV4] Màn hình kết quả, phân tích âm vị, tips cải thiện
│   │   └── settings/           # [TV2] Cài đặt mục tiêu, nhắc học, đổi chế độ Mock/Real
│   └── main.dart               # Điểm khởi chạy ứng dụng
├── test/                       # Unit tests & Widget tests
└── pubspec.yaml                # Khai báo thư viện và tài nguyên
```

---

## 4. Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### 4.1. Yêu cầu môi trường
- **Flutter SDK:** >= 3.13.0 (Đã kiểm tra tương thích trên Flutter 3.24+)
- **Dart SDK:** >= 3.1.0
- **Android Studio / VS Code / Antigravity IDE** với Flutter Extension.
- **Thiết bị chạy:** Android Emulator (API 26+) hoặc máy thật, hoặc Windows Desktop.

### 4.2. Khởi chạy ứng dụng (Chế độ Mock chạy ngay lập tức)

> ⭐️ **Điểm đặc biệt:** Bất kỳ thành viên nào clone repository về đều có thể **chạy ngay lập tức mà không cần cấu hình API Key AI hay backend**, ứng dụng tự động nạp dữ liệu từ `assets/mocks/`.

```bash
# 1. Cài đặt các thư viện phụ thuộc
flutter pub get

# 2. Kiểm tra lỗi mã nguồn (phải 0 errors)
flutter analyze

# 3. Chạy toàn bộ unit test kiểm tra logic streak và parse model
flutter test

# 4. Khởi chạy ứng dụng
flutter run
```

---

## 5. Hướng Dẫn Chuyển Đổi Sang Dịch Vụ AI Thật (Real Mode)

Khi TV3 hoàn thiện tích hợp mô hình AI (Gemini / Whisper / Azure Speech Service):
1. Mở ứng dụng $\rightarrow$ Vào mục **Cài đặt (Settings)** $\rightarrow$ Bật công tắc **"Sử dụng AI Phân tích thật"**.
2. Hoặc cấu hình biến môi trường trong tệp `.env` (không commit lên Git):
   ```properties
   AI_SERVICE_PROVIDER=gemini
   AI_API_KEY=your_secret_gemini_api_key_here
   AI_ENDPOINT=https://generativelanguage.googleapis.com
   ```

---

## 6. Phân Công Thành Viên & Liên Hệ

| Thành viên | Vai trò | Trách nhiệm chính |
|---|---|---|
| **Nhóm trưởng** | Team Lead / Architect | Xây dựng khung dự án, ban hành hợp đồng, kiểm soát PR, điều phối |
| **Thành viên 1 (TV1)** | Database & Content Dev | Cơ sở dữ liệu SQLite, Màn hình Đăng nhập, Danh sách bài, Lịch sử |
| **Thành viên 2 (TV2)** | Progress & Motivation Dev | Màn hình Tổng quan, Thuật toán Streak, Thống kê, Nhắc học (Notifications) |
| **Thành viên 3 (TV3)** | Audio & AI Engine Dev | Thu âm giọng nói, Tích hợp AI so sánh âm vị, Lưu kết quả vào DB |
| **Thành viên 4 (TV4)** | Feedback UI & QA Lead | Màn hình Kết quả, Trực quan hóa lỗi âm vị, Kế hoạch kiểm thử đa giọng đọc |
