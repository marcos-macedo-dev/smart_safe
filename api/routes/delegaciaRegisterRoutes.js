const express = require('express');
const router = express.Router();
const delegaciaRegisterController = require('../controllers/delegaciaRegisterController');

// Endpoint para buscar dados reais da solicitação de registro de delegacia pelo token
router.get('/pending', delegaciaRegisterController.getPendingDelegaciaRegistration);

// Endpoint público para solicitação de registro de delegacia
router.post('/register', delegaciaRegisterController.registerDelegacia);

// Endpoint para aprovar o registro (pode ser protegido posteriormente)
router.post('/approve', delegaciaRegisterController.approveDelegaciaRegistration);

// Endpoint para rejeitar o registro (pode ser protegido posteriormente)
router.post('/reject', delegaciaRegisterController.rejectDelegaciaRegistration);

module.exports = router;