# Hợp Đồng Mô Hình Dữ Liệu Dùng Chung (Data Contract & Models)

> **Dự án:** Ứng dụng Học Tiếng Anh Phân Tích Phát Âm AI (TH3)  
> **Phiên bản:** 1.0.0-PROPOSAL  
> **Người biên soạn:** Nhóm trưởng (phối hợp cùng TV1 & TV3)

---

## 1. Nguyên Tắc Thiết Kế Dữ Liệu Dùng Chung

1. **Tuyệt đối không tự suy diễn kiểu dữ liệu:** Mọi thành viên phải tuân theo đúng tên trường (camelCase), kiểu dữ liệu và tính cho phép rỗng (`nullable`) quy định tại tài liệu này.
2. **Quy tắc giá trị thiếu (`null`):**
   - Điểm số không đo được hoặc dịch vụ AI không trả về phải để `null`. **Tuyệt đối không tự ý gán `0`** vì 0 điểm mang ý nghĩa "phát âm hoàn toàn sai", khác với "chưa có dữ liệu".
   - Mảng rỗng (`[]`) được dùng khi không có phần tử, không dùng `null` cho mảng danh sách.
3. **Chuẩn biểu diễn thời gian:**
   - Khi lưu trữ vào DB hoặc truyền qua JSON/API: Bắt buộc dùng định dạng **UTC ISO 8601** với đuôi `Z` (VD: `2026-10-31T09:15:30.000Z`).
   - Khi hiển thị trên màn hình: Chuyển đổi sang múi giờ địa phương của người dùng (VD: `16:15 31/10/2026`).
4. **Tránh lưu trùng (Idempotency):**
   - Mỗi lượt luyện có `sessionId` duy nhất dạng UUID v4 hoặc tiền tố timestamp (VD: `sess_1730366130_a1b2`).
   - Bảng cơ sở dữ liệu phải đặt khóa chính `PRIMARY KEY(sessionId)` để nếu người dùng nhấn gửi nhiều lần, thao tác chỉ ghi đè hoặc bỏ qua chứ không tạo ra 2 bản ghi lịch sử.

---

## 2. Chi Tiết Các Thực Thể Dữ Liệu (Entities Specification)

### 2.1. Thực thể `UserProfile` (Thông tin & Thiết lập người dùng)

| Tên trường | Kiểu dữ liệu | Bắt buộc? | Mô tả ý nghĩa | Ví dụ giá trị |
|---|---|---|---|---|
| `id` | `String` | Có | Mã định danh người dùng | `"usr_dev_01"` |
| `name` | `String` | Có | Họ và tên hiển thị | `"Nguyễn Văn A"` |
| `email` | `String` | Có | Email tài khoản | `"nguyenvana@example.com"` |
| `avatarUrl` | `String?` | Không | Link ảnh đại diện (hoặc icon mặc định) | `"https://..."` |
| `streakCount` | `int` | Có | Số ngày học liên tục tính đến hiện tại | `5` |
| `lastPracticeDate` | `String?` | Không | Ngày luyện tập gần nhất đạt mục tiêu (YYYY-MM-DD) | `"2026-10-31"` |
| `dailyGoalMinutes` | `int` | Có | Mục tiêu thời gian học mỗi ngày (phút), mặc định `5` | `5` |
| `reminderTime` | `String` | Có | Giờ gửi thông báo nhắc học (HH:mm) | `"20:00"` |
| `isReminderEnabled` | `bool` | Có | Trạng thái bật/tắt nhắc học | `true` |
| `level` | `String` | Có | Cấp độ học viên (`Beginner`, `Intermediate`, `Advanced`) | `"Intermediate"` |
| `totalSessions` | `int` | Có | Tổng số lượt luyện đã hoàn thành | `28` |
| `totalActiveMinutes` | `int` | Có | Tổng số phút luyện tập thực tế tích lũy | `142` |

---

### 2.2. Thực thể `Lesson` (Bài học phát âm)

