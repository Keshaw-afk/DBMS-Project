-- SIS TITAN - ADVANCED DATABASE INITIALIZATION
DROP DATABASE IF EXISTS sis_db;
CREATE DATABASE sis_db;
USE sis_db;

-- 1. SCHEMATIC ARCHITECTURE
CREATE TABLE Department (
    Dept_ID INT PRIMARY KEY AUTO_INCREMENT,
    Dept_Name VARCHAR(100) NOT NULL,
    HOD_Name VARCHAR(100),
    Established_Year INT,
    Building VARCHAR(50)
);

CREATE TABLE Student (
    Student_ID INT PRIMARY KEY AUTO_INCREMENT,
    First_Name VARCHAR(50) NOT NULL,
    Last_Name VARCHAR(50) NOT NULL,
    DOB DATE,
    Gender ENUM('M', 'F', 'Other'),
    Email VARCHAR(100) UNIQUE NOT NULL,
    Phone VARCHAR(15),
    Address TEXT,
    Admission_Year INT,
    Dept_ID INT,
    FOREIGN KEY (Dept_ID) REFERENCES Department(Dept_ID)
);

CREATE TABLE Faculty (
    Faculty_ID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Phone VARCHAR(15),
    Designation VARCHAR(50),
    Dept_ID INT,
    Joining_Date DATE,
    FOREIGN KEY (Dept_ID) REFERENCES Department(Dept_ID)
);

CREATE TABLE Course (
    Course_ID INT PRIMARY KEY AUTO_INCREMENT,
    Course_Name VARCHAR(100) NOT NULL,
    Credits INT CHECK (Credits > 0),
    Dept_ID INT,
    Faculty_ID INT,
    Semester_Level INT,
    Max_Capacity INT DEFAULT 60,
    FOREIGN KEY (Dept_ID) REFERENCES Department(Dept_ID),
    FOREIGN KEY (Faculty_ID) REFERENCES Faculty(Faculty_ID)
);

CREATE TABLE Enrollment (
    Enroll_ID INT PRIMARY KEY AUTO_INCREMENT,
    Student_ID INT,
    Course_ID INT,
    Semester INT,
    Academic_Year INT,
    Status ENUM('ENROLLED', 'COMPLETED', 'DROPPED') DEFAULT 'ENROLLED',
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID),
    FOREIGN KEY (Course_ID) REFERENCES Course(Course_ID),
    UNIQUE(Student_ID, Course_ID, Semester, Academic_Year)
);

CREATE TABLE Grade (
    Grade_ID INT PRIMARY KEY AUTO_INCREMENT,
    Enroll_ID INT UNIQUE,
    Marks_Obtained DECIMAL(5,2),
    Max_Marks DECIMAL(5,2),
    Grade_Letter VARCHAR(2),
    Grade_Points INT,
    FOREIGN KEY (Enroll_ID) REFERENCES Enrollment(Enroll_ID)
);

CREATE TABLE Attendance (
    Attend_ID INT PRIMARY KEY AUTO_INCREMENT,
    Enroll_ID INT,
    Session_Date DATE,
    Status ENUM('P', 'A', 'L'),
    FOREIGN KEY (Enroll_ID) REFERENCES Enrollment(Enroll_ID)
);

CREATE TABLE FeePayment (
    Fee_ID INT PRIMARY KEY AUTO_INCREMENT,
    Student_ID INT,
    Semester INT,
    Amount_Due DECIMAL(10,2),
    Amount_Paid DECIMAL(10,2) DEFAULT 0.00,
    Payment_Date DATE,
    Due_Date DATE,
    Status ENUM('PAID', 'PARTIAL', 'UNPAID') DEFAULT 'UNPAID',
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID),
    UNIQUE(Student_ID, Semester)
);

