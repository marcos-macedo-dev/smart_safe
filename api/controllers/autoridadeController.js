const bcrypt = require('bcryptjs');
const { Autoridade, Delegacia } = require('../models');
const { excludePassword } = require('../utils/responseHelpers');

module.exports = {
  /**
   * Cria uma nova autoridade (Agente/Delegado)
   * Restrito: Apenas Unidades (via middleware)
   */
  async createAutoridade(req, res) {
    try {
      let { nome, email, senha, cargo } = req.body;
      const delegacia_id = req.user.delegacia_id;

      if (!nome || !email || !senha || !cargo) {
        return res.status(400).json({ error: 'Todos os campos são obrigatórios.' });
      }

      // Sanitização
      nome = nome.trim();
      email = email.trim();
      senha = senha.trim();

      const hashedPassword = await bcrypt.hash(senha, 10);

      const novaAutoridade = await Autoridade.create({
        nome,
        email,
        senha: hashedPassword,
        cargo,
        delegacia_id
      });

      return res.status(201).json(excludePassword(novaAutoridade));

    } catch (error) {
      if (error.name === 'SequelizeUniqueConstraintError') {
        return res.status(409).json({ error: 'Este email já está em uso.' });
      }
      console.error('Erro em createAutoridade:', error);
      return res.status(500).json({ error: 'Erro interno ao criar autoridade.' });
    }
  },

  /**
   * Obtém o perfil da autoridade logada
   */
  async getLoggedInAutoridade(req, res) {
    try {
      const autoridade = await Autoridade.findByPk(req.user.id, {
        attributes: { exclude: ['senha'] },
        include: [{
          model: Delegacia,
          as: 'delegacia',
          attributes: ['id', 'nome', 'endereco', 'telefone']
        }]
      });
      
      if (!autoridade) {
        return res.status(404).json({ error: 'Autoridade não encontrada.' });
      }
      
      return res.json(autoridade);

    } catch (error) {
      console.error('Erro em getLoggedInAutoridade:', error);
      return res.status(500).json({ error: 'Erro interno ao buscar perfil.' });
    }
  },

  /**
   * Atualiza o perfil da autoridade logada
   */
  async updateLoggedInAutoridade(req, res) {
    try {
      let { nome, email, senha } = req.body;
      const autoridade = await Autoridade.findByPk(req.user.id);

      if (!autoridade) {
        return res.status(404).json({ error: 'Autoridade não encontrada.' });
      }

      // Atualizações com sanitização
      if (nome) autoridade.nome = nome.trim();
      if (email) autoridade.email = email.trim();

      if (senha) {
        autoridade.senha = await bcrypt.hash(senha.trim(), 10);
      }

      await autoridade.save();

      return res.json(excludePassword(autoridade));

    } catch (error) {
      console.error('Erro em updateLoggedInAutoridade:', error);
      return res.status(500).json({ error: 'Erro interno ao atualizar perfil.' });
    }
  },

  /**
   * Lista autoridades de uma delegacia específica
   * Restrito: Apenas Unidades
   */
  async getAutoridadesByDelegacia(req, res) {
    try {
      const delegacia_id = req.user.delegacia_id;
      
      const autoridades = await Autoridade.findAll({
        where: { delegacia_id },
        attributes: { exclude: ['senha'] }
      });

      return res.json(autoridades);

    } catch (error) {
      console.error('Erro em getAutoridadesByDelegacia:', error);
      return res.status(500).json({ error: 'Erro interno ao listar autoridades.' });
    }
  },

  /**
   * Atualiza uma autoridade específica da delegacia
   * Restrito: Apenas Unidades (Admin local)
   */
  async updateAutoridade(req, res) {
    try {
      const { id } = req.params;
      let { nome, email, cargo, ativo } = req.body;
      const delegacia_id = req.user.delegacia_id;

      const autoridade = await Autoridade.findOne({ where: { id, delegacia_id } });

      if (!autoridade) {
        return res.status(404).json({ error: 'Autoridade não encontrada nesta delegacia.' });
      }

      if (nome) autoridade.nome = nome.trim();
      if (email) autoridade.email = email.trim();
      if (cargo) autoridade.cargo = cargo;
      if (ativo !== undefined) autoridade.ativo = ativo;

      await autoridade.save();

      return res.json(excludePassword(autoridade));

    } catch (error) {
      console.error('Erro em updateAutoridade:', error);
      return res.status(500).json({ error: 'Erro interno ao atualizar autoridade.' });
    }
  },

  /**
   * Remove uma autoridade da delegacia
   * Restrito: Apenas Unidades
   */
  async deleteAutoridade(req, res) {
    try {
      const { id } = req.params;
      const delegacia_id = req.user.delegacia_id;

      const deleted = await Autoridade.destroy({
        where: { id, delegacia_id }
      });

      if (deleted) {
        return res.status(204).send();
      }

      return res.status(404).json({ error: 'Autoridade não encontrada nesta delegacia.' });

    } catch (error) {
      console.error('Erro em deleteAutoridade:', error);
      return res.status(500).json({ error: 'Erro interno ao deletar autoridade.' });
    }
  }
};