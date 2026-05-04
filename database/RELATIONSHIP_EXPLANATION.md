# SIS TITAN - Database Relationship Guide

This document explains the technical relationships shown in the Entity-Relationship (ER) diagram.

## 1. The Department Hub
The `Department` table acts as the parent for almost all core entities.
- **Student Enrollment:** Each student is linked to a department via `Dept_ID`. This is a mandatory relationship (Double Line `||`) because a student cannot exist in the system without an academic home.
- **Faculty Staffing:** Faculty members are grouped by department.
- **HOD Leadership:** A 1:1 relationship exists between `Department.HOD_ID` and `Faculty.Faculty_ID`. This is optional on the Faculty side (not everyone is an HOD) but critical for department management.

## 2. The Enrollment Transaction
The `Enrollment` table is an **Associative Entity**. It resolves the many-to-many relationship between `Student` and `Course`.
- **Primary Key:** `Enroll_ID` is used as the unique anchor for all performance data.
- **Course Linking:** Connects a specific student to a specific course for a specific semester/year.

## 3. Performance Metrics (Linked to Enrollment)
Instead of linking Grades and Attendance to the Student, they are linked to the `Enroll_ID`.
- **Grade (1:1):** Each enrollment record can have exactly one Grade. If a student retakes a course, it is a new `Enroll_ID`, thus getting a new Grade.
- **Attendance (1:N):** One enrollment record has many attendance check-ins (one for each class session).
- **Alerts:** Automated triggers monitor the `Attendance` and `Grade` tables and generate alerts tied to the `Enroll_ID`.

## 4. Financial Tracking
- **FeePayment:** Linked directly to `Student_ID`. It is partitioned by `Semester` to ensure the system can track if a student has cleared their dues for the current term before allowing exam registration (Eligibility).

## 5. System Integrity
- **Audit_Log:** A decoupled table that uses JSON to store "Before" and "After" snapshots of any record changed in the above tables.
- **ACID Compliance:** All relationships are enforced by Foreign Key constraints with defined `ON DELETE` behaviors (CASCADE or SET NULL) to ensure no orphan records ever exist.
