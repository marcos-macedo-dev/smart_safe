const { AuditLog } = require('../models');

const logAudit = async (ator_id, acao, tipo_alvo, id_alvo, detalhes = {}) => {
  try {
    // Use 0 as default ator_id if not provided (e.g., for unauthenticated actions)
    const final_ator_id = ator_id || 0;

    await AuditLog.create({
      ator_id: final_ator_id,
      acao,
      tipo_alvo,
      id_alvo,
      detalhes,
    });
  } catch (error) {
    console.error('Erro ao registrar log de auditoria:', error);
  }
};

module.exports = logAudit;
