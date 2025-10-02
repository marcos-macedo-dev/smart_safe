const { User } = require('../models');
const bcrypt = require('bcryptjs');
const logAudit = require('../utils/auditLogger');

// Função auxiliar para remover a senha do objeto do usuário
const excludePassword = (user) => {
  const { senha, ...rest } = user.toJSON();
  return rest;
};

// Criar um novo usuário
exports.createUser = async (req, res) => {
  try {
    const { senha, genero, ...userData } = req.body;

    const hashedPassword = await bcrypt.hash(senha, 10); // Hash da senha
    const user = await User.create({ ...userData, genero, senha: hashedPassword });
    await logAudit(req.user ? req.user.id : null, 'CREATE', 'usuario', user.id, user.toJSON());
    return res.status(201).json(excludePassword(user));
  } catch (error) {
    console.error('Erro ao criar usuário:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao criar usuário.' });
  }
};

// Obter todos os usuários
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.findAll();
    // logAudit(req.user ? req.user.id : null, 'ACCESS', 'usuario', null, { action: 'getAllUsers' }); // ACCESS logs can be noisy, consider middleware
    return res.status(200).json(users.map(excludePassword));
  } catch (error) {
    console.error('Erro ao buscar usuários:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar usuários.' });
  }
};

// Obter um usuário por ID
exports.getUserById = async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) {
      return res.status(404).json({ error: 'Usuário não encontrado.' });
    }
    // logAudit(req.user ? req.user.id : null, 'ACCESS', 'usuario', user.id, { action: 'getUserById' }); // ACCESS logs can be noisy, consider middleware
    return res.status(200).json(excludePassword(user));
  } catch (error) {
    console.error('Erro ao buscar usuário por ID:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar usuário.' });
  }
};

// Atualizar um usuário por ID
exports.updateUser = async (req, res) => {
  try {
    const { senha, genero, ...userData } = req.body;

    let updateData = { ...userData, genero };

    if (senha) {
      updateData.senha = await bcrypt.hash(senha, 10);
    }

    const [updated] = await User.update(updateData, {
      where: { id: req.params.id }
    });

    if (updated) {
      const updatedUser = await User.findByPk(req.params.id);
      await logAudit(req.user ? req.user.id : null, 'UPDATE', 'usuario', updatedUser.id, { oldData: req.originalBody, newData: updatedUser.toJSON() }); // Assuming req.originalBody exists from a middleware
      return res.status(200).json(excludePassword(updatedUser));
    }
    return res.status(404).json({ error: 'Usuário não encontrado para atualização.' });
  } catch (error) {
    console.error('Erro ao atualizar usuário:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao atualizar usuário.' });
  }
};

// Deletar um usuário por ID
exports.deleteUser = async (req, res) => {
  try {
    const deleted = await User.destroy({
      where: { id: req.params.id }
    });
    if (deleted) {
      await logAudit(req.user ? req.user.id : null, 'DELETE', 'usuario', req.params.id, { message: 'Usuário deletado' });
      return res.status(204).send(); // No Content
    }
    return res.status(404).json({ error: 'Usuário não encontrado para exclusão.' });
  } catch (error) {
    console.error('Erro ao deletar usuário:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao deletar usuário.' });
  }
};

exports.getLoggedInUser = async (req, res) => {
  res.json(req.user);
};