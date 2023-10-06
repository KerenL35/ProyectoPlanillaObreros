const sql = require('mssql')

var dbSettings = {
    user: 'sa',
    password: '12345',
    server: 'KEREN',
    database: 'PlanillaObrera',
    port:  1433,
    options: {
        encrypt: true,
        trustServerCertificate: true,
    },
}

async function getConnection() {
    try {
    const pool = await sql.connect(dbSettings);
    console.dir(pool)
    return pool;
    } catch (error) {
        console.error(error);
    }
}
module.exports = {getConnection}