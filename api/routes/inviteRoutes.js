const express = require('express');
const router = express.Router();
const inviteController = require('../controllers/inviteController');
const { authMiddleware } = require('../middlewares/authMiddleware');
const { isAdmin } = require('../middlewares/permissionMiddleware');

// Aceitar convite (não requer autenticação prévia)
router.post('/accept', inviteController.acceptInvite);

// Verificar token de convite (não requer autenticação)
router.get('/verify/:token', inviteController.verifyInviteToken);

// Rotas que exigem autenticação de administrador
router.use(authMiddleware);

// Enviar convite (apenas administradores)
router.post('/send', isAdmin, inviteController.sendInvite);

module.exports = router;