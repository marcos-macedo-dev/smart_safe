const { Sos, User, Delegacia, Media, sequelize } = require('../models');
const { Op } = require('sequelize');

// Obter estatísticas da delegacia do usuário logado
exports.getDelegaciaStats = async (req, res) => {
  try {
    // Verificar se o usuário é uma autoridade (Agente ou Unidade)
    if (!req.user || !['Agente', 'Unidade'].includes(req.user.role) || !req.user.delegacia_id) {
      return res.status(403).json({ error: 'Acesso negado. Apenas autoridades podem acessar estas estatísticas.' });
    }

    const delegaciaId = req.user.delegacia_id;

    // Obter informações básicas da delegacia
    const delegacia = await Delegacia.findByPk(delegaciaId);
    if (!delegacia) {
      return res.status(404).json({ error: 'Delegacia não encontrada.' });
    }

    // Contagens gerais da delegacia
    const totalSos = await Sos.count({ where: { delegacia_id: delegaciaId } });
    const closedSos = await Sos.count({ where: { delegacia_id: delegaciaId, status: 'fechado' } });
    const pendingSos = await Sos.count({ where: { delegacia_id: delegaciaId, status: 'pendente' } });
    const activeSos = await Sos.count({ where: { delegacia_id: delegaciaId, status: 'ativo' } });
    const waitingSos = await Sos.count({ where: { delegacia_id: delegaciaId, status: 'aguardando_autoridade' } });
    
    // Calcular taxa de resolução
    const resolutionRate = totalSos > 0 ? Math.round((closedSos / totalSos) * 100) : 0;

    // Obter últimos SOS da delegacia
    const latestSos = await Sos.findAll({
      where: { delegacia_id: delegaciaId },
      include: [
        { model: User, as: 'usuario', attributes: ['nome_completo', 'telefone'] }
      ],
      order: [['createdAt', 'DESC']],
      limit: 5
    });

    // Estatísticas por status
    const statusCounts = await Sos.findAll({
      attributes: [
        'status',
        [sequelize.fn('COUNT', sequelize.col('status')), 'count']
      ],
      where: { delegacia_id: delegaciaId },
      group: ['status']
    });

    const byStatus = {};
    statusCounts.forEach(item => {
      byStatus[item.status] = parseInt(item.get('count'));
    });

    // Estatísticas por período (últimos 7 dias)
    const now = new Date();
    const last7Days = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    
    const sosLast7Days = await Sos.count({ 
      where: { 
        delegacia_id: delegaciaId,
        createdAt: { [Op.gte]: last7Days } 
      } 
    });

    // Tempo médio de resposta (diferença entre criação e fechamento)
    const closedSosWithTime = await Sos.findAll({
      attributes: [
        'id',
        'createdAt',
        'encerrado_em',
        [sequelize.literal('TIMESTAMPDIFF(MINUTE, createdAt, encerrado_em)'), 'responseTime']
      ],
      where: {
        delegacia_id: delegaciaId,
        encerrado_em: { [Op.not]: null }
      }
    });

    const validResponseTimes = closedSosWithTime
      .map(sos => sos.get('responseTime'))
      .filter(time => time !== null && time >= 0);

    const avgResponseTime = validResponseTimes.length > 0 
      ? Math.round(validResponseTimes.reduce((sum, time) => sum + time, 0) / validResponseTimes.length)
      : 0;

    // Estatísticas de mídia
    const sosWithMediaCount = await Sos.count({
      where: { 
        delegacia_id: delegaciaId,
        [Op.or]: [
          { caminho_video: { [Op.not]: null } },
          { caminho_audio: { [Op.not]: null } }
        ]
      }
    });

    const mediaPercentage = totalSos > 0 ? Math.round((sosWithMediaCount / totalSos) * 100) : 0;

    // Retornar todas as estatísticas
    return res.status(200).json({
      delegacia: {
        id: delegacia.id,
        nome: delegacia.nome,
        endereco: delegacia.endereco,
        telefone: delegacia.telefone
      },
      overview: {
        totalSos,
        closedSos,
        pendingSos,
        activeSos,
        waitingSos,
        resolutionRate,
        sosLast7Days,
        avgResponseTime,
        mediaPercentage
      },
      byStatus,
      latestSos
    });
  } catch (error) {
    console.error('Erro ao buscar estatísticas da delegacia:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas da delegacia.' });
  }
};

// Obter estatísticas de SOS por hora do dia para a delegacia
exports.getDelegaciaSosByHour = async (req, res) => {
  try {
    if (!req.user || !['Agente', 'Unidade'].includes(req.user.role) || !req.user.delegacia_id) {
      return res.status(403).json({ error: 'Acesso negado.' });
    }

    const delegaciaId = req.user.delegacia_id;

    // Obter contagem de SOS por hora do dia
    const hourlyCounts = await Sos.findAll({
      attributes: [
        [sequelize.fn('HOUR', sequelize.col('createdAt')), 'hour'],
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: { 
        delegacia_id: delegaciaId,
        createdAt: {
          [Op.gte]: new Date(new Date() - 30 * 24 * 60 * 60 * 1000) // Últimos 30 dias
        }
      },
      group: [sequelize.fn('HOUR', sequelize.col('createdAt'))],
      order: [sequelize.fn('HOUR', sequelize.col('createdAt'))]
    });

    // Converter para array
    const byHour = {};
    for (let i = 0; i < 24; i++) {
      byHour[i] = 0;
    }

    hourlyCounts.forEach(item => {
      byHour[item.get('hour')] = parseInt(item.get('count'));
    });

    return res.status(200).json(byHour);
  } catch (error) {
    console.error('Erro ao buscar estatísticas de SOS por hora:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas de SOS por hora.' });
  }
};

