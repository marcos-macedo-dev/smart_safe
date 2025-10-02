const { IncidentLocation } = require('../models');
const logAudit = require('../utils/auditLogger');

// Criar um novo registro de localização de incidente
exports.createIncidentLocation = async (req, res) => {
  try {
    const incidentLocation = await IncidentLocation.create(req.body);
    await logAudit(req.user ? req.user.id : null, 'CREATE', 'localizacao_incidente', incidentLocation.id, incidentLocation.toJSON());
    return res.status(201).json(incidentLocation);
  } catch (error) {
    console.error('Erro ao criar registro de localização de incidente:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao criar registro de localização de incidente.' });
  }
};

// Obter todos os registros de localização de incidente (opcionalmente por sos_id)
exports.getAllIncidentLocations = async (req, res) => {
  try {
    const query = {};
    if (req.query.sos_id) {
      query.sos_id = req.query.sos_id;
    }
    const allIncidentLocations = await IncidentLocation.findAll({ where: query });
    // logAudit(req.user ? req.user.id : null, 'ACCESS', 'localizacao_incidente', null, { action: 'getAllIncidentLocations' }); // ACCESS logs can be noisy, consider middleware
    return res.status(200).json(allIncidentLocations);
  } catch (error) {
    console.error('Erro ao buscar registros de localização de incidente:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar registros de localização de incidente.' });
  }
};

// Obter um registro de localização de incidente por ID
exports.getIncidentLocationById = async (req, res) => {
  try {
    const incidentLocation = await IncidentLocation.findByPk(req.params.id);
    if (!incidentLocation) {
      return res.status(404).json({ error: 'Registro de localização de incidente não encontrado.' });
    }
    // logAudit(req.user ? req.user.id : null, 'ACCESS', 'localizacao_incidente', incidentLocation.id, { action: 'getIncidentLocationById' }); // ACCESS logs can be noisy, consider middleware
    return res.status(200).json(incidentLocation);
  } catch (error) {
    console.error('Erro ao buscar registro de localização de incidente por ID:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar registro de localização de incidente.' });
  }
};

// Atualizar um registro de localização de incidente por ID
exports.updateIncidentLocation = async (req, res) => {
  try {
    const [updated] = await IncidentLocation.update(req.body, {
      where: { id: req.params.id }
    });
    if (updated) {
      const updatedIncidentLocation = await IncidentLocation.findByPk(req.params.id);
      await logAudit(req.user ? req.user.id : null, 'UPDATE', 'localizacao_incidente', updatedIncidentLocation.id, { oldData: req.originalBody, newData: updatedIncidentLocation.toJSON() }); // Assuming req.originalBody exists from a middleware
      return res.status(200).json(updatedIncidentLocation);
    }
    return res.status(404).json({ error: 'Registro de localização de incidente não encontrado para atualização.' });
  } catch (error) {
    console.error('Erro ao atualizar registro de localização de incidente:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao atualizar registro de localização de incidente.' });
  }
};

// Deletar um registro de localização de incidente por ID
exports.deleteIncidentLocation = async (req, res) => {
  try {
    const deleted = await IncidentLocation.destroy({
      where: { id: req.params.id }
    });
    if (deleted) {
      await logAudit(req.user ? req.user.id : null, 'DELETE', 'localizacao_incidente', req.params.id, { message: 'Registro de localização de incidente deletado' });
      return res.status(204).send(); // No Content
    }
    return res.status(404).json({ error: 'Registro de localização de incidente não encontrado para exclusão.' });
  } catch (error) {
    console.error('Erro ao deletar registro de localização de incidente:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao deletar registro de localização de incidente.' });
  }
};
