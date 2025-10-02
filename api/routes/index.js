const express = require('express');
const router = express.Router();

// Importar todas as rotas
const authRoutes = require('./authRoutes');
const userRoutes = require('./userRoutes');
const sosRoutes = require('./sosRoutes');
const reportRoutes = require('./reportRoutes');
const contactRoutes = require('./contactRoutes');
const mediaRoutes = require('./mediaRoutes');
const delegaciaRoutes = require('./delegaciaRoutes');
const autoridadeRoutes = require('./autoridadeRoutes');
const delegaciaUserRoutes = require('./delegaciaUserRoutes');
const delegaciaCoberturaRoutes = require('./delegaciaCoberturaRoutes');
const delegaciaRegisterRoutes = require('./delegaciaRegisterRoutes');
const inviteRoutes = require('./inviteRoutes');
const rastreamentoApurosRoutes = require('./rastreamentoApurosRoutes');
const emailRoutes = require('./emailRoutes');
const testEmailRoutes = require('./testEmailRoutes');
const uploadRoutes = require('./uploadRoutes');
const incidentLocationRoutes = require('./incidentLocationRoutes');
const delegaciaStatsRoutes = require('./delegaciaStatsRoutes');

// Usar todas as rotas
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/sos', sosRoutes);
router.use('/reports', reportRoutes);
router.use('/contacts', contactRoutes);
router.use('/media', mediaRoutes);
router.use('/delegacias', delegaciaRoutes);
router.use('/autoridades', autoridadeRoutes);
router.use('/delegacia-users', delegaciaUserRoutes);
router.use('/delegacia-cobertura', delegaciaCoberturaRoutes);
router.use('/delegacias-register', delegaciaRegisterRoutes);
router.use('/invites', inviteRoutes);
router.use('/rastreamento-apuros', rastreamentoApurosRoutes);
router.use('/email', emailRoutes);
router.use('/test-email', testEmailRoutes);
router.use('/upload', uploadRoutes);
router.use('/incident-locations', incidentLocationRoutes);
router.use('/delegacia-stats', delegaciaStatsRoutes);

module.exports = router;
