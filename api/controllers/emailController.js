const { sendTemplateEmail, sendGenericEmail } = require('../utils/emailService');

/**
 * Send a generic email using a template
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
exports.sendGenericTemplateEmail = async (req, res) => {
  try {
    const { email, subject, message, placeholders } = req.body;
    
    await sendTemplateEmail({
      email,
      subject,
      template: 'generic',
      placeholders: {
        subject,
        message: message.replace(/\n/g, '<br>'),
        ...placeholders
      }
    });
    
    res.status(200).json({
      status: 'success',
      message: 'Email sent successfully'
    });
  } catch (error) {
    console.error('Error sending email:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to send email'
    });
  }
};

/**
 * Send a password reset email using a template
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
exports.sendPasswordResetEmail = async (req, res) => {
  try {
    const { email, resetURL } = req.body;
    
    await sendTemplateEmail({
      email,
      subject: 'Redefinição de Senha - Smart Safe',
      template: 'reset-password',
      placeholders: {
        reset_url: resetURL
      }
    });
    
    res.status(200).json({
      status: 'success',
      message: 'Password reset email sent successfully'
    });
  } catch (error) {
    console.error('Error sending password reset email:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to send password reset email'
    });
  }
};

/**
 * Send an invitation email using a template
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
exports.sendInviteEmail = async (req, res) => {
  try {
    const { email, nome, delegacia_nome, cargo, accept_url } = req.body;
    
    await sendTemplateEmail({
      email,
      subject: `Convite para ${delegacia_nome} - Smart Safe`,
      template: 'invite',
      placeholders: {
        nome,
        delegacia_nome,
        cargo,
        accept_url
      }
    });
    
    res.status(200).json({
      status: 'success',
      message: 'Invite email sent successfully'
    });
  } catch (error) {
    console.error('Error sending invite email:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to send invite email'
    });
  }
};

/**
 * Send a notification email using a template with advanced features
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
exports.sendNotificationEmail = async (req, res) => {
  try {
    const { email, subject, name, message, button_text, button_url, details } = req.body;
    
    await sendTemplateEmail({
      email,
      subject,
      template: 'notification',
      placeholders: {
        subject,
        name,
        message,
        button_text,
        button_url,
        details
      }
    });
    
    res.status(200).json({
      status: 'success',
      message: 'Notification email sent successfully'
    });
  } catch (error) {
    console.error('Error sending notification email:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to send notification email',
      error: error.message
    });
  }
};

/**
 * Send a custom email using any template
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
exports.sendCustomTemplateEmail = async (req, res) => {
  try {
    const { email, subject, template, placeholders } = req.body;
    
    await sendTemplateEmail({
      email,
      subject,
      template,
      placeholders
    });
    
    res.status(200).json({
      status: 'success',
      message: 'Custom template email sent successfully'
    });
  } catch (error) {
    console.error('Error sending custom template email:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to send custom template email',
      error: error.message
    });
  }
};

/**
 * Send a generic email (without template)
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
exports.sendCustomEmail = async (req, res) => {
  try {
    const { email, subject, message, isHTML } = req.body;
    
    await sendGenericEmail({
      email,
      subject,
      message,
      isHTML
    });
    
    res.status(200).json({
      status: 'success',
      message: 'Custom email sent successfully'
    });
  } catch (error) {
    console.error('Error sending custom email:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to send custom email'
    });
  }
};