// Obter estatísticas de SOS por dia da semana para a delegacia
exports.getDelegaciaSosByDayOfWeek = async (req, res) => {
  try {
    if (!req.user || !['Agente', 'Unidade'].includes(req.user.role) || !req.user.delegacia_id) {
      return res.status(403).json({ error: 'Acesso negado.' });
    }

    const delegaciaId = req.user.delegacia_id;

    // Obter contagem de SOS por dia da semana
    const dailyCounts = await Sos.findAll({
      attributes: [
        [sequelize.fn('DAYOFWEEK', sequelize.col('createdAt')), 'dayOfWeek'],
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: { 
        delegacia_id: delegaciaId,
        createdAt: {
          [Op.gte]: new Date(new Date() - 30 * 24 * 60 * 60 * 1000) // Últimos 30 dias
        }
      },
      group: [sequelize.fn('DAYOFWEEK', sequelize.col('createdAt'))],
      order: [sequelize.fn('DAYOFWEEK', sequelize.col('createdAt'))]
    });

    // Converter para array (1 = Domingo, 2 = Segunda, ..., 7 = Sábado)
    const byDayOfWeek = {};
    for (let i = 1; i <= 7; i++) {
      byDayOfWeek[i] = 0;
    }

    dailyCounts.forEach(item => {
      byDayOfWeek[item.get('dayOfWeek')] = parseInt(item.get('count'));
    });

    // Converter para nomes dos dias
    const dayNames = {
      1: 'Domingo',
      2: 'Segunda',
      3: 'Terça',
      4: 'Quarta',
      5: 'Quinta',
      6: 'Sexta',
      7: 'Sábado'
    };

    const result = {};
    Object.keys(byDayOfWeek).forEach(key => {
      result[dayNames[key]] = byDayOfWeek[key];
    });

    return res.status(200).json(result);
  } catch (error) {
    console.error('Erro ao buscar estatísticas de SOS por dia da semana:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas de SOS por dia da semana.' });
  }
};

// Obter estatísticas demográficas dos usuários da delegacia
exports.getDelegaciaUserDemographics = async (req, res) => {
  try {
    if (!req.user || !['Agente', 'Unidade'].includes(req.user.role) || !req.user.delegacia_id) {
      return res.status(403).json({ error: 'Acesso negado.' });
    }

    const delegaciaId = req.user.delegacia_id;

    // Obter IDs dos usuários que fizeram SOS para esta delegacia
    const userSos = await Sos.findAll({
      attributes: ['usuario_id'],
      where: { delegacia_id: delegaciaId },
      group: ['usuario_id']
    });

    const userIds = userSos.map(sos => sos.usuario_id);

    if (userIds.length === 0) {
      return res.status(200).json({
        byGender: {},
        byRace: {},
        byState: {}
      });
    }

    // Obter usuários com base nos IDs
    const users = await User.findAll({
      attributes: ['genero', 'cor', 'estado'],
      where: { id: { [Op.in]: userIds } }
    });

    // Contar por gênero
    const byGender = {};
    users.forEach(user => {
      const gender = user.genero || 'Não informado';
      byGender[gender] = (byGender[gender] || 0) + 1;
    });

    // Contar por cor/raça
    const byRace = {};
    users.forEach(user => {
      const race = user.cor || 'Não informado';
      byRace[race] = (byRace[race] || 0) + 1;
    });

    // Contar por estado
    const byState = {};
    users.forEach(user => {
      const state = user.estado || 'Não informado';
      byState[state] = (byState[state] || 0) + 1;
    });

    return res.status(200).json({
      byGender,
      byRace,
      byState
    });
  } catch (error) {
    console.error('Erro ao buscar estatísticas demográficas:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas demográficas.' });
  }
};

// Obter estatísticas de localização geográfica para a delegacia
exports.getDelegaciaLocationStats = async (req, res) => {
  try {
    if (!req.user || !['Agente', 'Unidade'].includes(req.user.role) || !req.user.delegacia_id) {
      return res.status(403).json({ error: 'Acesso negado.' });
    }

    const delegaciaId = req.user.delegacia_id;

    // Obter SOS com coordenadas válidas
    const sosWithLocation = await Sos.findAll({
      attributes: ['latitude', 'longitude'],
      where: {
        delegacia_id: delegaciaId,
        latitude: { [Op.not]: null },
        longitude: { [Op.not]: null }
      }
    });

    // Obter SOS sem localização
    const sosWithoutLocation = await Sos.count({
      where: {
        delegacia_id: delegaciaId,
        [Op.or]: [
          { latitude: null },
          { longitude: null }
        ]
      }
    });

    // Total de SOS
    const totalSos = await Sos.count({ where: { delegacia_id: delegaciaId } });

    // Porcentagem de SOS sem localização
    const percentageWithoutLocation = totalSos > 0 ? Math.round((sosWithoutLocation / totalSos) * 100) : 0;

    return res.status(200).json({
      geographicData: sosWithLocation.map(sos => ({
        latitude: parseFloat(sos.latitude),
        longitude: parseFloat(sos.longitude)
      })),
      sosWithoutLocation,
      totalSos,
      percentageWithoutLocation
    });
  } catch (error) {
    console.error('Erro ao buscar estatísticas de localização:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar estatísticas de localização.' });
  }
};