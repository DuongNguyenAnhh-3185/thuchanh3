# Báo cáo kiểm thử đa giọng đọc và phản hồi phát âm

**Phụ trách:** Thái  
**Nhánh:** `feature/thai-result-feedback-testing`  
**Phạm vi:** Màn hình kết quả `/result`, hiển thị IPA và phản hồi phát âm.

**Ngày kiểm tra:** 01-11-2026. Widget tests chạy thành công cho cả bốn fixture. Trong lần kiểm tra tương tác, BottomSheet so sánh âm vị bị tràn chiều cao; nội dung đã được chuyển sang vùng cuộn và kiểm tra lại.

**Xác minh lại:** 02-11-2026, chạy `flutter test test/features/result/result_screen_test.dart` trên nhánh này — 4/4 widget tests đạt. Lần chạy này xác nhận giao diện với dữ liệu mock; không bao gồm thu âm hay chấm điểm từ người nói thật.

## Mục tiêu và giới hạn

Kiểm tra màn hình kết quả với dữ liệu điểm cao, điểm thấp có lỗi âm vị, thiếu chỉ số phụ và không nhận dạng được từ. Các ca này kiểm tra cách giao diện trình bày kết quả AI; chúng không thay thế việc đo độ chính xác nhận dạng trên bản ghi giọng nói thật.

## Ma trận kiểm thử người nói

Mỗi người đọc cùng một bộ câu chuẩn, thu trong điều kiện yên tĩnh và dùng cùng cấu hình API/model. Lưu mã người tham gia, thiết bị, vùng giọng tự khai báo, mã bài, mã phiên và phản hồi AI; chỉ lưu âm thanh khi đã có đồng thuận. Không đưa thông tin định danh cá nhân vào báo cáo.

| Mã ca | Hồ sơ giọng đọc | Mục tiêu | Kết quả cần xác nhận |
|---|---|---|---|
| V01 | Giọng nam, người mới học | Phát hiện lỗi âm /θ/, /ð/ và hướng dẫn dễ hiểu | Âm thay thế được đánh dấu; mẹo luyện tập phù hợp |
| V02 | Giọng nữ, người mới học | Kiểm tra cùng câu mẫu với giọng và cao độ khác | Có điểm và phản hồi; không nhầm khác biệt cao độ với lỗi âm vị |
| V03 | Người học phát âm tốt | Kiểm tra mức điểm cao và tránh đánh dấu sai | Âm đúng được tô xanh; điểm phụ hiển thị đúng |
| V04 | Người nói giọng vùng miền | Kiểm tra độ ổn định với biến thể vùng miền | Ghi lại lỗi thật và lỗi nhận diện nhầm để rà soát công bằng |
| V05 | Bản ghi không có lời nói/không rõ | Kiểm tra lỗi đầu vào | Hiển thị trạng thái trống và lời nhắc thu lại, không gây crash |

## Kết quả kiểm tra mock giao diện

| Fixture | Nội dung | Kết quả mong đợi | Trạng thái |
|---|---|---|---|
| `practice_result_high.json` | Điểm tổng cao, đủ chỉ số và âm vị | Điểm/metric hiển thị; chạm từ mở so sánh IPA | Đạt |
| `practice_result_low.json` | Điểm thấp, /θ/ bị thay bằng /s/ hoặc /t/ | Lỗi âm vị, IPA thực tế và gợi ý cải thiện hiển thị | Đạt |
| `practice_result_missing_metrics.json` | Điểm phụ là `null`, không có chi tiết âm vị | Ẩn thẻ chỉ số phụ; kết quả từ vẫn hiển thị | Đạt |
| `practice_result_empty.json` | Điểm/từ rỗng, không nhận dạng được lời nói | Hiển thị trạng thái chưa có điểm và hướng dẫn thử lại | Đạt |

Lệnh xác nhận: `flutter test test/features/result/result_screen_test.dart` — 4 test pass (xác minh lại ngày 02-11-2026).

## Giới hạn và kiểm thử giọng thật còn thiếu

Các ca V01–V05 là kế hoạch chạy với người tham gia và bản ghi thực tế. Chưa có bản ghi đa người nói hoặc kết quả API thực trong bộ fixture hiện tại, vì vậy không kết luận độ chính xác AI theo giới tính, trình độ hay vùng giọng từ mock. Khi chạy, bổ sung số phiên hợp lệ, tỷ lệ nhận dạng đúng từng âm mục tiêu, tỷ lệ lỗi âm vị bị bỏ sót, tỷ lệ cảnh báo nhầm, số lỗi API và ghi chú thiết bị/điều kiện thu.

Tiêu chí đề xuất để nhóm nghiệm thu: mọi ca đều có thể mở màn hình kết quả; lỗi microphone/API có hướng dẫn phục hồi; không có lỗi render; các lần nhận dạng nhầm được ghi riêng để đánh giá theo âm vị và nhóm giọng trước khi kết luận chất lượng mô hình.
