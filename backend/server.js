const express = require('express');
const cors = require('cors');
const path = require('path');
const db = require('./db/connection');
require('dotenv').config();

const app = express();

// 1. Middlewares
app.use(cors());
app.use(express.json());

// 2. Database Connection Check
async function checkConnection() {
    try {
        const connection = await db.getConnection();
        console.log('✅ DATABASE CONNECTED: Connected to "' + process.env.DB_NAME + '"');
        connection.release();
    } catch (err) {
        console.error('❌ DATABASE ERROR: Could not connect to MySQL.');
        console.error('Error Details:', err.message);
        console.log('\nTroubleshooting:');
        console.log('1. Is MySQL running?');
        console.log('2. Is the password "Hello_MYSQL" correct?');
        console.log('3. Did you run "mysql -u root < database/init.sql"?');
    }
}
checkConnection();

// 3. API Endpoints (Must be defined before static/catch-all)
app.get('/api/dashboard', async (req, res) => {
    try {
        const [students] = await db.execute('SELECT COUNT(*) as count FROM Student');
        const [courses] = await db.execute('SELECT COUNT(*) as count FROM Course');
        const [departments] = await db.execute('SELECT COUNT(*) as count FROM Department');
        const [pendingFees] = await db.execute('SELECT COUNT(*) as count FROM FeePayment WHERE Status != "PAID"');
        res.json({
            totalStudents: students[0].count,
            totalCourses: courses[0].count,
            totalDepartments: departments[0].count,
            pendingFees: pendingFees[0].count
        });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/students', async (req, res) => {
    try {
        const [rows] = await db.execute('SELECT s.*, d.Dept_Name FROM Student s LEFT JOIN Department d ON s.Dept_ID = d.Dept_ID');
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/students', async (req, res) => {
    const { first_name, last_name, email, phone, dept_id, admission_year } = req.body;
    try {
        await db.execute('INSERT INTO Student (First_Name, Last_Name, Email, Phone, Dept_ID, Admission_Year) VALUES (?, ?, ?, ?, ?, ?)', [first_name, last_name, email, phone, dept_id, admission_year]);
        res.json({ message: 'Student Registered' });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/courses', async (req, res) => {
    try {
        const [rows] = await db.execute('SELECT c.*, d.Dept_Name, f.Name as Faculty_Name FROM Course c JOIN Department d ON c.Dept_ID = d.Dept_ID JOIN Faculty f ON c.Faculty_ID = f.Faculty_ID');
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/fees', async (req, res) => {
    try {
        const [rows] = await db.execute('SELECT f.*, s.First_Name, s.Last_Name FROM FeePayment f JOIN Student s ON f.Student_ID = s.Student_ID');
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/departments', async (req, res) => {
    try {
        const [rows] = await db.execute('SELECT * FROM Department');
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST routes
app.post('/api/enrollments', async (req, res) => {
    const { student_id, course_id, semester, academic_year } = req.body;
    try {
        await db.execute('CALL Enroll_Student(?, ?, ?, ?)', [student_id, course_id, semester, academic_year]);
        res.json({ message: 'Success' });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/fees/pay', async (req, res) => {
    const { student_id, semester, amount } = req.body;
    try {
        await db.execute('CALL Process_Fee_Payment(?, ?, ?)', [student_id, semester, amount]);
        res.json({ message: 'Success' });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/enrollments/all', async (req, res) => {
    try {
        const [rows] = await db.execute(`
            SELECT e.Enroll_ID, s.First_Name, s.Last_Name, c.Course_Name, e.Semester, e.Academic_Year 
            FROM Enrollment e 
            JOIN Student s ON e.Student_ID = s.Student_ID 
            JOIN Course c ON e.Course_ID = c.Course_ID
        `);
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/faculty', async (req, res) => {
    try {
        const [rows] = await db.execute('SELECT f.*, d.Dept_Name FROM Faculty f JOIN Department d ON f.Dept_ID = d.Dept_ID');
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/performance', async (req, res) => {
    try {
        const [rows] = await db.execute('SELECT * FROM Student_Performance_View');
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/audit', async (req, res) => {
    try {
        const [rows] = await db.execute('SELECT * FROM Audit_Log ORDER BY Timestamp DESC LIMIT 50');
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/attendance/summary', async (req, res) => {
    try {
        const [rows] = await db.execute(`
            SELECT s.First_Name, s.Last_Name, c.Course_Name, 
            Calculate_Attendance_Percentage(e.Enroll_ID) as Percentage
            FROM Enrollment e
            JOIN Student s ON e.Student_ID = s.Student_ID
            JOIN Course c ON e.Course_ID = c.Course_ID
        `);
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// Admin Write Endpoints
app.post('/api/admin/attendance', async (req, res) => {
    const { enroll_id, date, status } = req.body;
    try {
        await db.execute('INSERT INTO Attendance (Enroll_ID, Session_Date, Status) VALUES (?, ?, ?)', [enroll_id, date, status]);
        res.json({ message: 'Attendance Logged' });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// Advanced Analytics Endpoints
app.get('/api/analytics/revenue', async (req, res) => {
    try {
        const [rows] = await db.execute('SELECT Status, SUM(Amount_Paid) as total FROM FeePayment GROUP BY Status');
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/analytics/enrollment-trends', async (req, res) => {
    try {
        const [rows] = await db.execute('SELECT d.Dept_Name, COUNT(s.Student_ID) as count FROM Department d LEFT JOIN Student s ON d.Dept_ID = s.Dept_ID GROUP BY d.Dept_Name');
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/search', async (req, res) => {
    const { q } = req.query;
    try {
        const [students] = await db.execute('SELECT * FROM Student WHERE First_Name LIKE ? OR Last_Name LIKE ? OR Email LIKE ?', [`%${q}%`, `%${q}%`, `%${q}%`]);
        const [courses] = await db.execute('SELECT * FROM Course WHERE Course_Name LIKE ?', [`%${q}%`]);
        const [faculty] = await db.execute('SELECT * FROM Faculty WHERE Name LIKE ? OR Email LIKE ?', [`%${q}%`, `%${q}%`]);
        res.json({ students, courses, faculty });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/alerts', async (req, res) => {
    try {
        const [rows] = await db.execute('SELECT a.*, s.First_Name, s.Last_Name, c.Course_Name FROM Alerts a JOIN Enrollment e ON a.Enroll_ID = e.Enroll_ID JOIN Student s ON e.Student_ID = s.Student_ID JOIN Course c ON e.Course_ID = c.Course_ID ORDER BY Timestamp DESC');
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/admin/defaulters', async (req, res) => {
    try {
        const [rows] = await db.execute('SELECT * FROM Attendance_Defaulters');
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/admin/post-grade', async (req, res) => {
    const { enroll_id, marks, max_marks } = req.body;
    try {
        await db.execute('CALL Post_Grades(?, ?, ?)', [enroll_id, marks, max_marks]);
        res.json({ message: 'Grade Processed via PL/SQL' });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/admin/eligibility/:sid', async (req, res) => {
    const { sid } = req.params;
    try {
        const [fees] = await db.execute('SELECT Status FROM FeePayment WHERE Student_ID = ? ORDER BY Semester DESC LIMIT 1', [sid]);
        const [att] = await db.execute(`
            SELECT AVG(perc) as avg_perc FROM (
                SELECT (COUNT(CASE WHEN Status='P' THEN 1 END) / COUNT(*)) * 100 as perc
                FROM Attendance a 
                JOIN Enrollment e ON a.Enroll_ID = e.Enroll_ID 
                WHERE e.Student_ID = ? 
                GROUP BY e.Enroll_ID
            ) as course_wise`, [sid]);
            
        const feeStatus = fees[0]?.Status || 'NO_RECORD';
        const attendance = att[0]?.avg_perc || 0;
        const isEligible = feeStatus === 'PAID' && attendance >= 75;
        
        res.json({ sid, isEligible, feeStatus, attendance: Math.round(attendance * 100) / 100 });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 4. Static Files
app.use(express.static(path.join(__dirname, 'public')));

// 5. Catch-all (NO regex, NO path-to-regexp)
// This middleware runs for any request that didn't match an API or a static file
app.use((req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 APP STARTED: http://localhost:${PORT}`);
});
