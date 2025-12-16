const { Sos, User, Delegacia, Autoridade } = require('../models');
const logAudit = require('../utils/auditLogger');
const { findDelegaciaForLocation } = require('../utils/roteamento');
const DispatchService = require('../services/dispatchService');

// ==========================================
// Controller Methods
// ==========================================

module.exports = {
  /**
   * Cria um novo registro de SOS e inicia o despacho
   */
  async createSos(req, res) {
    try {
      const usuarioId = req.user ? req.user.id : req.body.usuario_id;
      
      if (!usuarioId) {
        return res.status(400).json({ error: 'usuario_id é obrigatório.' });
      }

      // Criação inicial (não permitir id vindo do cliente para evitar duplicidade)
      const { id, ...rest } = req.body;
      const sosData = { ...rest, usuario_id: usuarioId };
      const sos = await Sos.create(sosData);

      // Roteamento Automático
      const delegaciaId = await findDelegaciaForLocation(sos.latitude, sos.longitude);
      
      if (delegaciaId) {
        await sos.update({ delegacia_id: delegaciaId });
      }

      // Recarrega SOS completo para broadcast
      let sosCompleto = await Sos.findByPk(sos.id, {
        include: [
          { model: User, as: 'usuario' },
          { model: Delegacia, as: 'delegacia' }
        ]
      });

      // Lógica de Despacho e Notificação
      if (delegaciaId) {
        // Notifica Sala da Delegacia
        req.io.to(`delegacia_${delegaciaId}`).emit('novo_sos', sosCompleto.toJSON());

        // Atribuição Automática de Agente via Service
        const nearestAgente = await DispatchService.findBestAgentForSos(delegaciaId, sos.latitude, sos.longitude);
        
        if (nearestAgente) {
          await sos.update({
            status: 'aguardando_autoridade',
            autoridade_id: nearestAgente.id
          });

          // Recarrega com dados do agente
          const updatedSos = await Sos.findByPk(sos.id, {
            include: [
              { model: User, as: 'usuario' },
              { model: Delegacia, as: 'delegacia' },
              { model: Autoridade, as: 'autoridade' }
            ]
          });

          // Notifica Agente Específico
          req.io.to(`autoridade_${nearestAgente.id}`).emit('nova_atribuicao_sos', updatedSos.toJSON());

          // Atualiza objeto em memória para resposta final
          sosCompleto = updatedSos;
        }
      } else {
        // Fallback: Admin Geral
        req.io.to('admin_geral').emit('novo_sos_nao_roteado', sosCompleto.toJSON());
      }
      
      // Broadcast Global (Dashboard Geral)
      req.io.emit('novo_sos_global', sosCompleto.toJSON());

      await logAudit(usuarioId, 'CREATE', 'sos', sos.id, sosCompleto.toJSON());
      
      return res.status(201).json(sosCompleto);

    } catch (error) {
      console.error('Erro em createSos:', error);
      return res.status(500).json({ error: 'Erro interno ao processar SOS.' });
    }
  },

  /**
   * Lista todos os SOS (filtrado por permissão)
   */
  async getAllSos(req, res) {
    try {
      const whereClause = {};

      // Filtros de Segurança
      if (req.user) {
        if (req.user.tipo === 'autoridade') {
          whereClause.delegacia_id = req.user.delegacia_id;
        } else if (req.user.tipo === 'user') {
          whereClause.usuario_id = req.user.id;
        }
      }

      const allSos = await Sos.findAll({
        where: whereClause,
        include: [
          { model: User, as: 'usuario', attributes: ['nome_completo', 'telefone'] },
          { model: Delegacia, as: 'delegacia' },
          { model: Autoridade, as: 'autoridade', attributes: ['id', 'nome', 'cargo'] }
        ],
        order: [['createdAt', 'DESC']]
      });

      return res.json(allSos);

    } catch (error) {
      console.error('Erro em getAllSos:', error);
      return res.status(500).json({ error: 'Erro interno ao listar SOS.' });
    }
  },

  /**
   * Busca detalhe de um SOS
   */
  async getSosById(req, res) {
    try {
      const { id } = req.params;
      const sos = await Sos.findByPk(id, {
        include: [
          { model: User, as: 'usuario' },
          { model: Delegacia, as: 'delegacia' },
          { model: Autoridade, as: 'autoridade', attributes: ['id', 'nome', 'cargo'] }
        ]
      });

      if (!sos) {
        return res.status(404).json({ error: 'SOS não encontrado.' });
      }

      // Validação de Jurisdição
      if (req.user && req.user.tipo === 'autoridade' && sos.delegacia_id !== req.user.delegacia_id) {
        return res.status(403).json({ error: 'Acesso negado: Jurisdição incorreta.' });
      }

      return res.json(sos);

    } catch (error) {
      console.error('Erro em getSosById:', error);
      return res.status(500).json({ error: 'Erro interno ao buscar detalhes do SOS.' });
    }
  },

  /**
   * Atualiza status ou dados de um SOS
   */
  async updateSos(req, res) {
    try {
      const { id } = req.params;
      const sos = await Sos.findByPk(id);

      if (!sos) {
        return res.status(404).json({ error: 'SOS não encontrado.' });
      }

      // Validação de Jurisdição
      if (req.user && req.user.tipo === 'autoridade' && sos.delegacia_id !== req.user.delegacia_id) {
        return res.status(403).json({ error: 'Acesso negado: Jurisdição incorreta.' });
      }

      // Snapshot para log
      const oldData = sos.toJSON();

      await sos.update(req.body);

      // Recarrega para devolver completo
      const updatedSos = await Sos.findByPk(id, {
        include: [
          { model: User, as: 'usuario' },
          { model: Delegacia, as: 'delegacia' },
          { model: Autoridade, as: 'autoridade', attributes: ['id', 'nome', 'cargo'] }
        ]
      });

      if (req.user) {
        await logAudit(req.user.id, 'UPDATE', 'sos', updatedSos.id, { 
          oldData, 
          newData: updatedSos.toJSON() 
        });
      }

      // Notificações Real-Time
      if (updatedSos.delegacia_id) {
        req.io.to(`delegacia_${updatedSos.delegacia_id}`).emit('update_sos', updatedSos.toJSON());
      }
      
      // Se houve atribuição de autoridade, notifica a autoridade também
      if (updatedSos.autoridade_id && updatedSos.autoridade_id !== oldData.autoridade_id) {
         req.io.to(`autoridade_${updatedSos.autoridade_id}`).emit('nova_atribuicao_sos', updatedSos.toJSON());
      }

      return res.json(updatedSos);

    } catch (error) {
      console.error('Erro em updateSos:', error);
      return res.status(500).json({ error: 'Erro interno ao atualizar SOS.' });
    }
  },

  /**
   * Remove um SOS (Geralmente soft-delete ou restrito a admin)
   */
  async deleteSos(req, res) {
    try {
      const { id } = req.params;
      
      // TODO: Adicionar checagem de permissão extra aqui (apenas Admin Geral?)
      
      const deleted = await Sos.destroy({ where: { id } });

      if (deleted) {
        if (req.user) {
          await logAudit(req.user.id, 'DELETE', 'sos', id, { message: 'SOS deletado permanentemente' });
        }
        return res.status(204).send();
      }

      return res.status(404).json({ error: 'SOS não encontrado.' });

    } catch (error) {
      console.error('Erro em deleteSos:', error);
      return res.status(500).json({ error: 'Erro interno ao deletar SOS.' });
    }
  }
};