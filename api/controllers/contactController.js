const { Contact } = require('../models');
const logAudit = require('../utils/auditLogger');

// Criar um novo contato de emergência
exports.createContact = async (req, res) => {
  try {
    const contact = await Contact.create(req.body);
    await logAudit(req.user ? req.user.id : null, 'CREATE', 'contato_emergencia', contact.id, contact.toJSON());
    return res.status(201).json(contact);
  } catch (error) {
    console.error('Erro ao criar contato de emergência:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao criar contato de emergência.' });
  }
};

// Obter todos os contatos de emergência (opcionalmente por usuario_id)
exports.getAllContacts = async (req, res) => {
  try {
    const query = {};
    if (req.query.usuario_id) {
      query.usuario_id = req.query.usuario_id;
    }
    const contacts = await Contact.findAll({ where: query });
    // logAudit(req.user ? req.user.id : null, 'ACCESS', 'contato_emergencia', null, { action: 'getAllContacts' }); // ACCESS logs can be noisy, consider middleware
    return res.status(200).json(contacts);
  } catch (error) {
    console.error('Erro ao buscar contatos de emergência:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar contatos de emergência.' });
  }
};

// Obter um contato de emergência por ID
exports.getContactById = async (req, res) => {
  try {
    const contact = await Contact.findByPk(req.params.id);
    if (!contact) {
      return res.status(404).json({ error: 'Contato de emergência não encontrado.' });
    }
    // logAudit(req.user ? req.user.id : null, 'ACCESS', 'contato_emergencia', contact.id, { action: 'getContactById' }); // ACCESS logs can be noisy, consider middleware
    return res.status(200).json(contact);
  } catch (error) {
    console.error('Erro ao buscar contato de emergência por ID:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar contato de emergência.' });
  }
};

// Atualizar um contato de emergência por ID
exports.updateContact = async (req, res) => {
  try {
    const [updated] = await Contact.update(req.body, {
      where: { id: req.params.id }
    });
    if (updated) {
      const updatedContact = await Contact.findByPk(req.params.id);
      await logAudit(req.user ? req.user.id : null, 'UPDATE', 'contato_emergencia', updatedContact.id, { oldData: req.originalBody, newData: updatedContact.toJSON() }); // Assuming req.originalBody exists from a middleware
      return res.status(200).json(updatedContact);
    }
    return res.status(404).json({ error: 'Contato de emergência não encontrado para atualização.' });
  } catch (error) {
    console.error('Erro ao atualizar contato de emergência:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao atualizar contato de emergência.' });
  }
};

// Deletar um contato de emergência por ID
exports.deleteContact = async (req, res) => {
  try {
    const deleted = await Contact.destroy({
      where: { id: req.params.id }
    });
    if (deleted) {
      await logAudit(req.user ? req.user.id : null, 'DELETE', 'contato_emergencia', req.params.id, { message: 'Contato de emergência deletado' });
      return res.status(204).send(); // No Content
    }
    return res.status(404).json({ error: 'Contato de emergência não encontrado para exclusão.' });
  } catch (error) {
    console.error('Erro ao deletar contato de emergência:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao deletar contato de emergência.' });
  }
};