CREATE TABLE Audit_Log (
    Log_ID INT PRIMARY KEY AUTO_INCREMENT,
    Table_Name VARCHAR(50),
    Action VARCHAR(10),
    New_Data TEXT,
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. ADVANCED VIEWS
CREATE VIEW Student_Performance_View AS
SELECT 
    s.Student_ID, s.First_Name, s.Last_Name, e.Semester,
    ROUND(SUM(g.Grade_Points * c.Credits) / SUM(c.Credits), 2) AS SGPA,
    SUM(c.Credits) AS Total_Credits
FROM Student s
JOIN Enrollment e ON s.Student_ID = e.Student_ID
JOIN Grade g ON e.Enroll_ID = g.Enroll_ID
JOIN Course c ON e.Course_ID = c.Course_ID
GROUP BY s.Student_ID, e.Semester;

CREATE VIEW Attendance_Defaulters AS
SELECT s.First_Name, s.Last_Name, c.Course_Name, 
    ROUND((COUNT(CASE WHEN a.Status = 'P' THEN 1 END) / COUNT(*)) * 100, 2) as Percentage
FROM Enrollment e
JOIN Student s ON e.Student_ID = s.Student_ID
JOIN Course c ON e.Course_ID = c.Course_ID
JOIN Attendance a ON e.Enroll_ID = a.Enroll_ID
GROUP BY e.Enroll_ID
HAVING Percentage < 75;

-- 3. ADVANCED FUNCTIONS
DELIMITER //
CREATE FUNCTION Get_Outstanding_Fee(p_sid INT, p_sem INT) RETURNS DECIMAL(10,2) DETERMINISTIC
BEGIN
    DECLARE v_due, v_paid DECIMAL(10,2);
    SELECT Amount_Due, Amount_Paid INTO v_due, v_paid FROM FeePayment WHERE Student_ID = p_sid AND Semester = p_sem;
    RETURN IFNULL(v_due - v_paid, 0);
END //

CREATE FUNCTION Is_Course_Full(p_cid INT) RETURNS BOOLEAN DETERMINISTIC
BEGIN
    DECLARE v_count, v_max INT;
    SELECT COUNT(*) INTO v_count FROM Enrollment WHERE Course_ID = p_cid;
    SELECT Max_Capacity INTO v_max FROM Course WHERE Course_ID = p_cid;
    RETURN v_count >= v_max;
END //
DELIMITER ;

-- 4. COMPLEX PROCEDURES
DELIMITER //
CREATE PROCEDURE Enroll_Student(IN p_sid INT, IN p_cid INT, IN p_sem INT, IN p_year INT)
BEGIN
    DECLARE v_exists INT;
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

CREATE PROCEDURE Post_Grades(IN p_eid INT, IN p_marks DECIMAL(5,2), IN p_max DECIMAL(5,2))
BEGIN
    DECLARE v_points INT;
    DECLARE v_letter VARCHAR(2);
    DECLARE v_perc DECIMAL(5,2);
    SET v_perc = (p_marks / p_max) * 100;
    IF v_perc >= 90 THEN SET v_letter = 'O', v_points = 10;
    ELSEIF v_perc >= 80 THEN SET v_letter = 'A', v_points = 9;
    ELSEIF v_perc >= 70 THEN SET v_letter = 'B', v_points = 8;
    ELSEIF v_perc >= 60 THEN SET v_letter = 'C', v_points = 7;
    ELSEIF v_perc >= 50 THEN SET v_letter = 'D', v_points = 6;
    ELSE SET v_letter = 'F', v_points = 0; END IF;
    INSERT INTO Grade (Enroll_ID, Marks_Obtained, Max_Marks, Grade_Letter, Grade_Points)
    VALUES (p_eid, p_marks, p_max, v_letter, v_points) 
    ON DUPLICATE KEY UPDATE 
        Marks_Obtained=p_marks, 
        Max_Marks=p_max,
        Grade_Letter=v_letter, 
        Grade_Points=v_points;
END //
DELIMITER ;

-- 5. MASSIVE SEED DATA (50+ Students)
INSERT INTO Department (Dept_Name, HOD_Name, Established_Year, Building) VALUES 
('Computer Science', 'Dr. Smith', 1995, 'Block A'), ('Electronics', 'Dr. Johnson', 1998, 'Block B'), 
('Mechanical', 'Dr. Williams', 2000, 'Block C'), ('Civil', 'Dr. Davis', 2002, 'Block D'), 
('Biotech', 'Dr. Moore', 2010, 'Block E');

INSERT INTO Faculty (Name, Email, Designation, Dept_ID) VALUES 
('Alan Turing', 'alan@sis.com', 'Professor', 1), ('Grace Hopper', 'grace@sis.com', 'Professor', 1),
('Marie Curie', 'marie@sis.com', 'Professor', 5), ('Nikola Tesla', 'tesla@sis.com', 'Associate Prof', 2);

INSERT INTO Course (Course_Name, Credits, Dept_ID, Faculty_ID, Semester_Level) VALUES 
('DBMS', 4, 1, 1, 3), ('Data Structures', 4, 1, 2, 3), ('Analog Circuits', 3, 2, 4, 2), ('Microbiology', 4, 5, 3, 1);

-- Loop-like injection for 50 students
INSERT INTO Student (First_Name, Last_Name, Email, Dept_ID, Admission_Year) VALUES
('Liam', 'Smith', 'liam@mail.com', 1, 2024), ('Olivia', 'Jones', 'olivia@mail.com', 1, 2024),
('Noah', 'Taylor', 'noah@mail.com', 2, 2024), ('Emma', 'Brown', 'emma@mail.com', 3, 2024),
('Oliver', 'Wilson', 'oliver@mail.com', 4, 2024), ('Ava', 'Evans', 'ava@mail.com', 5, 2024),
('Elijah', 'Thomas', 'elijah@mail.com', 1, 2024), ('Sophia', 'Roberts', 'sophia@mail.com', 2, 2024),
('James', 'Walker', 'james@mail.com', 3, 2024), ('Isabella', 'White', 'isabella@mail.com', 4, 2024),
('Benjamin', 'Hall', 'ben@mail.com', 5, 2024), ('Mia', 'Allen', 'mia@mail.com', 1, 2024),
('Lucas', 'Young', 'lucas@mail.com', 2, 2024), ('Charlotte', 'King', 'char@mail.com', 3, 2024),
('Henry', 'Wright', 'henry@mail.com', 4, 2024), ('Amelia', 'Scott', 'amelia@mail.com', 5, 2024),
('Alexander', 'Green', 'alex@mail.com', 1, 2024), ('Harper', 'Baker', 'harper@mail.com', 2, 2024),
('Sebastian', 'Adams', 'seb@mail.com', 3, 2024), ('Evelyn', 'Nelson', 'evelyn@mail.com', 4, 2024),
('Jack', 'Hill', 'jack@mail.com', 5, 2024), ('Abigail', 'Ramirez', 'abby@mail.com', 1, 2024),
('Owen', 'Campbell', 'owen@mail.com', 2, 2024), ('Emily', 'Anderson', 'emily@mail.com', 3, 2024),
('Theodore', 'Clark', 'theo@mail.com', 4, 2024), ('Elizabeth', 'Lewis', 'liz@mail.com', 5, 2024),
('Daniel', 'Lee', 'daniel@mail.com', 1, 2024), ('Sofia', 'Walker', 'sofia@mail.com', 2, 2024),
('Matthew', 'Harris', 'matt@mail.com', 3, 2024), ('Avery', 'Clark', 'avery@mail.com', 4, 2024),
('Jackson', 'Lewis', 'jax@mail.com', 5, 2024), ('Scarlett', 'Lee', 'scarlett@mail.com', 1, 2024),
('Levi', 'Walker', 'levi@mail.com', 2, 2024), ('Victoria', 'Harris', 'vicky@mail.com', 3, 2024),
('David', 'Clark', 'david@mail.com', 4, 2024), ('Madison', 'Lewis', 'madison@mail.com', 5, 2024),
('Joseph', 'Lee', 'joe@mail.com', 1, 2024), ('Luna', 'Walker', 'luna@mail.com', 2, 2024),
('Carter', 'Harris', 'carter@mail.com', 3, 2024), ('Grace', 'Clark', 'grace@mail.com', 4, 2024),
('Owen', 'Lewis', 'owen2@mail.com', 5, 2024), ('Chloe', 'Lee', 'chloe@mail.com', 1, 2024),
('Wyatt', 'Walker', 'wyatt@mail.com', 2, 2024), ('Penelope', 'Harris', 'pen@mail.com', 3, 2024),
('John', 'Clark', 'john2@mail.com', 4, 2024), ('Layla', 'Lewis', 'layla@mail.com', 5, 2024),
('Luke', 'Lee', 'luke@mail.com', 1, 2024), ('Riley', 'Walker', 'riley@mail.com', 2, 2024),
('Ezra', 'Harris', 'ezra@mail.com', 3, 2024), ('Zoey', 'Clark', 'zoey@mail.com', 4, 2024);

-- Diverse Fee Payments
TRUNCATE TABLE FeePayment;
INSERT INTO FeePayment (Student_ID, Semester, Amount_Due, Amount_Paid, Due_Date, Status)
SELECT Student_ID, 3, 50000, 
    CASE 
        WHEN Student_ID % 5 = 0 THEN 50000 
        WHEN Student_ID % 3 = 0 THEN 20000 
        ELSE 0 
    END,
    '2024-12-31',
    CASE 
        WHEN Student_ID % 5 = 0 THEN 'PAID'
        WHEN Student_ID % 3 = 0 THEN 'PARTIAL'
        ELSE 'UNPAID'
    END
FROM Student;

-- Seed Enrollments
INSERT INTO Enrollment (Student_ID, Course_ID, Semester, Academic_Year)
SELECT s.Student_ID, c.Course_ID, c.Semester_Level, 2024
FROM Student s
JOIN Course c ON s.Dept_ID = c.Dept_ID
LIMIT 100;

-- Diverse Attendance (last 5 sessions)
TRUNCATE TABLE Attendance;
INSERT INTO Attendance (Enroll_ID, Session_Date, Status)
SELECT e.Enroll_ID, d.dt,
    CASE 
        WHEN (e.Student_ID + DAY(d.dt)) % 4 = 0 THEN 'A'
        ELSE 'P'
    END
FROM Enrollment e
CROSS JOIN (
    SELECT DATE_SUB(CURDATE(), INTERVAL 1 DAY) as dt UNION 
    SELECT DATE_SUB(CURDATE(), INTERVAL 2 DAY) UNION
    SELECT DATE_SUB(CURDATE(), INTERVAL 3 DAY) UNION
    SELECT DATE_SUB(CURDATE(), INTERVAL 4 DAY) UNION
    SELECT DATE_SUB(CURDATE(), INTERVAL 5 DAY)
) d;

-- Seed Grades for some enrollments
INSERT INTO Grade (Enroll_ID, Marks_Obtained, Max_Marks, Grade_Letter, Grade_Points)
SELECT Enroll_ID, 75 + (Enroll_ID % 20), 100, 
    CASE 
        WHEN 75 + (Enroll_ID % 20) >= 90 THEN 'O'
        WHEN 75 + (Enroll_ID % 20) >= 80 THEN 'A'
        ELSE 'B'
    END,
    CASE 
        WHEN 75 + (Enroll_ID % 20) >= 90 THEN 10
        WHEN 75 + (Enroll_ID % 20) >= 80 THEN 9
        ELSE 8
    END
FROM Enrollment
LIMIT 30;
