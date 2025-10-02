const multer = require('multer');

// Armazenamento em memória para enviar direto ao GCS
const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 100 * 1024 * 1024
    }, // limite 100MB, ajuste se precisar
});

module.exports = upload;
