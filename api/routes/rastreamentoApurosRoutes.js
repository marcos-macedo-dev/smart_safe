const express = require('express');
const router = express.Router();
const RastreamentoApurosController = require('../controllers/rastreamentoApurosController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Aplicar middleware de autenticação a todas as rotas
router.use(authMiddleware);

// Injeta io do servidor principal no controller
RastreamentoApurosController.setIo = (io) => {
  RastreamentoApurosController.io = io;
};

router.post('/', RastreamentoApurosController.create);
router.get('/:sos_id', RastreamentoApurosController.getBySos);

module.exports = router;

