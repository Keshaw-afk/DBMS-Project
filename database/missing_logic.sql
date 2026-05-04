USE sis_db;

DELIMITER //

-- Function to calculate attendance percentage for a given enrollment
DROP FUNCTION IF EXISTS Calculate_Attendance_Percentage //
CREATE FUNCTION Calculate_Attendance_Percentage(p_eid INT) RETURNS DECIMAL(5,2) DETERMINISTIC
BEGIN
    DECLARE v_total, v_present INT;
    SELECT COUNT(*) INTO v_total FROM Attendance WHERE Enroll_ID = p_eid;
    IF v_total = 0 THEN RETURN 0.00; END IF;
    SELECT COUNT(*) INTO v_present FROM Attendance WHERE Enroll_ID = p_eid AND Status = 'P';
    RETURN ROUND((v_present / v_total) * 100, 2);
END //

-- Procedure to process fee payment
DROP PROCEDURE IF EXISTS Process_Fee_Payment //
CREATE PROCEDURE Process_Fee_Payment(IN p_sid INT, IN p_sem INT, IN p_amount DECIMAL(10,2))
BEGIN
    DECLARE v_due, v_paid DECIMAL(10,2);
    SELECT Amount_Due, Amount_Paid INTO v_due, v_paid FROM FeePayment WHERE Student_ID = p_sid AND Semester = p_sem;
    
    SET v_paid = v_paid + p_amount;
    
    IF v_paid >= v_due THEN
        UPDATE FeePayment SET Amount_Paid = v_paid, Status = 'PAID', Payment_Date = CURDATE() WHERE Student_ID = p_sid AND Semester = p_sem;
    ELSEIF v_paid > 0 THEN
        UPDATE FeePayment SET Amount_Paid = v_paid, Status = 'PARTIAL', Payment_Date = CURDATE() WHERE Student_ID = p_sid AND Semester = p_sem;
    ELSE
        UPDATE FeePayment SET Amount_Paid = v_paid, Status = 'UNPAID' WHERE Student_ID = p_sid AND Semester = p_sem;
    END IF;
END //

-- Procedure to enroll a student
DROP PROCEDURE IF EXISTS Enroll_Student //
CREATE PROCEDURE Enroll_Student(IN p_sid INT, IN p_cid INT, IN p_sem INT, IN p_year INT)
BEGIN
    DECLARE v_exists INT;
    
    -- Check if already enrolled
    SELECT COUNT(*) INTO v_exists FROM Enrollment 
    WHERE Student_ID = p_sid AND Course_ID = p_cid AND Semester = p_sem AND Academic_Year = p_year;
    
    IF v_exists > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student is already enrolled in this course for the given semester';
    ELSEIF Is_Course_Full(p_cid) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Course Enrollment Limit Reached';
    ELSE
        INSERT INTO Enrollment (Student_ID, Course_ID, Semester, Academic_Year) VALUES (p_sid, p_cid, p_sem, p_year);
    END IF;
END //

DELIMITER ;
