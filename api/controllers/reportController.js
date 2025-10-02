const { Sos, User, Delegacia, Media, sequelize } = require('../models');
const { Op } = require('sequelize');

// Obter visão geral do sistema
exports.getSystemOverview = async (req, res) => {
  try {
    // Contagens gerais
    const totalSos = await Sos.count();
    const closedSos = await Sos.count({ where: { status: 'fechado' } });
    const totalUsers = await User.count();
    const totalDelegacias = await Delegacia.count();
    
    // Retornar dados da visão geral
    return res.status(200).json({
      totalSos,
      closedSos,
      totalUsers,
      totalDelegacias
    });
  } catch (error) {
    console.error('Erro ao buscar visão geral do sistema:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar visão geral.' });
  }
};

// Obter estatísticas detalhadas dos SOS
exports.getSosStats = async (req, res) => {
  try {
    const { startDate, endDate, state, status } = req.query;
    
    // Construir where clause com base nos filtros
    const whereClause = {};
    
    if (startDate || endDate) {
      whereClause.createdAt = {};
      if (startDate) {
        whereClause.createdAt[Op.gte] = new Date(startDate);
      }
      if (endDate) {
        whereClause.createdAt[Op.lte] = new Date(endDate);
      }
    }
    
    if (status) {
      whereClause.status = status;
    }
    
    if (state) {
      // Precisamos fazer join com usuarios para filtrar por estado
      whereClause['$usuario.estado$'] = state;
    }
    
    // Buscar dados dos SOS com filtros aplicados
    const sosData = await Sos.findAll({
      where: whereClause,
      include: [
        {
          model: User,
          as: 'usuario',
          attributes: ['id', 'nome_completo', 'estado']
        },
        {
          model: Delegacia,
          as: 'delegacia',
          attributes: ['id', 'nome', 'endereco']
        }
      ],
      order: [['createdAt', 'DESC']]
    });
    
    // Calcular estatísticas
    const totalSos = sosData.length;
    const statusCounts = sosData.reduce((acc, sos) => {
      acc[sos.status] = (acc[sos.status] || 0) + 1;
      return acc;
    }, {});
    
    // Calcular estatísticas por período
    const now = new Date();
    const last24h = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const last7Days = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const last30Days = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    
    const sosLast24h = sosData.filter(sos => new Date(sos.createdAt) >= last24h).length;
    const sosLast7Days = sosData.filter(sos => new Date(sos.createdAt) >= last7Days).length;
    const sosLast30Days = sosData.filter(sos => new Date(sos.createdAt) >= last30Days).length;
    
    return res.status(200).json({
      totalSos,
      byStatus: statusCounts,
      last24h: sosLast24h,
      last7Days: sosLast7Days,
      last30Days: sosLast30Days,
      sosData
    });
  } catch (error) {
    console.error('Erro ao buscar estatísticas dos SOS:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas dos SOS.' });
  }
};

// Obter estatísticas dos usuários
exports.getUserStats = async (req, res) => {
  try {
    // Contagens de usuários
    const totalUsers = await User.count();
    
    // Como não existe uma coluna 'status' na tabela de usuários, vamos contar todos os usuários como ativos
    const activeUsers = totalUsers;
    
    // Novos usuários nos últimos 7 dias
    const now = new Date();
    const last7Days = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    
    const newUsers7Days = await User.count({ 
      where: { 
        createdAt: { [Op.gte]: last7Days } 
      } 
    });
    
    // Retornar estatísticas dos usuários
    return res.status(200).json({
      totalUsers,
      activeUsers,
      newUsers7Days
    });
  } catch (error) {
    console.error('Erro ao buscar estatísticas dos usuários:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas dos usuários.' });
  }
};

