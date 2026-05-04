const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function initialize() {
    console.log('🚀 Starting Cloud Database Initialization...');
    
    const connection = await mysql.createConnection({
        host: process.env.MYSQLHOST || process.env.DB_HOST || 'localhost',
        user: process.env.MYSQLUSER || process.env.DB_USER || 'root',
        password: process.env.MYSQLPASSWORD || process.env.DB_PASS || 'Hello_MYSQL',
        database: process.env.MYSQLDATABASE || process.env.DB_NAME,
        port: process.env.MYSQLPORT || process.env.DB_PORT || 3306,
        multipleStatements: true
    });

    const sqlFiles = [
        '../database/init.sql',
        '../database/missing_logic.sql',
        '../database/triggers.sql',
        '../database/alerts.sql'
    ];

    try {
        for (const file of sqlFiles) {
            console.log(`📖 Executing: ${file}`);
            let content = fs.readFileSync(path.join(__dirname, file), 'utf8');
            
            // Remove 'USE sis_db;' as Railway handles database selection
            content = content.replace(/USE\s+sis_db;/gi, '');
            // Remove DELIMITER statements as they are for CLI/WorkBench
            content = content.replace(/DELIMITER \/\/|DELIMITER ;/g, '');
            // Replace // with ; for procedures/triggers
            content = content.replace(/\/\/(\s*)/g, ';$1');

            await connection.query(content);
            console.log(`✅ Success: ${file}`);
        }
        console.log('\n✨ DATABASE INITIALIZED SUCCESSFULLY');
    } catch (err) {
        console.error('❌ INITIALIZATION ERROR:', err.message);
    } finally {
        await connection.end();
    }
}

initialize();
