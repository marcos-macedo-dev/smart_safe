const { AuditLog } = require('../models');

// Criar um novo registro de auditoria
exports.createAuditLog = async (req, res) => {
  try {
    const auditLog = await AuditLog.create(req.body);
    return res.status(201).json(auditLog);
  } catch (error) {
    console.error('Erro ao criar registro de auditoria:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao criar registro de auditoria.' });
  }
};

// Obter todos os registros de auditoria (opcionalmente por ator_id)
exports.getAllAuditLogs = async (req, res) => {
  try {
    const query = {};
    if (req.query.ator_id) {
      query.ator_id = req.query.ator_id;
    }
    const allAuditLogs = await AuditLog.findAll({ where: query });
    return res.status(200).json(allAuditLogs);
  } catch (error) {
    console.error('Erro ao buscar registros de auditoria:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar registros de auditoria.' });
  }
};

// Obter um registro de auditoria por ID
exports.getAuditLogById = async (req, res) => {
  try {
    const auditLog = await AuditLog.findByPk(req.params.id);
    if (!auditLog) {
      return res.status(404).json({ error: 'Registro de auditoria não encontrado.' });
    }
    return res.status(200).json(auditLog);
  } catch (error) {
    console.error('Erro ao buscar registro de auditoria por ID:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar registro de auditoria.' });
  }
};

// Atualizar um registro de auditoria por ID
exports.updateAuditLog = async (req, res) => {
  try {
    const [updated] = await AuditLog.update(req.body, {
      where: { id: req.params.id }
    });
    if (updated) {
      const updatedAuditLog = await AuditLog.findByPk(req.params.id);
      return res.status(200).json(updatedAuditLog);
    }
    return res.status(404).json({ error: 'Registro de auditoria não encontrado para atualização.' });
  } catch (error) {
    console.error('Erro ao atualizar registro de auditoria:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao atualizar registro de auditoria.' });
  }
};

// Deletar um registro de auditoria por ID
exports.deleteAuditLog = async (req, res) => {
  try {
    const deleted = await AuditLog.destroy({
      where: { id: req.params.id }
    });
    if (deleted) {
      return res.status(204).send(); // No Content
    }
    return res.status(404).json({ error: 'Registro de auditoria não encontrado para exclusão.' });
  } catch (error) {
    console.error('Erro ao deletar registro de auditoria:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao deletar registro de auditoria.' });
  }
};
