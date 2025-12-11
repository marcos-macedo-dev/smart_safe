const { Autoridade, Delegacia } = require('../models');

// Listar todos os usuários da delegacia da unidade
exports.getUsersByDelegacia = async (req, res) => {
  try {
    const delegacia_id = req.user.delegacia_id;
    
    // Buscar a delegacia para confirmar que existe
    const delegacia = await Delegacia.findByPk(delegacia_id);
    if (!delegacia) {
      return res.status(404).json({ error: 'Delegacia não encontrada.' });
    }
    
    // Buscar todos os usuários (autoridades) da delegacia
    const usuarios = await Autoridade.findAll({
      where: { delegacia_id },
      attributes: { exclude: ['senha', 'inviteToken', 'inviteExpires'] },
      order: [['createdAt', 'DESC']]
    });
    
    res.status(200).json(usuarios);
  } catch (error) {
    console.error('Erro ao buscar usuários da delegacia:', error);
    res.status(500).json({ error: 'Erro interno do servidor.' });
  }
};

// Buscar um usuário específico da delegacia
exports.getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    const delegacia_id = req.user.delegacia_id;
    
    const usuario = await Autoridade.findOne({
      where: { id, delegacia_id },
      attributes: { exclude: ['senha', 'inviteToken', 'inviteExpires'] }
    });
    
    if (!usuario) {
      return res.status(404).json({ error: 'Usuário não encontrado nesta delegacia.' });
    }
    
    res.status(200).json(usuario);
  } catch (error) {
    console.error('Erro ao buscar usuário:', error);
    res.status(500).json({ error: 'Erro interno do servidor.' });
  }
};

// Atualizar um usuário da delegacia
exports.updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { nome, email, cargo, ativo } = req.body;
    const delegacia_id = req.user.delegacia_id;
    
    const usuario = await Autoridade.findOne({ 
      where: { id, delegacia_id } 
    });
    
    if (!usuario) {
      return res.status(404).json({ error: 'Usuário não encontrado nesta delegacia.' });
    }
    
    // Não permitir que um usuário altere seu próprio cargo de Unidade para Agente
    if (usuario.id === req.user.id && usuario.cargo === 'Unidade' && cargo === 'Agente') {
      return res.status(403).json({ error: 'Você não pode remover seus próprios privilégios de unidade.' });
    }
    
    // Atualizar campos
    usuario.nome = nome ?? usuario.nome;
    usuario.email = email ?? usuario.email;
    usuario.cargo = cargo ?? usuario.cargo;
    usuario.ativo = ativo !== undefined ? ativo : usuario.ativo;
    
    await usuario.save();
    
    const { senha: _, inviteToken: __, inviteExpires: ___, ...usuarioSemDadosSensiveis } = usuario.toJSON();
    res.status(200).json(usuarioSemDadosSensiveis);
  } catch (error) {
    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'Este email já está em uso.' });
    }
    console.error('Erro ao atualizar usuário:', error);
    res.status(500).json({ error: 'Erro interno do servidor.' });
  }
};

// Desativar um usuário (em vez de deletar)
exports.deactivateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const delegacia_id = req.user.delegacia_id;
    
    const usuario = await Autoridade.findOne({ 
      where: { id, delegacia_id } 
    });
    
    if (!usuario) {
      return res.status(404).json({ error: 'Usuário não encontrado nesta delegacia.' });
    }
    
    // Não permitir que um usuário desative a si mesmo
    if (usuario.id === req.user.id) {
      return res.status(403).json({ error: 'Você não pode desativar sua própria conta.' });
    }
    
    usuario.ativo = false;
    await usuario.save();
    
    const { senha: _, inviteToken: __, inviteExpires: ___ } = usuario.toJSON();
    res.status(200).json({ 
      ...usuario.toJSON(), 
      senha: undefined, 
      inviteToken: undefined, 
      inviteExpires: undefined,
      message: 'Usuário desativado com sucesso.' 
    });
  } catch (error) {
    console.error('Erro ao desativar usuário:', error);
    res.status(500).json({ error: 'Erro interno do servidor.' });
  }
};

// Reativar um usuário
exports.reactivateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const delegacia_id = req.user.delegacia_id;
    
    const usuario = await Autoridade.findOne({ 
      where: { id, delegacia_id } 
    });
    
    if (!usuario) {
      return res.status(404).json({ error: 'Usuário não encontrado nesta delegacia.' });
    }
    
    usuario.ativo = true;
    await usuario.save();
    
    const { senha: _, inviteToken: __, inviteExpires: ___ } = usuario.toJSON();
    res.status(200).json({ 
      ...usuario.toJSON(), 
      senha: undefined, 
      inviteToken: undefined, 
      inviteExpires: undefined,
      message: 'Usuário reativado com sucesso.' 
    });
  } catch (error) {
    console.error('Erro ao reativar usuário:', error);
    res.status(500).json({ error: 'Erro interno do servidor.' });
  }
};