// Obter delegacias com mais SOS
exports.getTopDelegacias = async (req, res) => {
  try {
    const topDelegacias = await Sos.findAll({
      attributes: [
        'delegacia_id',
        [sequelize.fn('COUNT', sequelize.col('Sos.delegacia_id')), 'sosCount'],
        [sequelize.fn('MAX', sequelize.col('Sos.createdAt')), 'lastSos']
      ],
      include: [{
        model: Delegacia,
        as: 'delegacia',
        attributes: ['nome']
      }],
      group: ['delegacia_id', 'delegacia.id'],
      order: [[sequelize.fn('COUNT', sequelize.col('Sos.delegacia_id')), 'DESC']],
      limit: 5
    });
    
    // Converter para formato adequado
    const result = topDelegacias.map(item => ({
      id: item.delegacia_id,
      nome: item.delegacia ? item.delegacia.nome : 'Não roteado',
      sosCount: parseInt(item.get('sosCount')),
      lastSos: item.get('lastSos')
    }));
    
    return res.status(200).json(result);
  } catch (error) {
    console.error('Erro ao buscar delegacias com mais SOS:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar delegacias com mais SOS.' });
  }
};

// Obter estatísticas mensais dos SOS
exports.getMonthlyStats = async (req, res) => {
  try {
    // Obter contagem de SOS por mês
    const monthlyCounts = await Sos.findAll({
      attributes: [
        [sequelize.fn('YEAR', sequelize.col('createdAt')), 'year'],
        [sequelize.fn('MONTH', sequelize.col('createdAt')), 'month'],
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      group: [
        sequelize.fn('YEAR', sequelize.col('createdAt')),
        sequelize.fn('MONTH', sequelize.col('createdAt'))
      ],
      order: [
        [sequelize.fn('YEAR', sequelize.col('createdAt')), 'ASC'],
        [sequelize.fn('MONTH', sequelize.col('createdAt')), 'ASC']
      ]
    });
    
    // Converter para array com nomes de meses
    const monthlyStats = monthlyCounts.map(item => {
      const year = item.get('year');
      const month = item.get('month');
      const date = new Date(year, month - 1, 1);
      const monthName = date.toLocaleString('pt-BR', { month: 'short' });
      
      return {
        month: monthName,
        year: year,
        count: parseInt(item.get('count'))
      };
    });
    
    return res.status(200).json(monthlyStats);
  } catch (error) {
    console.error('Erro ao buscar estatísticas mensais:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas mensais.' });
  }
};

// Obter estatísticas de mídia dos SOS
exports.getMediaStats = async (req, res) => {
  try {
    // Contagem de mídias por tipo
    const mediaCounts = await Media.findAll({
      attributes: [
        'tipo',
        [sequelize.fn('COUNT', sequelize.col('tipo')), 'count']
      ],
      group: ['tipo']
    });
    
    // Converter para objeto
    const byType = {};
    mediaCounts.forEach(item => {
      byType[item.tipo] = parseInt(item.get('count'));
    });
    
    // Total de SOS com mídia
    const sosWithMedia = await Media.count({
      distinct: true,
      col: 'sos_id'
    });
    
    // Total de SOS
    const totalSos = await Sos.count();
    
    // Porcentagem de SOS com mídia
    const percentageWithMedia = totalSos > 0 ? Math.round((sosWithMedia / totalSos) * 100) : 0;
    
    return res.status(200).json({
      byType,
      sosWithMedia,
      totalSos,
      percentageWithMedia
    });
  } catch (error) {
    console.error('Erro ao buscar estatísticas de mídia:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas de mídia.' });
  }
};

// Obter informações demográficas dos usuários
exports.getUserDemographics = async (req, res) => {
  try {
    // Contagem por gênero
    const genderCounts = await User.findAll({
      attributes: [
        'genero',
        [sequelize.fn('COUNT', sequelize.col('genero')), 'count']
      ],
      group: ['genero']
    });
    
    // Converter para objeto
    const byGender = {};
    genderCounts.forEach(item => {
      byGender[item.genero] = parseInt(item.get('count'));
    });
    
    // Contagem por cor/raça
    const raceCounts = await User.findAll({
      attributes: [
        'cor',
        [sequelize.fn('COUNT', sequelize.col('cor')), 'count']
      ],
      group: ['cor']
    });
    
    // Converter para objeto
    const byRace = {};
    raceCounts.forEach(item => {
      byRace[item.cor] = parseInt(item.get('count'));
    });
    
    return res.status(200).json({
      byGender,
      byRace
    });
  } catch (error) {
    console.error('Erro ao buscar informações demográficas dos usuários:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar informações demográficas dos usuários.' });
  }
};

