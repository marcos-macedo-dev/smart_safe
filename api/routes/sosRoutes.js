const express = require('express');
const router = express.Router();
const sosController = require('../controllers/sosController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Aplicar middleware de autenticação a todas as rotas
router.use(authMiddleware);

// Rotas para SOS
router.post('/', sosController.createSos);
router.get('/', sosController.getAllSos);
router.get('/:id', sosController.getSosById);
router.put('/:id', sosController.updateSos);
router.delete('/:id', sosController.deleteSos);

module.exports = router;
