-- autoride_db.sql
DROP DATABASE IF EXISTS autoride_db;
CREATE DATABASE autoride_db;
USE autoride_db;

-- Bảng Cars
CREATE TABLE Cars (
    car_id INT AUTO_INCREMENT PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    license_plate VARCHAR(20) UNIQUE NOT NULL
);

-- Bảng Rentals (ban đầu) - nếu đã tồn tại, dùng ALTER TABLE để nâng cấp
CREATE TABLE IF NOT EXISTS Rentals (
    rental_id INT AUTO_INCREMENT PRIMARY KEY,
    car_id INT,
    customer_name VARCHAR(100) NOT NULL,
    rent_date DATETIME NOT NULL,
    return_date DATETIME,
    status ENUM('BOOKED','ACTIVE','COMPLETED','CANCELLED') DEFAULT 'BOOKED',
    security_deposit DECIMAL(12,2) DEFAULT 0.00,
    late_fee DECIMAL(12,2) DEFAULT 0.00,
    damage_fee DECIMAL(12,2) DEFAULT 0.00,
    refund_amount DECIMAL(12,2) GENERATED ALWAYS AS (security_deposit - late_fee - damage_fee) STORED,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (car_id) REFERENCES Cars(car_id)
);

-- Nếu bạn đang nâng cấp từ legacy schema có cột status VARCHAR, dùng ALTER TABLE thay vì CREATE
-- Ví dụ ALTER TABLE (chạy khi bảng Rentals đã tồn tại với cấu trúc cũ):
/*
ALTER TABLE Rentals
MODIFY COLUMN status ENUM('BOOKED','ACTIVE','COMPLETED','CANCELLED') NOT NULL DEFAULT 'BOOKED',
ADD COLUMN security_deposit DECIMAL(12,2) DEFAULT 0.00,
ADD COLUMN late_fee DECIMAL(12,2) DEFAULT 0.00,
ADD COLUMN damage_fee DECIMAL(12,2) DEFAULT 0.00,
ADD COLUMN refund_amount DECIMAL(12,2) GENERATED ALWAYS AS (security_deposit - late_fee - damage_fee) STORED;
*/

-- Bảng Inspections
CREATE TABLE Inspections (
    inspection_id INT AUTO_INCREMENT PRIMARY KEY,
    rental_id INT NOT NULL,
    inspection_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    inspector_name VARCHAR(100),
    damage_description TEXT,
    damage_cost DECIMAL(12,2) DEFAULT 0.00,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (rental_id) REFERENCES Rentals(rental_id) ON DELETE RESTRICT
);

-- Trigger: ngăn chặn insert Inspections cho hợp đồng đang ở trạng thái BOOKED
DELIMITER $$
CREATE TRIGGER trg_inspection_before_insert
BEFORE INSERT ON Inspections
FOR EACH ROW
BEGIN
    DECLARE r_status ENUM('BOOKED','ACTIVE','COMPLETED','CANCELLED');
    SELECT status INTO r_status FROM Rentals WHERE rental_id = NEW.rental_id;
    IF r_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rental not found';
    ELSEIF r_status = 'BOOKED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot add inspection for a BOOKED rental';
    END IF;
END$$
DELIMITER ;

-- Trigger: khi cập nhật damage_fee hoặc late_fee trên Rentals, cập nhật refund_amount tự động (refund_amount là cột GENERATED, nên DB tự tính)
-- Nếu DB không hỗ trợ GENERATED STORED, có thể dùng trigger AFTER UPDATE để cập nhật refund_amount.

-- Dữ liệu mẫu và kịch bản mô phỏng

-- Thêm xe
INSERT INTO Cars (model_name, license_plate) VALUES ('Toyota Vios', '30A-12345');

-- Kịch bản: khách thuê, đóng cọc 10.000.000, trạng thái ACTIVE
INSERT INTO Rentals (car_id, customer_name, rent_date, status, security_deposit)
VALUES (1, 'Nguyen Van A', '2026-10-01 09:00:00', 'ACTIVE', 10000000.00);

-- Giả sử khách trả xe; nhân viên kiểm tra và ghi Inspections (vì status đang ACTIVE, trigger cho phép)
INSERT INTO Inspections (rental_id, inspection_date, inspector_name, damage_description, damage_cost)
VALUES (1, '2026-10-05 11:30:00', 'Le Van B', 'Vỡ đèn pha trái', 2000000.00);

-- Cập nhật Rentals: trả xe, ghi phí trễ và phí hư hỏng, chuyển trạng thái COMPLETED
UPDATE Rentals
SET return_date = '2026-10-05 11:30:00',
    late_fee = 0.00,
    damage_fee = 2000000.00,
    status = 'COMPLETED'
WHERE rental_id = 1;

-- Truy vấn tính tiền hoàn lại cho khách
SELECT rental_id, customer_name, security_deposit, late_fee, damage_fee, (security_deposit - late_fee - damage_fee) AS refund_amount
FROM Rentals
WHERE rental_id = 1;

-- Kịch bản kiểm tra: khách trả trễ 2 ngày và gây hư hỏng
-- Thêm một rental khác
INSERT INTO Rentals (car_id, customer_name, rent_date, status, security_deposit)
VALUES (1, 'Tran Thi C', '2026-10-01 09:00:00', 'ACTIVE', 8000000.00);

-- Cập nhật trả trễ và hư hỏng
UPDATE Rentals
SET return_date = '2026-10-04 12:00:00',
    late_fee = 500000.00,
    damage_fee = 1500000.00,
    status = 'COMPLETED'
WHERE rental_id = 2;

-- Xem kết quả
SELECT rental_id, customer_name, security_deposit, late_fee, damage_fee, (security_deposit - late_fee - damage_fee) AS refund_amount
FROM Rentals
WHERE rental_id IN (1,2);
