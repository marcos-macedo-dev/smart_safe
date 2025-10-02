const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Rota pública para login
router.post('/login', authController.login);

// Rotas públicas para usuários (cidadãs) - Fluxo OTP
router.post('/request-password-reset/user', authController.requestPasswordResetUser);
router.post('/reset-password/otp', authController.resetPasswordWithOtp);

// Rotas públicas para autoridades - Fluxo por email com token
router.post('/request-password-reset/authority', authController.requestPasswordResetAuthority);
router.post('/reset-password/authority/:token', authController.resetPasswordWithToken);

// Rota protegida para logout
router.post('/logout', authController.logout);

// Rota protegida para mudança de senha de usuário autenticado
router.post('/change-password', authMiddleware, authController.changePassword);

module.exports = router;