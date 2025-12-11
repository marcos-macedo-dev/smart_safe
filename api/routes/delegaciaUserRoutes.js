const express = require('express');
const router = express.Router();
const delegaciaUserController = require('../controllers/delegaciaUserController');
const { authMiddleware } = require('../middlewares/authMiddleware');
const { isUnidade } = require('../middlewares/permissionMiddleware');

// Todas as rotas aqui exigem que o usuário esteja autenticado
router.use(authMiddleware);

// Listar todos os usuários da delegacia (acessível por qualquer autoridade da mesma delegacia)
router.get('/', delegaciaUserController.getUsersByDelegacia);

// Buscar um usuário específico (acessível por qualquer autoridade da mesma delegacia)
router.get('/:id', delegaciaUserController.getUserById);

// Atualizar um usuário (exige cargo de Unidade)
router.put('/:id', isUnidade, delegaciaUserController.updateUser);

// Desativar um usuário (exige cargo de Unidade)
router.patch('/:id/deactivate', isUnidade, delegaciaUserController.deactivateUser);

// Reativar um usuário (exige cargo de Unidade)
router.patch('/:id/reactivate', isUnidade, delegaciaUserController.reactivateUser);

module.exports = router;