// Obter estatísticas de localização dos SOS
exports.getSosLocationStats = async (req, res) => {
  try {
    // Contagem de SOS por estado
    const stateCounts = await Sos.findAll({
      attributes: [
        [sequelize.fn('COUNT', sequelize.col('Sos.id')), 'count']
      ],
      include: [{
        model: User,
        as: 'usuario',
        attributes: ['estado'],
        required: true // INNER JOIN para garantir que só contamos SOS com usuários válidos
      }],
      group: ['usuario.estado'],
      order: [[sequelize.fn('COUNT', sequelize.col('Sos.id')), 'DESC']],
      raw: true // Evita problemas com colunas não agregadas
    });
    
    // Converter para array
    const byState = stateCounts.map(item => ({
      estado: item['usuario.estado'] || 'Não identificado',
      count: parseInt(item.count)
    }));
    
    // SOS sem localização
    const sosWithoutLocation = await Sos.count({
      where: {
        [Op.or]: [
          { latitude: null },
          { longitude: null }
        ]
      }
    });
    
    // Total de SOS
    const totalSos = await Sos.count();
    
    // Porcentagem de SOS sem localização
    const percentageWithoutLocation = totalSos > 0 ? Math.round((sosWithoutLocation / totalSos) * 100) : 0;
    
    return res.status(200).json({
      byState,
      sosWithoutLocation,
      totalSos,
      percentageWithoutLocation
    });
  } catch (error) {
    console.error('Erro ao buscar estatísticas de localização dos SOS:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas de localização dos SOS.' });
  }
};

// Obter distribuição geográfica dos SOS (para mapa de calor)
exports.getSosGeographicDistribution = async (req, res) => {
  try {
    // Obter SOS com coordenadas válidas
    const sosWithLocation = await Sos.findAll({
      attributes: [
        'latitude',
        'longitude',
        'createdAt'
      ],
      include: [{
        model: User,
        as: 'usuario',
        attributes: ['estado', 'cidade'],
        required: true
      }],
      where: {
        latitude: {
          [Op.not]: null
        },
        longitude: {
          [Op.not]: null
        }
      },
      raw: true // Evita problemas com colunas não agregadas
    });
    
    // Formatar dados para mapa de calor
    const geographicData = sosWithLocation.map(sos => ({
      latitude: parseFloat(sos.latitude),
      longitude: parseFloat(sos.longitude),
      estado: sos['usuario.estado'] || null,
      cidade: sos['usuario.cidade'] || null,
      timestamp: sos.createdAt
    }));
    
    return res.status(200).json(geographicData);
  } catch (error) {
    console.error('Erro ao buscar distribuição geográfica dos SOS:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar distribuição geográfica dos SOS.' });
  }
};

// Obter estatísticas de tempo de resposta dos SOS
exports.getSosResponseStats = async (req, res) => {
  try {
    // Calcular tempo médio de resposta (diferença entre createdAt e encerrado_em)
    const sosWithResponseTime = await Sos.findAll({
      attributes: [
        'id',
        'createdAt',
        'encerrado_em',
        [sequelize.literal('TIMESTAMPDIFF(MINUTE, createdAt, encerrado_em)'), 'responseTime']
      ],
      where: {
        encerrado_em: {
          [Op.not]: null
        }
      }
    });

    // Filtrar apenas os SOS com tempo de resposta válido
    const validResponseTimes = sosWithResponseTime
      .map(sos => sos.get('responseTime'))
      .filter(time => time !== null && time >= 0);

    // Calcular estatísticas
    const totalClosedSos = validResponseTimes.length;
    const avgResponseTime = totalClosedSos > 0 
      ? Math.round(validResponseTimes.reduce((sum, time) => sum + time, 0) / totalClosedSos)
      : 0;

    // Calcular mediana
    const sortedTimes = [...validResponseTimes].sort((a, b) => a - b);
    const medianResponseTime = totalClosedSos > 0
      ? sortedTimes[Math.floor(totalClosedSos / 2)]
      : 0;

    return res.status(200).json({
      avgResponseTime,
      medianResponseTime,
      totalClosedSos
    });
  } catch (error) {
    console.error('Erro ao buscar estatísticas de tempo de resposta:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas de tempo de resposta.' });
  }
};

