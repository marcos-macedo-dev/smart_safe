
const express = require('express');
const router = express.Router();
const autoridadeController = require('../controllers/autoridadeController');
const { authMiddleware } = require('../middlewares/authMiddleware');
const { isAdmin } = require('../middlewares/permissionMiddleware');

// Todas as rotas aqui exigem que o usuário esteja autenticado.
router.use(authMiddleware);

// Rota para obter perfil da autoridade logada (acessível por qualquer autoridade)
router.get('/me', autoridadeController.getLoggedInAutoridade);

// Rota para atualizar perfil da autoridade logada (acessível por qualquer autoridade)
router.put('/me', autoridadeController.updateLoggedInAutoridade);

// Rotas que exigem cargo de Admin
router.post('/', isAdmin, autoridadeController.createAutoridade);
router.get('/', isAdmin, autoridadeController.getAutoridadesByDelegacia);
router.put('/:id', isAdmin, autoridadeController.updateAutoridade);
router.delete('/:id', isAdmin, autoridadeController.deleteAutoridade);

module.exports = router;
