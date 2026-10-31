# Hợp Đồng Giao Diện & Dịch Vụ (API & Interface Contract)

> **Dự án:** Ứng dụng Học Tiếng Anh Phân Tích Phát Âm AI (TH3)  
> **Phiên bản:** 1.0.0-PROPOSAL  
> **Người biên soạn:** Nhóm trưởng (Team Lead)

---

## 1. Mục Đích & Nguyên Tắc Lập Trình Theo Hợp Đồng (Contract-First)

Tài liệu này định nghĩa chính xác các phương thức trừu tượng (Abstract Interfaces trong Dart) và quy cách giao tiếp mạng (REST API).
- **Phát triển độc lập:** Từng thành viên chỉ cần gọi các phương thức qua Interface chung. Không cần quan tâm bên trong người khác viết SQL gì hay gọi thư viện AI nào.
- **Hoán đổi Mock & Real:** Mọi Interface đều có 2 bản triển khai:
  1. `Mock*Service`: Trả về dữ liệu mẫu tức thì từ `assets/mocks/` để TV1, TV2, TV4 phát triển và test giao diện ngay lập tức.
  2. `Real*Service`: Kết nối cơ sở dữ liệu thật và các API AI (Gemini / Whisper / Azure Speech) do TV1 và TV3 hoàn thiện.

---

## 2. Chi Tiết Các Dart Service Interfaces

### 2.1. `LessonRepository` (TV1 cung cấp - Cả nhóm sử dụng)
```dart
abstract class LessonRepository {
  /// Lấy toàn bộ danh sách bài học
  Future<List<Lesson>> getLessons();

  /// Lấy chi tiết một bài học theo id
  Future<Lesson?> getLessonById(String id);

  /// Lọc bài học theo cấp độ (Beginner, Intermediate, Advanced)
  Future<List<Lesson>> getLessonsByLevel(String level);
}
```

### 2.2. `AudioRecordingService` (TV3 cung cấp - Module Luyện tập sử dụng)
```dart
abstract class AudioRecordingService {
  /// Khởi động thu âm và lưu vào tệp tạm thời
  Future<void> startRecording();

  /// Dừng thu âm, trả về đường dẫn tệp âm thanh (.wav/.m4a) và thời gian thu thực tế (giây)
  Future<AudioRecordResult> stopRecording();

  /// Hủy bỏ bản thu đang thực hiện (không lưu)
  Future<void> cancelRecording();

  /// Trạng thái đang thu âm hay không
  bool get isRecording;

  /// Lắng nghe sóng âm thực tế để vẽ UI trực quan (Amplitude stream)
  Stream<double> get amplitudeStream;
}

class AudioRecordResult {
  final String filePath;
  final int durationSeconds;
  AudioRecordResult({required this.filePath, required this.durationSeconds});
}
```

### 2.3. `SpeechAiService` (TV3 cung cấp - Module Luyện tập sử dụng)
```dart
abstract class SpeechAiService {
  /// Gửi tệp âm thanh đến mô hình AI để nhận diện giọng nói và so sánh âm vị với câu mẫu
  /// 
  /// Đầu vào:
  /// - [audioFilePath]: Đường dẫn tệp ghi âm của người dùng
  /// - [lessonId]: Mã bài học
  /// - [targetText]: Câu mẫu tiếng Anh cần phát âm
  /// - [expectedIpa]: Phiên âm IPA chuẩn của câu mẫu
  /// - [activeDurationSeconds]: Thời gian thu âm thực tế (không tính thời gian chờ)
  /// 
  /// Đầu ra:
  /// - Đối tượng [PracticeResult] hoàn chỉnh với điểm số và chi tiết âm vị
  /// 
  /// Ném ngoại lệ (Exceptions):
  /// - [AudioEmptyException]: Tệp âm thanh rỗng hoặc không tồn tại
  /// - [SpeechNotDetectedException]: Không có tiếng nói người trong bản ghi
  /// - [AiServiceException]: Lỗi kết nối hoặc AI quá tải
  Future<PracticeResult> evaluatePronunciation({
    required String audioFilePath,
    required String lessonId,
    required String targetText,
    required String expectedIpa,
    required int activeDurationSeconds,
  });
}
```

### 2.4. `PracticeRepository` (TV1 cung cấp - TV3 ghi kết quả, TV1 & TV4 đọc kết quả)
```dart
abstract class PracticeRepository {
  /// Lưu kết quả một lượt luyện tập vào cơ sở dữ liệu (Single Source of Truth)
  /// Phải bảo đảm tính Idempotent (không lưu trùng khi gọi lại với cùng sessionId)
  Future<void> savePracticeResult(PracticeResult result);

  /// Lấy chi tiết một lượt luyện theo sessionId
  Future<PracticeResult?> getSessionResult(String sessionId);

  /// Lấy toàn bộ lịch sử luyện tập của người dùng, sắp xếp mới nhất lên đầu
  Future<List<PracticeResult>> getHistory(String userId);
}
```

