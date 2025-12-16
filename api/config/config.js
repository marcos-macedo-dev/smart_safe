require('dotenv').config();

module.exports = {
  development: {
    username: process.env.DB_USER || 'user',
    password: process.env.DB_PASS || 'password',
    database: process.env.DB_NAME || 'smart_safe_db',
    host: process.env.DB_HOST || '127.0.0.1',
    port: process.env.DB_PORT || 3306,
    dialect: 'mysql'
  },
  test: {
    username: process.env.DB_USER || 'root',
    password: process.env.DB_PASS || null,
    database: 'database_test',
    host: '127.0.0.1',
    dialect: 'mysql'
  },
  production: {
    // Opção 1: Usar a URL completa (Padrão Railway: DATABASE_URL ou MYSQL_URL)
    use_env_variable: 'DATABASE_URL', 
    
    // Opção 2: Fallback para variáveis individuais se a URL não for usada
    username: process.env.MYSQLUSER || process.env.DB_USER,
    password: process.env.MYSQLPASSWORD || process.env.DB_PASS,
    database: process.env.MYSQLDATABASE || process.env.DB_NAME,
    host: process.env.MYSQLHOST || process.env.DB_HOST,
    port: process.env.MYSQLPORT || process.env.DB_PORT,
    
    dialect: 'mysql',
    dialectOptions: {
      // Importante para conexões SSL em nuvem (Railway às vezes exige, às vezes não, mas é bom ter)
      ssl: {
        require: true,
        rejectUnauthorized: false 
      }
    },
    logging: false // Desativa logs de SQL em produção para limpar o console
  }
};
