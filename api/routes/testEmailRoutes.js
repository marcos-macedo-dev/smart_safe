const express = require('express');
const router = express.Router();
const { sendTemplateEmail } = require('../utils/emailService');

// Test endpoint to send a generic email
router.post('/test-email', async (req, res) => {
  try {
    const { email, subject, message } = req.body;
    
    await sendTemplateEmail({
      email,
      subject,
      template: 'generic',
      placeholders: {
        subject,
        message: message.replace(/\n/g, '<br>')
      }
    });
    
    res.status(200).json({
      status: 'success',
      message: 'Test email sent successfully'
    });
  } catch (error) {
    console.error('Error sending test email:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to send test email',
      error: error.message
    });
  }
});

module.exports = router;