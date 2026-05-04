-- SIS TITAN - ADVANCED DATABASE INITIALIZATION (ROBUST & NORMALIZED)
DROP DATABASE IF EXISTS sis_db;
CREATE DATABASE sis_db;
USE sis_db;

-- 1. SCHEMATIC ARCHITECTURE

-- Grade Scheme for normalization of grades
CREATE TABLE Grade_Scheme (
    Scheme_ID INT PRIMARY KEY AUTO_INCREMENT,
    Min_Percentage DECIMAL(5,2) NOT NULL,
    Max_Percentage DECIMAL(5,2) NOT NULL,
    Grade_Letter VARCHAR(2) NOT NULL,
    Grade_Points INT NOT NULL,
    UNIQUE(Grade_Letter),
    CONSTRAINT chk_percentage CHECK (Min_Percentage <= Max_Percentage)
);

CREATE TABLE Department (
    Dept_ID INT PRIMARY KEY AUTO_INCREMENT,
    Dept_Name VARCHAR(100) NOT NULL UNIQUE,
    HOD_ID INT, -- Will be FK to Faculty
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
    FOREIGN KEY (Dept_ID) REFERENCES Department(Dept_ID) ON DELETE SET NULL,
    INDEX idx_student_dept (Dept_ID)
);

CREATE TABLE Faculty (
    Faculty_ID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Phone VARCHAR(15),
    Designation VARCHAR(50),
    Dept_ID INT,
    Joining_Date DATE,
    FOREIGN KEY (Dept_ID) REFERENCES Department(Dept_ID) ON DELETE SET NULL,
    INDEX idx_faculty_dept (Dept_ID)
);

-- Add HOD_ID FK to Department after Faculty table is created
ALTER TABLE Department ADD FOREIGN KEY (HOD_ID) REFERENCES Faculty(Faculty_ID) ON DELETE SET NULL;

CREATE TABLE Course (
    Course_ID INT PRIMARY KEY AUTO_INCREMENT,
    Course_Name VARCHAR(100) NOT NULL,
    Credits INT NOT NULL CHECK (Credits > 0),
    Dept_ID INT,
    Faculty_ID INT,
    Semester_Level INT CHECK (Semester_Level > 0),
    Max_Capacity INT DEFAULT 60 CHECK (Max_Capacity > 0),
    FOREIGN KEY (Dept_ID) REFERENCES Department(Dept_ID) ON DELETE SET NULL,
    FOREIGN KEY (Faculty_ID) REFERENCES Faculty(Faculty_ID) ON DELETE SET NULL,
    INDEX idx_course_dept (Dept_ID),
    INDEX idx_course_faculty (Faculty_ID)
);

CREATE TABLE Enrollment (
    Enroll_ID INT PRIMARY KEY AUTO_INCREMENT,
    Student_ID INT NOT NULL,
    Course_ID INT NOT NULL,
    Semester INT NOT NULL,
    Academic_Year INT NOT NULL,
    Status ENUM('ENROLLED', 'COMPLETED', 'DROPPED') DEFAULT 'ENROLLED',
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE CASCADE,
    FOREIGN KEY (Course_ID) REFERENCES Course(Course_ID) ON DELETE CASCADE,
    UNIQUE(Student_ID, Course_ID, Semester, Academic_Year),
    INDEX idx_enrollment_student (Student_ID),
    INDEX idx_enrollment_course (Course_ID)
);

CREATE TABLE Grade (
    Grade_ID INT PRIMARY KEY AUTO_INCREMENT,
    Enroll_ID INT UNIQUE NOT NULL,
    Marks_Obtained DECIMAL(5,2) NOT NULL,
    Max_Marks DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (Enroll_ID) REFERENCES Enrollment(Enroll_ID) ON DELETE CASCADE,
    CONSTRAINT chk_marks CHECK (Marks_Obtained <= Max_Marks)
);

CREATE TABLE Attendance (
    Attend_ID INT PRIMARY KEY AUTO_INCREMENT,
    Enroll_ID INT NOT NULL,
    Session_Date DATE NOT NULL,
    Status ENUM('P', 'A', 'L') NOT NULL,
    FOREIGN KEY (Enroll_ID) REFERENCES Enrollment(Enroll_ID) ON DELETE CASCADE,
    INDEX idx_attendance_enroll (Enroll_ID),
    INDEX idx_attendance_date (Session_Date)
);

CREATE TABLE FeePayment (
    Fee_ID INT PRIMARY KEY AUTO_INCREMENT,
    Student_ID INT NOT NULL,
    Semester INT NOT NULL,
    Amount_Due DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    Amount_Paid DECIMAL(10,2) DEFAULT 0.00,
    Payment_Date DATE,
    Due_Date DATE,
    Status ENUM('PAID', 'PARTIAL', 'UNPAID') DEFAULT 'UNPAID',
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE CASCADE,
    UNIQUE(Student_ID, Semester),
    INDEX idx_fee_student (Student_ID)
);