// Obter estatísticas por tipo de mídia
exports.getMediaStatsByType = async (req, res) => {
  try {
    // Contagem de mídias por tipo
    const mediaCounts = await Media.findAll({
      attributes: [
        'tipo',
        [sequelize.fn('COUNT', sequelize.col('tipo')), 'count']
      ],
      group: ['tipo']
    });

    // Converter para objeto
    const byType = {};
    mediaCounts.forEach(item => {
      byType[item.tipo] = parseInt(item.get('count'));
    });

    // Total de mídias
    const totalMedia = await Media.count();

    return res.status(200).json({
      byType,
      totalMedia
    });
  } catch (error) {
    console.error('Erro ao buscar estatísticas por tipo de mídia:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas por tipo de mídia.' });
  }
};

// Obter estatísticas de SOS por hora do dia
exports.getSosByHour = async (req, res) => {
  try {
    // Obter contagem de SOS por hora do dia
    const hourlyCounts = await Sos.findAll({
      attributes: [
        [sequelize.fn('HOUR', sequelize.col('createdAt')), 'hour'],
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      group: [sequelize.fn('HOUR', sequelize.col('createdAt'))],
      order: [sequelize.fn('HOUR', sequelize.col('createdAt'))]
    });

    // Converter para array
    const byHour = {};
    hourlyCounts.forEach(item => {
      byHour[item.get('hour')] = parseInt(item.get('count'));
    });

    return res.status(200).json(byHour);
  } catch (error) {
    console.error('Erro ao buscar estatísticas de SOS por hora:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas de SOS por hora.' });
  }
};

// Obter estatísticas dos usuários
exports.getUserStats = async (req, res) => {
  try {
    // Contagens de usuários
    const totalUsers = await User.count();
    
    // Como não existe uma coluna 'status' na tabela de usuários, vamos contar todos os usuários como ativos
    const activeUsers = totalUsers;
    
    // Novos usuários nos últimos 7 dias
    const now = new Date();
    const last7Days = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    
    const newUsers7Days = await User.count({ 
      where: { 
        createdAt: { [Op.gte]: last7Days } 
      } 
    });
    
    // Retornar estatísticas dos usuários
    return res.status(200).json({
      totalUsers,
      activeUsers,
      newUsers7Days
    });
  } catch (error) {
    console.error('Erro ao buscar estatísticas dos usuários:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas dos usuários.' });
  }
};

// Obter delegacias com mais SOS
exports.getTopDelegacias = async (req, res) => {
  try {
    const topDelegacias = await Sos.findAll({
      attributes: [
        'delegacia_id',
        [sequelize.fn('COUNT', sequelize.col('Sos.delegacia_id')), 'sosCount'],
        [sequelize.fn('MAX', sequelize.col('Sos.createdAt')), 'lastSos']
      ],
      include: [{
        model: Delegacia,
        as: 'delegacia',
        attributes: ['nome']
      }],
      group: ['delegacia_id', 'delegacia.id'],
      order: [[sequelize.fn('COUNT', sequelize.col('Sos.delegacia_id')), 'DESC']],
      limit: 5
    });
    
    // Converter para formato adequado
    const result = topDelegacias.map(item => ({
      id: item.delegacia_id,
      nome: item.delegacia ? item.delegacia.nome : 'Não roteado',
      sosCount: parseInt(item.get('sosCount')),
      lastSos: item.get('lastSos')
    }));
    
    return res.status(200).json(result);
  } catch (error) {
    console.error('Erro ao buscar delegacias com mais SOS:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar delegacias com mais SOS.' });
  }
};

// Obter estatísticas mensais dos SOS
exports.getMonthlyStats = async (req, res) => {
  try {
    // Obter contagem de SOS por mês
    const monthlyCounts = await Sos.findAll({
      attributes: [
        [sequelize.fn('YEAR', sequelize.col('createdAt')), 'year'],
        [sequelize.fn('MONTH', sequelize.col('createdAt')), 'month'],
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      group: [
        sequelize.fn('YEAR', sequelize.col('createdAt')),
        sequelize.fn('MONTH', sequelize.col('createdAt'))
      ],
      order: [
        [sequelize.fn('YEAR', sequelize.col('createdAt')), 'ASC'],
        [sequelize.fn('MONTH', sequelize.col('createdAt')), 'ASC']
      ]
    });
    
    // Converter para array com nomes de meses
    const monthlyStats = monthlyCounts.map(item => {
      const year = item.get('year');
      const month = item.get('month');
      const date = new Date(year, month - 1, 1);
      const monthName = date.toLocaleString('pt-BR', { month: 'short' });
      
      return {
        month: monthName,
        year: year,
        count: parseInt(item.get('count'))
      };
    });
    
    return res.status(200).json(monthlyStats);
  } catch (error) {
    console.error('Erro ao buscar estatísticas mensais:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas mensais.' });
  }
};