### 2.5. `StreakProgressRepository` (TV1 cung cấp - TV2 sử dụng)
```dart
abstract class StreakProgressRepository {
  /// Lấy tiến độ học tập của ngày hôm nay theo múi giờ địa phương
  Future<DailyProgress> getTodayProgress(String userId);

  /// Lấy lịch sử tiến độ 7 ngày gần nhất (để vẽ biểu đồ tuần)
  Future<List<DailyProgress>> getWeeklyProgress(String userId);

  /// Cập nhật mục tiêu ngày (phút)
  Future<void> updateDailyGoal(String userId, int minutes);

  /// Tính toán và đồng bộ lại số ngày Streak liên tục
  Future<int> recalculateStreak(String userId);
}
```

### 2.6. `ReminderNotificationService` (TV2 cung cấp - Settings sử dụng)
```dart
abstract class ReminderNotificationService {
  /// Đặt lịch thông báo đẩy nhắc nhở luyện tập hàng ngày (VD: "20:00")
  Future<void> scheduleDailyReminder({required String timeString});

  /// Hủy bỏ thông báo nhắc nhở
  Future<void> cancelDailyReminder();
}
```

---

## 3. Đặc Tả REST API (Dành cho Backend hoặc Cloud Functions)

Nếu nhóm cấu hình backend tập trung (ví dụ Node.js/Python FastAPI hoặc Firebase/Google Cloud Run), các endpoint tuân thủ như sau:

### 3.1. `POST /api/v1/pronunciation/evaluate`
- **Mục đích:** Gửi âm thanh để phân tích âm vị AI.
- **Content-Type:** `multipart/form-data`
- **Request Parameters:**
  - `audioFile`: Tệp âm thanh nhị phân (`audio/wav` hoặc `audio/m4a`).
  - `lessonId`: `String` (VD: `"les_001"`).
  - `targetText`: `String` (VD: `"I think this is the right path."`).
  - `expectedIpa`: `String` (VD: `"/aɪ θɪŋk ðɪs ɪz ðə raɪt pæθ/"`).
  - `activeDurationSeconds`: `int` (VD: `14`).
- **Response 200 (OK):** Trả về đối tượng `PracticeResult` theo đúng mô hình tại [docs/data-contract.md](file:///d:/adrstu/th3/docs/data-contract.md).
- **Response Error (4xx, 5xx):** Trả về mã lỗi chuẩn tại Mục 4 bên dưới.

### 3.2. `GET /api/v1/lessons`
- **Mục đích:** Lấy danh sách bài học.
- **Response 200 (OK):** Mảng các đối tượng `Lesson`.

---

## 4. Bảng Mã Lỗi Chuẩn & Cơ Chế Xử Lý (Error Protocol)

| Mã lỗi (`errorCode`) | HTTP Status | Nguyên nhân | Hành vi ứng dụng & Gợi ý cho người dùng | Có thể thử lại (`canRetry`) |
|---|---|---|---|---|
| `AUDIO_EMPTY` | 400 | Tệp thu âm không có dữ liệu hoặc ngắn hơn 0.5s | Thông báo: "Thời gian ghi âm quá ngắn. Vui lòng giữ nút thu âm và đọc lại." | Có |
| `SPEECH_NOT_DETECTED` | 422 | Có tệp âm thanh nhưng AI không nhận diện được từ nào | Thông báo: "Không nghe rõ giọng đọc. Bạn hãy đọc to và rõ hơn nhé." | Có |
| `AI_TIMEOUT` | 504 | Mô hình AI xử lý quá 15 giây không phản hồi | Thông báo: "Máy chủ AI phản hồi chậm. Bấm 'Thử lại' để gửi lại." | Có |
| `RATE_LIMIT_EXCEEDED` | 429 | Gửi yêu cầu quá nhiều lần liên tiếp | Thông báo: "Thao tác quá nhanh. Xin vui lòng chờ 30 giây." | Không (Chờ timeout) |
| `NETWORK_UNAVAILABLE` | 0 | Mất kết nối Internet khi gọi AI | Thông báo: "Không có kết nối mạng. Bạn có thể bật Chế độ Mock để trải nghiệm." | Có |
| `INTERNAL_AI_ERROR` | 500 | Lỗi thuật toán phân tích âm vị nội bộ | Thông báo: "Có lỗi khi phân tích. Không tính lượt này vào lịch sử." | Có |
