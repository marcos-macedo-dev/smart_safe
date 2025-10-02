const express = require('express');
const router = express.Router();
const contactController = require('../controllers/contactController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Rotas para contatos de emergência
router.post('/', authMiddleware, contactController.createContact);
router.get('/', authMiddleware, contactController.getAllContacts);
router.get('/:id', authMiddleware, contactController.getContactById);
router.put('/:id', authMiddleware, contactController.updateContact);
router.delete('/:id', authMiddleware, contactController.deleteContact);

module.exports = router;
