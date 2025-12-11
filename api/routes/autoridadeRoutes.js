
const express = require('express');
const router = express.Router();
const autoridadeController = require('../controllers/autoridadeController');
const { authMiddleware } = require('../middlewares/authMiddleware');
const { isUnidade } = require('../middlewares/permissionMiddleware');

// Todas as rotas aqui exigem que o usuário esteja autenticado.
router.use(authMiddleware);

// Rota para obter perfil da autoridade logada (acessível por qualquer autoridade)
router.get('/me', autoridadeController.getLoggedInAutoridade);

// Rota para atualizar perfil da autoridade logada (acessível por qualquer autoridade)
router.put('/me', autoridadeController.updateLoggedInAutoridade);

// Rotas que exigem cargo de Unidade
router.post('/', isUnidade, autoridadeController.createAutoridade);
router.get('/', isUnidade, autoridadeController.getAutoridadesByDelegacia);
router.put('/:id', isUnidade, autoridadeController.updateAutoridade);
router.delete('/:id', isUnidade, autoridadeController.deleteAutoridade);

module.exports = router;
