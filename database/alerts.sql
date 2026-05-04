USE sis_db;

CREATE TABLE IF NOT EXISTS Alerts (
    Alert_ID INT PRIMARY KEY AUTO_INCREMENT,
    Enroll_ID INT,
    Message TEXT,
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Enroll_ID) REFERENCES Enrollment(Enroll_ID)
);

DELIMITER //

DROP TRIGGER IF EXISTS low_attendance_alert //
CREATE TRIGGER low_attendance_alert
AFTER INSERT ON Attendance
FOR EACH ROW
BEGIN
    DECLARE v_perc DECIMAL(5,2);
    SET v_perc = Calculate_Attendance_Percentage(NEW.Enroll_ID);
    IF v_perc < 75 THEN
        INSERT INTO Alerts (Enroll_ID, Message)
        VALUES (NEW.Enroll_ID, CONCAT('Low Attendance Alert: ', v_perc, '%'));
    END IF;
END //

DELIMITER ;
