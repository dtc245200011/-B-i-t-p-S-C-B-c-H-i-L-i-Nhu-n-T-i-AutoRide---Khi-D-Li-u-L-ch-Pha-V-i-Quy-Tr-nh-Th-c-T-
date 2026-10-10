# AI Prompt Log

## Prompt 1
"Có nên dùng DECIMAL hay FLOAT cho các cột tiền trong MySQL? Tại sao?"
### Tóm tắt phản hồi AI
Dùng DECIMAL để tránh lỗi làm tròn và sai số khi tính toán tài chính; DECIMAL lưu chính xác số thập phân, phù hợp cho tiền tệ.

## Prompt 2
"Làm sao để biểu diễn trạng thái vòng đời hợp đồng (BOOKED, ACTIVE, COMPLETED, CANCELLED) trong MySQL?"
### Tóm tắt phản hồi AI
Dùng ENUM để khóa tập giá trị hợp lệ; hoặc dùng bảng trạng thái riêng nếu cần mở rộng lịch sử trạng thái. ENUM đơn giản và hiệu quả cho tập giá trị cố định.

## Prompt 3
"Database-level mechanism to prevent inserting an inspection for a rental that is still BOOKED?"
### Tóm tắt phản hồi AI
Sử dụng trigger BEFORE INSERT trên bảng Inspections để kiểm tra `Rentals.status` và SIGNAL lỗi nếu trạng thái là BOOKED; hoặc dùng CHECK + FK + ứng dụng kiểm tra, nhưng trigger đảm bảo ở tầng DB.

## Prompt 4
"Refund amount should be stored or computed on the fly?"
### Tóm tắt phản hồi AI
Ưu tiên tính toán tự động (GENERATED STORED column hoặc trigger) để tránh bất đồng bộ; lưu cột GENERATED giúp truy vấn nhanh và đảm bảo nhất quán khi các thành phần phí thay đổi.
