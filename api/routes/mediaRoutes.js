const express = require('express');
const router = express.Router();
const mediaController = require('../controllers/mediaController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Aplicar middleware de autenticação a todas as rotas
router.use(authMiddleware);

// Rotas para Mídia
router.post('/', mediaController.createMedia);
router.get('/', mediaController.getAllMedia);
router.get('/:id', mediaController.getMediaById);
router.put('/:id', mediaController.updateMedia);
router.delete('/:id', mediaController.deleteMedia);

module.exports = router;
