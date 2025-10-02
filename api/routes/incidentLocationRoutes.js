const express = require('express');
const router = express.Router();
const incidentLocationController = require('../controllers/incidentLocationController');

// Rotas para Localizações de Incidente
router.post('/', incidentLocationController.createIncidentLocation);
router.get('/', incidentLocationController.getAllIncidentLocations);
router.get('/:id', incidentLocationController.getIncidentLocationById);
router.put('/:id', incidentLocationController.updateIncidentLocation);
router.delete('/:id', incidentLocationController.deleteIncidentLocation);

module.exports = router;
