const express = require('express');
const router = express.Router();
const delegaciaUserController = require('../controllers/delegaciaUserController');
const { authMiddleware } = require('../middlewares/authMiddleware');
const { isAdmin } = require('../middlewares/permissionMiddleware');

// Todas as rotas aqui exigem que o usuário esteja autenticado e seja administrador
router.use(authMiddleware);

// Listar todos os usuários da delegacia
router.get('/', delegaciaUserController.getUsersByDelegacia);

// Buscar um usuário específico
router.get('/:id', delegaciaUserController.getUserById);

// Atualizar um usuário
router.put('/:id', delegaciaUserController.updateUser);

// Desativar um usuário
router.patch('/:id/deactivate', delegaciaUserController.deactivateUser);

// Reativar um usuário
router.patch('/:id/reactivate', delegaciaUserController.reactivateUser);

module.exports = router;