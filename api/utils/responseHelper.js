/**
 * Helper para padronizar respostas HTTP
 */

const sendSuccess = (res, data = null, message = '', statusCode = 200) => {
    res.status(statusCode).json({
        success: true,
        data,
        message
    });
};

const sendError = (res, error = '', message = '', statusCode = 500) => {
    res.status(statusCode).json({
        success: false,
        error,
        message
    });
};

module.exports = {
    sendSuccess,
    sendError
};