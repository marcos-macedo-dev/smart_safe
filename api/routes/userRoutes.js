const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Registro
router.post('/', userController.createUser);
router.get('/', authMiddleware, userController.getAllUsers);
// Perfil logado
router.get('/me', authMiddleware, userController.getLoggedInUser);
// Outros endpoints já existentes
router.get('/:id', userController.getUserById);
router.put('/:id', authMiddleware, userController.updateUser);
router.delete('/:id', authMiddleware, userController.deleteUser);

module.exports = router;
