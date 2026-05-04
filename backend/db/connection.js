const mysql = require('mysql2');
require('dotenv').config();

const pool = mysql.createPool({
    host: process.env.MYSQLHOST || process.env.DB_HOST || 'localhost',
    user: process.env.MYSQLUSER || process.env.DB_USER || 'root',
    password: process.env.MYSQLPASSWORD || process.env.DB_PASS || 'Hello_MYSQL',
    database: process.env.MYSQLDATABASE || process.env.DB_NAME || 'sis_db',
    port: process.env.MYSQLPORT || process.env.DB_PORT || 3306,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    // Add SSL for cloud providers if needed
    ssl: process.env.MYSQL_SSL ? { rejectUnauthorized: false } : null
});

module.exports = pool.promise();
