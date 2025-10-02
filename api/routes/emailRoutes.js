const express = require('express');
const router = express.Router();
const emailController = require('../controllers/emailController');

// Send a generic template email
router.post('/send-generic-template', emailController.sendGenericTemplateEmail);

// Send a password reset email
router.post('/send-password-reset', emailController.sendPasswordResetEmail);

// Send an invitation email
router.post('/send-invite', emailController.sendInviteEmail);

// Send a notification email with advanced template features
router.post('/send-notification', emailController.sendNotificationEmail);

// Send a custom template email
router.post('/send-custom-template', emailController.sendCustomTemplateEmail);

// Send a generic email (without template)
router.post('/send-custom', emailController.sendCustomEmail);

module.exports = router;