| Tên trường | Kiểu dữ liệu | Bắt buộc? | Mô tả ý nghĩa | Ví dụ giá trị |
|---|---|---|---|---|
| `id` | `String` | Có | Mã bài học | `"les_001"` |
| `title` | `String` | Có | Tiêu đề bài học và âm trọng tâm | `"Voiceless TH /θ/ - Think & Thought"` |
| `level` | `String` | Có | Cấp độ (`Beginner`, `Intermediate`, `Advanced`) | `"Beginner"` |
| `category` | `String` | Có | Nhóm ngữ âm (`Consonants`, `Vowels`, `Sibilants`...) | `"Consonants"` |
| `text` | `String` | Có | Câu mẫu tiếng Anh cần luyện đọc | `"I think this is the right path."` |
| `ipa` | `String` | Có | Phiên âm quốc tế chuẩn của câu mẫu | `"/aɪ θɪŋk ðɪs ɪz ðə raɪt pæθ/"` |
| `translationVi` | `String` | Có | Bản dịch nghĩa tiếng Việt | `"Tôi nghĩ đây là con đường đúng đắn."` |
| `audioSampleUrl`| `String` | Có | URL hoặc asset path tệp âm thanh bản xứ | `"assets/audio/les_001.mp3"` |
| `targetPhonemes`| `List<String>` | Có | Danh sách các âm vị trọng tâm cần chú ý | `["θ", "ð", "p"]` |

---

### 2.3. Thực thể `PracticeResult` (Kết quả phân tích lượt luyện)

| Tên trường | Kiểu dữ liệu | Bắt buộc? | Mô tả ý nghĩa | Ví dụ giá trị |
|---|---|---|---|---|
| `sessionId` | `String` | Có | Mã duy nhất của lượt luyện | `"sess_high_92"` |
| `lessonId` | `String` | Có | Mã bài học tương ứng | `"les_001"` |
| `userId` | `String` | Có | Mã người dùng thực hiện | `"usr_dev_01"` |
| `completedAt` | `String` | Có | Thời điểm hoàn thành chuẩn ISO 8601 UTC | `"2026-10-31T09:15:30.000Z"` |
| `activeDurationSeconds`| `int` | Có | Thời gian thu âm thực tế (giây), không tính chờ AI | `14` |
| `status` | `String` | Có | Trạng thái: `"processing"`, `"completed"`, `"failed"` | `"completed"` |
| `scores` | `ScoreBreakdown` | Có | Đối tượng chứa các chỉ số điểm số | `{ "overall": 92.5, ... }` |
| `transcript` | `String` | Có | Văn bản AI nhận dạng được từ giọng nói (STT) | `"I think this is the right path"` |
| `targetText` | `String` | Có | Câu mẫu gốc cần đối chiếu | `"I think this is the right path."` |
| `words` | `List<WordEvaluation>` | Có | Danh sách đánh giá chi tiết từng từ | `[...]` (Rỗng nếu không nhận dạng được) |
| `feedbackTips` | `List<String>` | Có | Lời khuyên cụ thể để sửa lỗi khẩu hình/âm vị | `["Lỗi âm /θ/ trong think..."]` |

---

### 2.4. Thực thể `ScoreBreakdown` (Bảng điểm chi tiết)

| Tên trường | Kiểu dữ liệu | Bắt buộc? | Mô tả ý nghĩa | Xử lý khi thiếu |
|---|---|---|---|---|
| `overall` | `double?` | Không | Điểm tổng thể thang 0 - 100 | Nếu null: Hiện "Chưa chấm" |
| `accuracy` | `double?` | Không | Điểm độ chính xác phát âm từng âm vị | Nếu null: Ẩn thanh Accuracy |
| `fluency` | `double?` | Không | Điểm độ lưu loát, ngắt nghỉ, nhịp điệu | Nếu null: Ẩn thanh Fluency |
| `completeness`| `double?` | Không | Điểm tỷ lệ đọc đủ số lượng từ | Nếu null: Ẩn thanh Completeness |

---

### 2.5. Thực thể `WordEvaluation` (Đánh giá từng từ)

| Tên trường | Kiểu dữ liệu | Bắt buộc? | Mô tả ý nghĩa | Giá trị hợp lệ |
|---|---|---|---|---|
| `word` | `String` | Có | Từ tiếng Anh | `"think"` |
| `ipa` | `String` | Có | Phiên âm chuẩn của từ | `"/θɪŋk/"` |
| `score` | `double` | Có | Điểm số của riêng từ này (0 - 100) | `42.0` |
| `status` | `String` | Có | Trạng thái màu sắc để UI render | `"correct"` (Xanh $\ge 80$), `"warning"` (Vàng $60-79$), `"incorrect"` (Đỏ $< 60$) |
| `phonemes` | `List<PhonemeEvaluation>` | Có | Danh sách phân tích từng âm vị của từ | `[...]` |

