
const bcrypt = require('bcryptjs');
const { Autoridade, Delegacia } = require('../models');

// Apenas Unidades podem criar novas autoridades para sua própria delegacia
exports.createAutoridade = async (req, res) => {
  try {
    const { nome, email, senha, cargo } = req.body;
    const delegacia_id = req.user.delegacia_id; // Pega o ID da delegacia do token da unidade

    // Criptografa a senha
    const hashedPassword = await bcrypt.hash(senha, 10);

    const novaAutoridade = await Autoridade.create({
      nome,
      email,
      senha: hashedPassword,
      cargo,
      delegacia_id
    });

    // Não retorna a senha
    const { senha: _, ...autoridadeSemSenha } = novaAutoridade.toJSON();

    res.status(201).json(autoridadeSemSenha);
  } catch (error) {
    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'Este email já está em uso.' });
    }
    console.error('Erro ao criar autoridade:', error);
    res.status(500).json({ error: 'Erro interno do servidor.' });
  }
};


// Obter perfil da autoridade logada
exports.getLoggedInAutoridade = async (req, res) => {
  try {
    const autoridade = await Autoridade.findByPk(req.user.id, {
      attributes: { exclude: ['senha'] }, // Exclui o campo senha
      include: [{
        model: Delegacia,
        as: 'delegacia',
        attributes: ['id', 'nome', 'endereco', 'telefone']
      }]
    });
    
    if (!autoridade) {
      return res.status(404).json({ error: 'Autoridade não encontrada.' });
    }
    
    res.status(200).json(autoridade);
  } catch (error) {
    console.error('Erro ao buscar autoridade:', error);
    res.status(500).json({ error: 'Erro interno do servidor.' });
  }
};

// Atualizar perfil da autoridade logada
exports.updateLoggedInAutoridade = async (req, res) => {
  try {
    const { nome, email, senha } = req.body;
    const autoridade = await Autoridade.findByPk(req.user.id);

    if (!autoridade) {
      return res.status(404).json({ error: 'Autoridade não encontrada.' });
    }

    // Atualiza os campos
    autoridade.nome = nome ?? autoridade.nome;
    autoridade.email = email ?? autoridade.email;

    // Atualiza a senha se fornecida
    if (senha) {
      const hashedPassword = await bcrypt.hash(senha, 10);
      autoridade.senha = hashedPassword;
    }

    await autoridade.save();

    const { senha: _, ...autoridadeSemSenha } = autoridade.toJSON();
    res.status(200).json(autoridadeSemSenha);
  } catch (error) {
    console.error('Erro ao atualizar autoridade:', error);
    res.status(500).json({ error: 'Erro interno do servidor.' });
  }
};

// Apenas Unidades podem listar autoridades da sua delegacia
exports.getAutoridadesByDelegacia = async (req, res) => {
  try {
    const delegacia_id = req.user.delegacia_id;
    const autoridades = await Autoridade.findAll({
      where: { delegacia_id },
      attributes: { exclude: ['senha'] } // Exclui o campo senha
    });
    res.status(200).json(autoridades);
  } catch (error) {
    console.error('Erro ao buscar autoridades:', error);
    res.status(500).json({ error: 'Erro interno do servidor.' });
  }
};

// Apenas Unidades podem atualizar uma autoridade da sua delegacia
exports.updateAutoridade = async (req, res) => {
  try {
    const { id } = req.params;
    const { nome, email, cargo, ativo } = req.body;
    const delegacia_id = req.user.delegacia_id;

    const autoridade = await Autoridade.findOne({ where: { id, delegacia_id } });

    if (!autoridade) {
      return res.status(404).json({ error: 'Autoridade não encontrada nesta delegacia.' });
    }

    // Atualiza os campos
    autoridade.nome = nome ?? autoridade.nome;
    autoridade.email = email ?? autoridade.email;
    autoridade.cargo = cargo ?? autoridade.cargo;
    autoridade.ativo = ativo ?? autoridade.ativo;

    await autoridade.save();

    const { senha: _, ...autoridadeSemSenha } = autoridade.toJSON();
    res.status(200).json(autoridadeSemSenha);
  } catch (error) {
    console.error('Erro ao atualizar autoridade:', error);
    res.status(500).json({ error: 'Erro interno do servidor.' });
  }
};

// Apenas Unidades podem deletar uma autoridade da sua delegacia
exports.deleteAutoridade = async (req, res) => {
  try {
    const { id } = req.params;
    const delegacia_id = req.user.delegacia_id;

    const deleted = await Autoridade.destroy({
      where: { id, delegacia_id }
    });

    if (deleted) {
      return res.status(204).send();
    }

    return res.status(404).json({ error: 'Autoridade não encontrada para exclusão nesta delegacia.' });
  } catch (error) {
    console.error('Erro ao deletar autoridade:', error);
    res.status(500).json({ error: 'Erro interno do servidor.' });
  }
};
