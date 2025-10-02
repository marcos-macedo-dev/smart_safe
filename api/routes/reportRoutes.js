const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Aplicar middleware de autenticação a todas as rotas
router.use(authMiddleware);

// Rotas para relatórios
router.get('/overview', reportController.getSystemOverview);
router.get('/sos-stats', reportController.getSosStats);
router.get('/user-stats', reportController.getUserStats);
router.get('/top-delegacias', reportController.getTopDelegacias);
router.get('/monthly-stats', reportController.getMonthlyStats);
router.get('/media-stats', reportController.getMediaStats);
router.get('/user-demographics', reportController.getUserDemographics);
router.get('/sos-location-stats', reportController.getSosLocationStats);
router.get('/sos-geographic-distribution', reportController.getSosGeographicDistribution);
router.get('/sos-response-stats', reportController.getSosResponseStats);
router.get('/media-stats-by-type', reportController.getMediaStatsByType);
router.get('/sos-by-hour', reportController.getSosByHour);

module.exports = router;