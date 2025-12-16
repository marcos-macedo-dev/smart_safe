const bcrypt = require('bcryptjs');
const { User } = require('../models');
const logAudit = require('../utils/auditLogger');
const { excludePassword } = require('../utils/responseHelpers');

// ==========================================
// Controller Methods
// ==========================================

module.exports = {
  /**
   * Cria um novo usuário (Cidadão)
   */
  async createUser(req, res) {
    try {
      let { senha, email, genero, ...userData } = req.body;

      // Sanitização básica
      if (!senha || !email) {
        return res.status(400).json({ error: 'Email e senha são obrigatórios.' });
      }
      
      senha = senha.trim();
      email = email.trim();

      // Verificar se email já existe (opcional, pois o banco já trava, mas melhora a UX)
      const existingUser = await User.findOne({ where: { email } });
      if (existingUser) {
        return res.status(409).json({ error: 'Email já cadastrado.' });
      }

      const hashedPassword = await bcrypt.hash(senha, 10);
      
      const user = await User.create({ 
        ...userData, 
        email, 
        genero, 
        senha: hashedPassword 
      });

      await logAudit(req.user?.id || null, 'CREATE', 'usuario', user.id, excludePassword(user));
      
      return res.status(201).json(excludePassword(user));

    } catch (error) {
      console.error('Erro em createUser:', error);
      return res.status(500).json({ error: 'Erro interno ao criar usuário.' });
    }
  },

  /**
   * Lista todos os usuários
   */
  async getAllUsers(req, res) {
    try {
      const users = await User.findAll();
      return res.json(excludePassword(users)); // Helper agora suporta arrays!
    } catch (error) {
      console.error('Erro em getAllUsers:', error);
      return res.status(500).json({ error: 'Erro interno ao buscar usuários.' });
    }
  },

  /**
   * Busca usuário por ID
   */
  async getUserById(req, res) {
    try {
      const { id } = req.params;
      const user = await User.findByPk(id);

      if (!user) {
        return res.status(404).json({ error: 'Usuário não encontrado.' });
      }

      return res.json(excludePassword(user));
    } catch (error) {
      console.error('Erro em getUserById:', error);
      return res.status(500).json({ error: 'Erro interno ao buscar usuário.' });
    }
  },

  /**
   * Atualiza dados do usuário
   */
  async updateUser(req, res) {
    try {
      const { id } = req.params;
      let { senha, email, ...updateData } = req.body;

      const user = await User.findByPk(id);
      if (!user) {
        return res.status(404).json({ error: 'Usuário não encontrado.' });
      }

      // Preparar dados para atualização
      if (senha) {
        updateData.senha = await bcrypt.hash(senha.trim(), 10);
      }
      if (email) {
        updateData.email = email.trim();
      }

      // Snapshot para auditoria
      const oldData = user.toJSON();

      await user.update(updateData);

      await logAudit(req.user?.id || null, 'UPDATE', 'usuario', user.id, { 
        oldData: excludePassword({ ...oldData }), 
        newData: excludePassword(user) 
      });

      return res.json(excludePassword(user));

    } catch (error) {
      console.error('Erro em updateUser:', error);
      return res.status(500).json({ error: 'Erro interno ao atualizar usuário.' });
    }
  },

  /**
   * Remove um usuário
   */
  async deleteUser(req, res) {
    try {
      const { id } = req.params;
      
      const user = await User.findByPk(id);
      if (!user) {
        return res.status(404).json({ error: 'Usuário não encontrado.' });
      }

      await user.destroy();
      
      await logAudit(req.user?.id || null, 'DELETE', 'usuario', id, { message: 'Usuário deletado' });

      return res.status(204).send();

    } catch (error) {
      console.error('Erro em deleteUser:', error);
      return res.status(500).json({ error: 'Erro interno ao deletar usuário.' });
    }
  },

  /**
   * Retorna o usuário logado (perfil)
   */
  async getLoggedInUser(req, res) {
    // req.user já vem populado pelo middleware de auth, mas geralmente sem detalhes atualizados do banco
    // É uma boa prática buscar do banco novamente para garantir status atual
    try {
      if (!req.user || !req.user.id) {
        return res.status(401).json({ error: 'Usuário não autenticado.' });
      }

      const user = await User.findByPk(req.user.id);
      if (!user) {
        return res.status(404).json({ error: 'Usuário não encontrado.' });
      }

      return res.json(excludePassword(user));
    } catch (error) {
      console.error('Erro em getLoggedInUser:', error);
      return res.status(500).json({ error: 'Erro interno ao buscar perfil.' });
    }
  }
};
