USE sis_db;

DELIMITER //

DROP TRIGGER IF EXISTS student_after_insert //
CREATE TRIGGER student_after_insert
AFTER INSERT ON Student
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Log (Table_Name, Action, New_Data)
    VALUES ('Student', 'INSERT', JSON_OBJECT('id', NEW.Student_ID, 'name', CONCAT(NEW.First_Name, ' ', NEW.Last_Name), 'email', NEW.Email));

    -- Automatically create a fee record for the student's entry semester
    INSERT IGNORE INTO FeePayment (Student_ID, Semester, Amount_Due, Status, Due_Date)
    VALUES (NEW.Student_ID, 1, 50000, 'UNPAID', DATE_ADD(CURDATE(), INTERVAL 30 DAY));
END //

DROP TRIGGER IF EXISTS student_after_update //
CREATE TRIGGER student_after_update
AFTER UPDATE ON Student
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Log (Table_Name, Action, New_Data)
    VALUES ('Student', 'UPDATE', JSON_OBJECT('id', NEW.Student_ID, 'old_email', OLD.Email, 'new_email', NEW.Email));
END //

DROP TRIGGER IF EXISTS student_after_delete //
CREATE TRIGGER student_after_delete
AFTER DELETE ON Student
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Log (Table_Name, Action, New_Data)
    VALUES ('Student', 'DELETE', JSON_OBJECT('id', OLD.Student_ID, 'name', CONCAT(OLD.First_Name, ' ', OLD.Last_Name)));
END //

DROP TRIGGER IF EXISTS grade_after_insert //
CREATE TRIGGER grade_after_insert
AFTER INSERT ON Grade
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Log (Table_Name, Action, New_Data)
    VALUES ('Grade', 'INSERT', JSON_OBJECT('enroll_id', NEW.Enroll_ID, 'grade', NEW.Grade_Letter));
END //

DROP TRIGGER IF EXISTS grade_after_update //
CREATE TRIGGER grade_after_update
AFTER UPDATE ON Grade
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Log (Table_Name, Action, New_Data)
    VALUES ('Grade', 'UPDATE', JSON_OBJECT('enroll_id', NEW.Enroll_ID, 'old_grade', OLD.Grade_Letter, 'new_grade', NEW.Grade_Letter));
END //

DROP TRIGGER IF EXISTS grade_before_insert //
CREATE TRIGGER grade_before_insert
BEFORE INSERT ON Grade
FOR EACH ROW
BEGIN
    IF NEW.Marks_Obtained > NEW.Max_Marks THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Marks Obtained cannot exceed Max Marks';
    END IF;
END //

DROP TRIGGER IF EXISTS enrollment_after_insert //
CREATE TRIGGER enrollment_after_insert
AFTER INSERT ON Enrollment
FOR EACH ROW
BEGIN
    INSERT IGNORE INTO FeePayment (Student_ID, Semester, Amount_Due, Status, Due_Date)
    VALUES (NEW.Student_ID, NEW.Semester, 50000, 'UNPAID', DATE_ADD(CURDATE(), INTERVAL 30 DAY));
END //

DROP TRIGGER IF EXISTS fee_before_update //
CREATE TRIGGER fee_before_update
BEFORE UPDATE ON FeePayment
FOR EACH ROW
BEGIN
    IF NEW.Amount_Paid >= NEW.Amount_Due THEN
        SET NEW.Status = 'PAID';
    ELSEIF NEW.Amount_Paid > 0 THEN
        SET NEW.Status = 'PARTIAL';
    ELSE
        SET NEW.Status = 'UNPAID';
    END IF;
END //

DELIMITER ;
