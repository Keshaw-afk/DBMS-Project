USE sis_db;
DELIMITER //
DROP TRIGGER IF EXISTS student_after_insert //
CREATE TRIGGER student_after_insert
AFTER INSERT ON Student
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Log (Table_Name, Action, New_Data)
    VALUES ('Student', 'INSERT', JSON_OBJECT('id', NEW.Student_ID, 'name', CONCAT(NEW.First_Name, ' ', NEW.Last_Name), 'email', NEW.Email));

    INSERT IGNORE INTO FeePayment (Student_ID, Semester, Amount_Due, Status, Due_Date)
    VALUES (NEW.Student_ID, 1, 50000.00, 'UNPAID', DATE_ADD(CURDATE(), INTERVAL 30 DAY));
END //
DELIMITER ;