---

### 2.6. Thực thể `PhonemeEvaluation` (Phân tích chi tiết âm vị)

| Tên trường | Kiểu dữ liệu | Bắt buộc? | Mô tả ý nghĩa | Ví dụ giá trị |
|---|---|---|---|---|
| `phoneme` | `String` | Có | Ký hiệu âm vị gốc | `"θ"` |
| `ipaExpected` | `String` | Có | Ký hiệu âm vị chuẩn mong đợi | `"θ"` |
| `ipaActual` | `String` | Có | Ký hiệu âm vị mà người dùng thực tế phát âm | `"s"` (Phát âm sai thành s) |
| `score` | `double` | Có | Điểm chính xác của âm vị (0 - 100) | `25.0` |
| `isCorrect` | `bool` | Có | Đúng hay sai (`true` nếu score $\ge 70$) | `false` |

---

### 2.7. Thực thể `DailyProgress` (Tiến độ học tập ngày)

| Tên trường | Kiểu dữ liệu | Bắt buộc? | Mô tả ý nghĩa | Ví dụ giá trị |
|---|---|---|---|---|
| `date` | `String` | Có | Ngày địa phương định dạng `YYYY-MM-DD` | `"2026-10-31"` |
| `activeSeconds` | `int` | Có | Tổng số giây đã luyện trong ngày | `320` |
| `targetSeconds` | `int` | Có | Mục tiêu ngày tính theo giây (`dailyGoalMinutes * 60`) | `300` |
| `isGoalReached` | `bool` | Có | Đã đạt mục tiêu hay chưa (`activeSeconds >= targetSeconds`) | `true` |
| `practiceCount` | `int` | Có | Số bài đã luyện trong ngày | `3` |

---

## 3. Lược Đồ Cơ Sở Dữ Liệu SQLite (Dành cho TV1 cài đặt Local DB)

```sql
-- Bảng người dùng
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    avatar_url TEXT,
    streak_count INTEGER NOT NULL DEFAULT 0,
    last_practice_date TEXT,
    daily_goal_minutes INTEGER NOT NULL DEFAULT 5,
    reminder_time TEXT NOT NULL DEFAULT '20:00',
    is_reminder_enabled INTEGER NOT NULL DEFAULT 1,
    level TEXT NOT NULL DEFAULT 'Beginner',
    total_sessions INTEGER NOT NULL DEFAULT 0,
    total_active_minutes INTEGER NOT NULL DEFAULT 0
);

-- Bảng bài học
CREATE TABLE IF NOT EXISTS lessons (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    level TEXT NOT NULL,
    category TEXT NOT NULL,
    text TEXT NOT NULL,
    ipa TEXT NOT NULL,
    translation_vi TEXT NOT NULL,
    audio_sample_url TEXT NOT NULL,
    target_phonemes TEXT NOT NULL -- Lưu dạng JSON array chuỗi
);

-- Bảng lịch sử và kết quả luyện tập
CREATE TABLE IF NOT EXISTS practice_sessions (
    session_id TEXT PRIMARY KEY,
    lesson_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    completed_at TEXT NOT NULL, -- UTC ISO 8601
    active_duration_seconds INTEGER NOT NULL,
    status TEXT NOT NULL,
    overall_score REAL,
    accuracy_score REAL,
    fluency_score REAL,
    completeness_score REAL,
    transcript TEXT,
    target_text TEXT NOT NULL,
    words_json TEXT NOT NULL,       -- Chuỗi JSON chi tiết words & phonemes
    feedback_tips_json TEXT NOT NULL, -- Chuỗi JSON mảng feedback tips
    FOREIGN KEY(lesson_id) REFERENCES lessons(id),
    FOREIGN KEY(user_id) REFERENCES users(id)
);

-- Bảng tiến độ theo ngày (phục vụ tính Streak & Biểu đồ)
CREATE TABLE IF NOT EXISTS daily_progress (
    user_id TEXT NOT NULL,
    date TEXT NOT NULL, -- YYYY-MM-DD
    active_seconds INTEGER NOT NULL DEFAULT 0,
    target_seconds INTEGER NOT NULL DEFAULT 300,
    is_goal_reached INTEGER NOT NULL DEFAULT 0,
    practice_count INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY(user_id, date),
    FOREIGN KEY(user_id) REFERENCES users(id)
);
```
