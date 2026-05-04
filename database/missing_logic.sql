USE sis_db;

DELIMITER //

-- Function to check if a course is full
DROP FUNCTION IF EXISTS Is_Course_Full //
CREATE FUNCTION Is_Course_Full(p_cid INT) RETURNS BOOLEAN DETERMINISTIC
BEGIN
    DECLARE v_count, v_max INT;
    SELECT COUNT(*) INTO v_count FROM Enrollment WHERE Course_ID = p_cid AND Status = 'ENROLLED';
    SELECT Max_Capacity INTO v_max FROM Course WHERE Course_ID = p_cid;
    RETURN IFNULL(v_count >= v_max, FALSE);
END //

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

-- Procedure to process fee payment with ACID compliance
DROP PROCEDURE IF EXISTS Process_Fee_Payment //
CREATE PROCEDURE Process_Fee_Payment(IN p_sid INT, IN p_sem INT, IN p_amount DECIMAL(10,2))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error occurred during fee payment processing';
    END;

    START TRANSACTION;
        UPDATE FeePayment 
        SET Amount_Paid = Amount_Paid + p_amount,
            Payment_Date = CURDATE(),
            Status = CASE 
                        WHEN (Amount_Paid + p_amount) >= Amount_Due THEN 'PAID'
                        WHEN (Amount_Paid + p_amount) > 0 THEN 'PARTIAL'
                        ELSE 'UNPAID'
                     END
        WHERE Student_ID = p_sid AND Semester = p_sem;
    COMMIT;
END //

-- Procedure to enroll a student with ACID compliance
DROP PROCEDURE IF EXISTS Enroll_Student //
CREATE PROCEDURE Enroll_Student(IN p_sid INT, IN p_cid INT, IN p_sem INT, IN p_year INT)
BEGIN
    DECLARE v_exists INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        -- Check if already enrolled
        SELECT COUNT(*) INTO v_exists FROM Enrollment 
        WHERE Student_ID = p_sid AND Course_ID = p_cid AND Semester = p_sem AND Academic_Year = p_year;
        
        IF v_exists > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student is already enrolled in this course for the given semester';
        ELSEIF Is_Course_Full(p_cid) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Course Enrollment Limit Reached';
        ELSE
            INSERT INTO Enrollment (Student_ID, Course_ID, Semester, Academic_Year) 
            VALUES (p_sid, p_cid, p_sem, p_year);
        END IF;
    COMMIT;
END //

-- Procedure to post grades with ACID compliance
DROP PROCEDURE IF EXISTS Post_Grades //
CREATE PROCEDURE Post_Grades(IN p_eid INT, IN p_marks DECIMAL(5,2), IN p_max DECIMAL(5,2))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        INSERT INTO Grade (Enroll_ID, Marks_Obtained, Max_Marks)
        VALUES (p_eid, p_marks, p_max) 
        ON DUPLICATE KEY UPDATE 
            Marks_Obtained = p_marks, 
            Max_Marks = p_max;
    COMMIT;
END //

DELIMITER ;
