const nodemailer = require('nodemailer');
const fs = require('fs').promises;
const path = require('path');

/**
 * Create a transporter for sending emails
 * @returns {Object} Nodemailer transporter
 */
const createTransporter = () => {
  return nodemailer.createTransport({
    host: process.env.EMAIL_HOST,
    port: process.env.EMAIL_PORT,
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });
};

/**
 * Simple template engine to process placeholders
 * @param {string} template - Template content
 * @param {Object} data - Data to replace placeholders
 * @returns {string} Processed template
 */
const processTemplate = (template, data) => {
  // Handle conditionals: {{#if key}}...{{/if}}
  template = template.replace(/{{#if\s+(\w+)}}([\s\S]*?){{\/if}}/g, (match, key, content) => {
    return data[key] ? content : '';
  });
  
  // Handle loops: {{#each array}}...{{/each}}
  template = template.replace(/{{#each\s+(\w+)}}([\s\S]*?){{\/each}}/g, (match, key, content) => {
    if (!Array.isArray(data[key])) return '';
    
    return data[key].map(item => {
      // For simple array items (strings, numbers)
      if (typeof item !== 'object') {
        return content.replace(/{{this}}/g, item);
      }
      
      // For object array items
      let result = content;
      Object.keys(item).forEach(prop => {
        const regex = new RegExp(`{{this\\.${prop}}}`, 'g');
        result = result.replace(regex, item[prop] || '');
      });
      return result;
    }).join('');
  });
  
  // Handle regular placeholders: {{key}}
  Object.keys(data).forEach(key => {
    // Skip arrays and objects for regular placeholders
    if (typeof data[key] === 'object') return;
    
    const regex = new RegExp(`{{${key}}}`, 'g');
    template = template.replace(regex, data[key]);
  });
  
  return template;
};

/**
 * Load and process an email template
 * @param {string} templateName - Name of the template file (without extension)
 * @param {Object} placeholders - Data to replace in the template
 * @returns {string} Processed HTML content
 */
const loadTemplate = async (templateName, placeholders = {}) => {
  try {
    const templatePath = path.join(__dirname, '..', 'templates', 'email', `${templateName}.html`);
    let htmlContent = await fs.readFile(templatePath, 'utf8');
    
    // Process template with placeholders
    htmlContent = processTemplate(htmlContent, placeholders);
    
    return htmlContent;
  } catch (error) {
    throw new Error(`Failed to load template '${templateName}': ${error.message}`);
  }
};

/**
 * Send an email using a template
 * @param {Object} options - Email options
 * @param {string} options.email - Recipient email address
 * @param {string} options.subject - Email subject
 * @param {string} options.template - Template name (without extension)
 * @param {Object} options.placeholders - Data to replace in the template
 * @param {string} [options.message] - Plain text message (fallback)
 * @returns {Promise} Promise that resolves when email is sent
 */
const sendTemplateEmail = async (options) => {
  const {
    email,
    subject,
    template,
    placeholders = {},
    message = ''
  } = options;

  // Create transporter
  const transporter = createTransporter();

  // Load and process template
  const htmlContent = await loadTemplate(template, placeholders);

  // Define email options
  const mailOptions = {
    from: 'Smart Safe <noreply@smartsafe.com>',
    to: email,
    subject: subject,
    text: message,
    html: htmlContent
  };

  // Send email
  return await transporter.sendMail(mailOptions);
};

/**
 * Send a generic email (without template)
 * @param {Object} options - Email options
 * @param {string} options.email - Recipient email address
 * @param {string} options.subject - Email subject
 * @param {string} options.message - Email message (plain text or HTML)
 * @param {boolean} [options.isHTML=false] - Whether the message is HTML
 * @returns {Promise} Promise that resolves when email is sent
 */
const sendGenericEmail = async (options) => {
  const {
    email,
    subject,
    message,
    isHTML = false
  } = options;

  // Create transporter
  const transporter = createTransporter();

  // Define email options
  const mailOptions = {
    from: 'Smart Safe <noreply@smartsafe.com>',
    to: email,
    subject: subject,
    [isHTML ? 'html' : 'text']: message
  };

  // Send email
  return await transporter.sendMail(mailOptions);
};

module.exports = {
  sendTemplateEmail,
  sendGenericEmail,
  loadTemplate
};