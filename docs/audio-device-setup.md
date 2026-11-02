# Chạy thử thu âm và giọng đọc mẫu

- Nút **Nghe giọng đọc mẫu** dùng giọng tiếng Anh do hệ điều hành cung cấp (TTS), không phải file thu sẵn của người bản xứ. Nếu nút báo không có giọng English, hãy tải/cài giọng English trong cài đặt Text-to-Speech của thiết bị.
- Lần đầu bấm micro, cấp quyền sử dụng micro cho ứng dụng. Nếu đã từ chối trước đó, bật lại quyền Microphone trong cài đặt ứng dụng rồi mở lại bài luyện tập.
- Sau khi dừng thu, ứng dụng lưu bản WAV mono 16 kHz trong thư mục tạm của ứng dụng. Bản ghi bị xóa theo chính sách dọn dẹp tệp tạm của hệ điều hành.
- Chế độ mặc định hiện thu âm thật nhưng chấm điểm bằng fixture mock. Điểm kết quả vì vậy chưa được tính từ giọng bạn; cần tích hợp `SpeechAiService` với API để có kết quả thực.
- Trên Android, quyền runtime được hỏi khi bắt đầu ghi. Trên Windows, bật quyền Microphone cho ứng dụng desktop trong Windows Privacy settings nếu hệ thống chặn micro.
- Trên Chrome/Web, chạy ứng dụng ở `localhost` hoặc HTTPS rồi chọn **Allow** khi trình duyệt hỏi quyền Microphone. Trình duyệt cung cấp voice TTS và tệp ghi âm tạm dạng blob; dữ liệu này không được lưu bền vững sau phiên web.
