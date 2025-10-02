const express = require('express');
const router = express.Router();
const delegaciaStatsController = require('../controllers/delegaciaStatsController');
const { authMiddleware } = require('../middlewares/authMiddleware');

// Aplicar middleware de autenticação a todas as rotas
router.use(authMiddleware);

// Rotas para estatísticas da delegacia
router.get('/stats', delegaciaStatsController.getDelegaciaStats);
router.get('/sos-by-hour', delegaciaStatsController.getDelegaciaSosByHour);
router.get('/sos-by-day-of-week', delegaciaStatsController.getDelegaciaSosByDayOfWeek);
router.get('/user-demographics', delegaciaStatsController.getDelegaciaUserDemographics);
router.get('/location-stats', delegaciaStatsController.getDelegaciaLocationStats);

module.exports = router;