CREATE TABLE Audit_Log (
    Log_ID INT PRIMARY KEY AUTO_INCREMENT,
    Table_Name VARCHAR(50),
    Action VARCHAR(10),
    Old_Data JSON,
    New_Data JSON,
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Alerts (
    Alert_ID INT PRIMARY KEY AUTO_INCREMENT,
    Enroll_ID INT,
    Message TEXT,
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Enroll_ID) REFERENCES Enrollment(Enroll_ID) ON DELETE CASCADE
);

-- 2. ADVANCED VIEWS FOR EASY QUERYING

-- View for mapping grades using Grade_Scheme
CREATE VIEW Grade_Report AS
SELECT 
    g.Grade_ID,
    g.Enroll_ID,
    g.Marks_Obtained,
    g.Max_Marks,
    (g.Marks_Obtained / g.Max_Marks * 100) as Percentage,
    gs.Grade_Letter,
    gs.Grade_Points
FROM Grade g
JOIN Grade_Scheme gs ON (g.Marks_Obtained / g.Max_Marks * 100) BETWEEN gs.Min_Percentage AND gs.Max_Percentage;

CREATE VIEW Student_Performance_View AS
SELECT 
    s.Student_ID, s.First_Name, s.Last_Name, e.Semester,
    ROUND(SUM(gr.Grade_Points * c.Credits) / SUM(c.Credits), 2) AS SGPA,
    SUM(c.Credits) AS Total_Credits
FROM Student s
JOIN Enrollment e ON s.Student_ID = e.Student_ID
JOIN Grade_Report gr ON e.Enroll_ID = gr.Enroll_ID
JOIN Course c ON e.Course_ID = c.Course_ID
GROUP BY s.Student_ID, e.Semester;

CREATE VIEW Attendance_Report AS
SELECT 
    e.Enroll_ID,
    s.Student_ID,
    s.First_Name,
    s.Last_Name,
    c.Course_Name,
    COUNT(*) as Total_Sessions,
    SUM(CASE WHEN a.Status = 'P' THEN 1 ELSE 0 END) as Present_Sessions,
    ROUND((SUM(CASE WHEN a.Status = 'P' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) as Percentage
FROM Enrollment e
JOIN Student s ON e.Student_ID = s.Student_ID
JOIN Course c ON e.Course_ID = c.Course_ID
JOIN Attendance a ON e.Enroll_ID = a.Enroll_ID
GROUP BY e.Enroll_ID;

CREATE VIEW Attendance_Defaulters AS
SELECT * FROM Attendance_Report WHERE Percentage < 75;

-- 3. SEED DATA

INSERT INTO Grade_Scheme (Min_Percentage, Max_Percentage, Grade_Letter, Grade_Points) VALUES
(90.00, 100.00, 'O', 10),
(80.00, 89.99, 'A', 9),
(70.00, 79.99, 'B', 8),
(60.00, 69.99, 'C', 7),
(50.00, 59.99, 'D', 6),
(0.00, 49.99, 'F', 0);

INSERT INTO Department (Dept_Name, HOD_ID, Established_Year, Building) VALUES 
('Computer Science', NULL, 1995, 'Block A'), 
('Electronics', NULL, 1998, 'Block B'), 
('Mechanical', NULL, 2000, 'Block C'), 
('Civil', NULL, 2002, 'Block D'), 
('Biotech', NULL, 2010, 'Block E');

INSERT INTO Faculty (Name, Email, Designation, Dept_ID) VALUES 
('Alan Turing', 'alan@sis.com', 'Professor', 1), 
('Grace Hopper', 'grace@sis.com', 'Professor', 1),
('Marie Curie', 'marie@sis.com', 'Professor', 5), 
('Nikola Tesla', 'tesla@sis.com', 'Associate Prof', 2);

-- Update HODs
UPDATE Department SET HOD_ID = 1 WHERE Dept_ID = 1;
UPDATE Department SET HOD_ID = 4 WHERE Dept_ID = 2;
UPDATE Department SET HOD_ID = 3 WHERE Dept_ID = 5;

INSERT INTO Course (Course_Name, Credits, Dept_ID, Faculty_ID, Semester_Level) VALUES 
('DBMS', 4, 1, 1, 3), 
('Data Structures', 4, 1, 2, 3), 
('Analog Circuits', 3, 2, 4, 2), 
('Microbiology', 4, 5, 3, 1);

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

-- Seed Fees
INSERT INTO FeePayment (Student_ID, Semester, Amount_Due, Amount_Paid, Due_Date, Status)
SELECT Student_ID, 1, 50000, 
    CASE 
        WHEN Student_ID % 5 = 0 THEN 50000 
        WHEN Student_ID % 3 = 0 THEN 20000 
        ELSE 0 
    END,
    DATE_ADD(CURDATE(), INTERVAL 30 DAY),
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

-- Seed Attendance
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

-- Seed Grades
INSERT INTO Grade (Enroll_ID, Marks_Obtained, Max_Marks)
SELECT Enroll_ID, 75 + (Enroll_ID % 20), 100
FROM Enrollment
LIMIT 30;
