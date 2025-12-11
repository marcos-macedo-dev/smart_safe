const {
    sendError
} = require('../utils/responseHelper');

/**
 * Middleware de tratamento de erros global
 */
const errorHandler = (err, req, res, next) => {
    console.error('Erro não tratado:', err);

    // Erros de validação do Sequelize
    if (err.name === 'SequelizeValidationError') {
        const errors = err.errors.map(e => e.message);
        return sendError(res, 'Erro de validação', errors.join(', '), 400);
    }

    // Erros de chave estrangeira
    if (err.name === 'SequelizeForeignKeyConstraintError') {
        return sendError(res, 'Erro de integridade referencial', 'Operação viola restrição de chave estrangeira', 400);
    }

    // Erros de unicidade
    if (err.name === 'SequelizeUniqueConstraintError') {
        return sendError(res, 'Erro de unicidade', 'Valor já existe no sistema', 400);
    }

    // Erro padrão
    return sendError(res, 'Erro interno do servidor', 'Ocorreu um erro inesperado');
};

module.exports = errorHandler;