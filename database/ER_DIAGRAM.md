# SIS TITAN - Entity Relationship Diagram

This diagram represents the normalized, ACID-compliant schema of the Student Information System.

## Mermaid ER Diagram

```mermaid
erDiagram
    DEPARTMENT ||--o{ STUDENT : "enrolled in"
    DEPARTMENT ||--o{ FACULTY : "staffed with"
    DEPARTMENT ||--o{ COURSE : "offered by"
    FACULTY |o--|| DEPARTMENT : "acts as HOD"
    FACULTY ||--o{ COURSE : "teaches"
    
    STUDENT ||--o{ ENROLLMENT : "participates in"
    STUDENT ||--o{ FEE_PAYMENT : "pays"
    
    COURSE ||--o{ ENROLLMENT : "has students"
    
    ENROLLMENT ||--o| GRADE : "receives"
    ENROLLMENT ||--o{ ATTENDANCE : "tracks"
    ENROLLMENT ||--o{ ALERTS : "triggers"
    
    GRADE_SCHEME ||--o{ GRADE : "determines (logic)"

    DEPARTMENT {
        int Dept_ID PK
        string Dept_Name UK "Unique Name"
        int HOD_ID FK "Link to Faculty"
        int Established_Year
        string Building
    }

    STUDENT {
        int Student_ID PK
        string First_Name
        string Last_Name
        date DOB
        string Email UK "Unique"
        int Dept_ID FK
    }

    FACULTY {
        int Faculty_ID PK
        string Name
        string Email UK
        int Dept_ID FK
        string Designation
    }

    COURSE {
        int Course_ID PK
        string Course_Name
        int Credits
        int Dept_ID FK
        int Faculty_ID FK
        int Max_Capacity
    }

    ENROLLMENT {
        int Enroll_ID PK
        int Student_ID FK
        int Course_ID FK
        int Semester
        int Academic_Year
        enum Status "ENROLLED, COMPLETED, DROPPED"
    }

    GRADE {
        int Grade_ID PK
        int Enroll_ID FK "Unique - One per Enrollment"
        decimal Marks_Obtained
        decimal Max_Marks
    }

    ATTENDANCE {
        int Attend_ID PK
        int Enroll_ID FK
        date Session_Date
        enum Status "P, A, L"
    }

    FEE_PAYMENT {
        int Fee_ID PK
        int Student_ID FK
        int Semester
        decimal Amount_Due
        decimal Amount_Paid
        enum Status "PAID, PARTIAL, UNPAID"
    }

    GRADE_SCHEME {
        int Scheme_ID PK
        decimal Min_Percentage
        decimal Max_Percentage
        string Grade_Letter UK
        int Grade_Points
    }

    AUDIT_LOG {
        int Log_ID PK
        string Table_Name
        string Action
        json Old_Data
        json New_Data
        datetime Timestamp
    }
```

## Entity Details

### 1. Core Entities
- **Student**: Contains personal and academic registration info.
- **Faculty**: Contains teaching staff details.
- **Department**: The organizational unit owning courses and students.

### 2. Academic Entities
- **Course**: Defined by credits and department.
- **Enrollment**: An associative entity linking a student to a course for a specific term.
- **Grade**: Linked to Enrollment; stores raw marks.
- **Attendance**: Daily logs linked to specific enrollments.

### 3. Logic & Support
- **Grade_Scheme**: Reference table for percentage-to-letter-grade mapping.
- **Fee_Payment**: Financial records per student/semester.
- **Audit_Log**: JSON-based history of all system changes.
- **Alerts**: Automated messages triggered by triggers (e.g., low attendance).