// Obter estatísticas de mídia dos SOS
exports.getMediaStats = async (req, res) => {
  try {
    // Contagem de mídias por tipo
    const mediaCounts = await Media.findAll({
      attributes: [
        'tipo',
        [sequelize.fn('COUNT', sequelize.col('tipo')), 'count']
      ],
      group: ['tipo']
    });
    
    // Converter para objeto
    const byType = {};
    mediaCounts.forEach(item => {
      byType[item.tipo] = parseInt(item.get('count'));
    });
    
    // Total de SOS com mídia
    const sosWithMedia = await Media.count({
      distinct: true,
      col: 'sos_id'
    });
    
    // Total de SOS
    const totalSos = await Sos.count();
    
    // Porcentagem de SOS com mídia
    const percentageWithMedia = totalSos > 0 ? Math.round((sosWithMedia / totalSos) * 100) : 0;
    
    return res.status(200).json({
      byType,
      sosWithMedia,
      totalSos,
      percentageWithMedia
    });
  } catch (error) {
    console.error('Erro ao buscar estatísticas de mídia:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas de mídia.' });
  }
};

// Obter informações demográficas dos usuários
exports.getUserDemographics = async (req, res) => {
  try {
    // Contagem por gênero
    const genderCounts = await User.findAll({
      attributes: [
        'genero',
        [sequelize.fn('COUNT', sequelize.col('genero')), 'count']
      ],
      group: ['genero']
    });
    
    // Converter para objeto
    const byGender = {};
    genderCounts.forEach(item => {
      byGender[item.genero] = parseInt(item.get('count'));
    });
    
    // Contagem por cor/raça
    const raceCounts = await User.findAll({
      attributes: [
        'cor',
        [sequelize.fn('COUNT', sequelize.col('cor')), 'count']
      ],
      group: ['cor']
    });
    
    // Converter para objeto
    const byRace = {};
    raceCounts.forEach(item => {
      byRace[item.cor] = parseInt(item.get('count'));
    });
    
    return res.status(200).json({
      byGender,
      byRace
    });
  } catch (error) {
    console.error('Erro ao buscar informações demográficas dos usuários:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar informações demográficas dos usuários.' });
  }
};

// Obter estatísticas de localização dos SOS
exports.getSosLocationStats = async (req, res) => {
  try {
    // Contagem de SOS por estado
    const stateCounts = await Sos.findAll({
      attributes: [
        [sequelize.fn('COUNT', sequelize.col('Sos.id')), 'count']
      ],
      include: [{
        model: User,
        as: 'usuario',
        attributes: ['estado'],
        required: true // INNER JOIN para garantir que só contamos SOS com usuários válidos
      }],
      group: ['usuario.estado'],
      order: [[sequelize.fn('COUNT', sequelize.col('Sos.id')), 'DESC']],
      raw: true // Evita problemas com colunas não agregadas
    });
    
    // Converter para array
    const byState = stateCounts.map(item => ({
      estado: item['usuario.estado'] || 'Não identificado',
      count: parseInt(item.count)
    }));
    
    // SOS sem localização
    const sosWithoutLocation = await Sos.count({
      where: {
        [Op.or]: [
          { latitude: null },
          { longitude: null }
        ]
      }
    });
    
    // Total de SOS
    const totalSos = await Sos.count();
    
    // Porcentagem de SOS sem localização
    const percentageWithoutLocation = totalSos > 0 ? Math.round((sosWithoutLocation / totalSos) * 100) : 0;
    
    return res.status(200).json({
      byState,
      sosWithoutLocation,
      totalSos,
      percentageWithoutLocation
    });
  } catch (error) {
    console.error('Erro ao buscar estatísticas de localização dos SOS:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas de localização dos SOS.' });
  }
};

