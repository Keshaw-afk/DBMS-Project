USE sis_db;

DELIMITER //

-- AUDIT LOG TRIGGERS

DROP TRIGGER IF EXISTS student_after_insert //
CREATE TRIGGER student_after_insert
AFTER INSERT ON Student
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Log (Table_Name, Action, New_Data)
    VALUES ('Student', 'INSERT', JSON_OBJECT(
        'id', NEW.Student_ID, 
        'name', CONCAT(NEW.First_Name, ' ', NEW.Last_Name), 
        'email', NEW.Email,
        'dept_id', NEW.Dept_ID
    ));

    -- Automatically create a fee record for the student's entry semester
    -- Use 1 as default semester for new students
    INSERT IGNORE INTO FeePayment (Student_ID, Semester, Amount_Due, Status, Due_Date)
    VALUES (NEW.Student_ID, 1, 50000, 'UNPAID', DATE_ADD(CURDATE(), INTERVAL 30 DAY));
END //

DROP TRIGGER IF EXISTS student_after_update //
CREATE TRIGGER student_after_update
AFTER UPDATE ON Student
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Log (Table_Name, Action, Old_Data, New_Data)
    VALUES ('Student', 'UPDATE', 
        JSON_OBJECT('id', OLD.Student_ID, 'email', OLD.Email, 'dept_id', OLD.Dept_ID),
        JSON_OBJECT('id', NEW.Student_ID, 'email', NEW.Email, 'dept_id', NEW.Dept_ID)
    );
END //

DROP TRIGGER IF EXISTS student_after_delete //
CREATE TRIGGER student_after_delete
AFTER DELETE ON Student
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Log (Table_Name, Action, Old_Data)
    VALUES ('Student', 'DELETE', JSON_OBJECT('id', OLD.Student_ID, 'name', CONCAT(OLD.First_Name, ' ', OLD.Last_Name)));
END //

-- ENROLLMENT TRIGGERS

DROP TRIGGER IF EXISTS enrollment_after_insert //
CREATE TRIGGER enrollment_after_insert
AFTER INSERT ON Enrollment
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Log (Table_Name, Action, New_Data)
    VALUES ('Enrollment', 'INSERT', JSON_OBJECT('enroll_id', NEW.Enroll_ID, 'student_id', NEW.Student_ID, 'course_id', NEW.Course_ID));

    -- Ensure a fee record exists for the semester the student is enrolling in
    INSERT IGNORE INTO FeePayment (Student_ID, Semester, Amount_Due, Status, Due_Date)
    VALUES (NEW.Student_ID, NEW.Semester, 50000, 'UNPAID', DATE_ADD(CURDATE(), INTERVAL 30 DAY));
END //

-- GRADE TRIGGERS

DROP TRIGGER IF EXISTS grade_before_insert //
CREATE TRIGGER grade_before_insert
BEFORE INSERT ON Grade
FOR EACH ROW
BEGIN
    IF NEW.Marks_Obtained > NEW.Max_Marks THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Marks Obtained cannot exceed Max Marks';
    END IF;
END //

DROP TRIGGER IF EXISTS grade_after_insert //
CREATE TRIGGER grade_after_insert
AFTER INSERT ON Grade
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Log (Table_Name, Action, New_Data)
    VALUES ('Grade', 'INSERT', JSON_OBJECT('enroll_id', NEW.Enroll_ID, 'marks', NEW.Marks_Obtained));
END //

DROP TRIGGER IF EXISTS grade_after_update //
CREATE TRIGGER grade_after_update
AFTER UPDATE ON Grade
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Log (Table_Name, Action, Old_Data, New_Data)
    VALUES ('Grade', 'UPDATE', 
        JSON_OBJECT('enroll_id', OLD.Enroll_ID, 'marks', OLD.Marks_Obtained),
        JSON_OBJECT('enroll_id', NEW.Enroll_ID, 'marks', NEW.Marks_Obtained)
    );
END //

-- ATTENDANCE TRIGGERS (Including Alert Logic)

DROP TRIGGER IF EXISTS attendance_after_insert //
CREATE TRIGGER attendance_after_insert
AFTER INSERT ON Attendance
FOR EACH ROW
BEGIN
    DECLARE v_perc DECIMAL(5,2);
    
    -- Audit Log
    INSERT INTO Audit_Log (Table_Name, Action, New_Data)
    VALUES ('Attendance', 'INSERT', JSON_OBJECT('enroll_id', NEW.Enroll_ID, 'date', NEW.Session_Date, 'status', NEW.Status));

    -- Low Attendance Alert
    SET v_perc = Calculate_Attendance_Percentage(NEW.Enroll_ID);
    IF v_perc < 75 THEN
        INSERT INTO Alerts (Enroll_ID, Message)
        VALUES (NEW.Enroll_ID, CONCAT('Low Attendance Alert: ', v_perc, '% (Required: 75%)'));
    END IF;
END //

-- FEE PAYMENT TRIGGERS

DROP TRIGGER IF EXISTS fee_before_update //
CREATE TRIGGER fee_before_update
BEFORE UPDATE ON FeePayment
FOR EACH ROW
BEGIN
    -- Automatic status update based on payment
    IF NEW.Amount_Paid >= NEW.Amount_Due THEN
        SET NEW.Status = 'PAID';
    ELSEIF NEW.Amount_Paid > 0 THEN
        SET NEW.Status = 'PARTIAL';
    ELSE
        SET NEW.Status = 'UNPAID';
    END IF;
END //

DELIMITER ;