// Obter distribuição geográfica dos SOS (para mapa de calor)
exports.getSosGeographicDistribution = async (req, res) => {
  try {
    // Obter SOS com coordenadas válidas
    const sosWithLocation = await Sos.findAll({
      attributes: [
        'latitude',
        'longitude',
        'createdAt'
      ],
      include: [{
        model: User,
        as: 'usuario',
        attributes: ['estado', 'cidade'],
        required: true
      }],
      where: {
        latitude: {
          [Op.not]: null
        },
        longitude: {
          [Op.not]: null
        }
      },
      raw: true // Evita problemas com colunas não agregadas
    });
    
    // Formatar dados para mapa de calor
    const geographicData = sosWithLocation.map(sos => ({
      latitude: parseFloat(sos.latitude),
      longitude: parseFloat(sos.longitude),
      estado: sos['usuario.estado'] || null,
      cidade: sos['usuario.cidade'] || null,
      timestamp: sos.createdAt
    }));
    
    return res.status(200).json(geographicData);
  } catch (error) {
    console.error('Erro ao buscar distribuição geográfica dos SOS:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar distribuição geográfica dos SOS.' });
  }
};

// Obter estatísticas de tempo de resposta dos SOS
exports.getSosResponseStats = async (req, res) => {
  try {
    // Calcular tempo médio de resposta (diferença entre createdAt e encerrado_em)
    const sosWithResponseTime = await Sos.findAll({
      attributes: [
        'id',
        'createdAt',
        'encerrado_em',
        [sequelize.literal('TIMESTAMPDIFF(MINUTE, createdAt, encerrado_em)'), 'responseTime']
      ],
      where: {
        encerrado_em: {
          [Op.not]: null
        }
      }
    });

    // Filtrar apenas os SOS com tempo de resposta válido
    const validResponseTimes = sosWithResponseTime
      .map(sos => sos.get('responseTime'))
      .filter(time => time !== null && time >= 0);

    // Calcular estatísticas
    const totalClosedSos = validResponseTimes.length;
    const avgResponseTime = totalClosedSos > 0 
      ? Math.round(validResponseTimes.reduce((sum, time) => sum + time, 0) / totalClosedSos)
      : 0;

    // Calcular mediana
    const sortedTimes = [...validResponseTimes].sort((a, b) => a - b);
    const medianResponseTime = totalClosedSos > 0
      ? sortedTimes[Math.floor(totalClosedSos / 2)]
      : 0;

    return res.status(200).json({
      avgResponseTime,
      medianResponseTime,
      totalClosedSos
    });
  } catch (error) {
    console.error('Erro ao buscar estatísticas de tempo de resposta:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas de tempo de resposta.' });
  }
};

// Obter estatísticas por tipo de mídia
exports.getMediaStatsByType = async (req, res) => {
  try {
    // Contagem de mídias por tipo
    const mediaCounts = await Media.findAll({
      attributes: [
        'tipo',
        [sequelize.fn('COUNT', sequelize.col('tipo')), 'count']
      ],
      group: ['tipo']
    });

    // Converter para objeto
    const byType = {};
    mediaCounts.forEach(item => {
      byType[item.tipo] = parseInt(item.get('count'));
    });

    // Total de mídias
    const totalMedia = await Media.count();

    return res.status(200).json({
      byType,
      totalMedia
    });
  } catch (error) {
    console.error('Erro ao buscar estatísticas por tipo de mídia:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas por tipo de mídia.' });
  }
};

// Obter estatísticas de SOS por hora do dia
exports.getSosByHour = async (req, res) => {
  try {
    // Obter contagem de SOS por hora do dia
    const hourlyCounts = await Sos.findAll({
      attributes: [
        [sequelize.fn('HOUR', sequelize.col('createdAt')), 'hour'],
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      group: [sequelize.fn('HOUR', sequelize.col('createdAt'))],
      order: [sequelize.fn('HOUR', sequelize.col('createdAt'))]
    });

    // Converter para array
    const byHour = {};
    hourlyCounts.forEach(item => {
      byHour[item.get('hour')] = parseInt(item.get('count'));
    });

    return res.status(200).json(byHour);
  } catch (error) {
    console.error('Erro ao buscar estatísticas de SOS por hora:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas de SOS por hora.' });
  }
};