const { Sos, User, Delegacia } = require('../models');
const logAudit = require('../utils/auditLogger');
const { findDelegaciaForLocation } = require('../utils/roteamento');

// Criar um novo registro de SOS
exports.createSos = async (req, res) => {
  try {
    // Garante que o usuario_id seja pego do token, e não do body, por segurança.
    const usuarioId = req.user ? req.user.id : req.body.usuario_id;
    if (!usuarioId) {
      return res.status(400).json({ error: 'usuario_id é obrigatório.' });
    }

    const sosData = { ...req.body, usuario_id: usuarioId };

    const sos = await Sos.create(sosData);

    // Roteamento da delegacia
    const delegaciaId = await findDelegaciaForLocation(sos.latitude, sos.longitude);
    if (delegaciaId) {
      await sos.update({ delegacia_id: delegaciaId });
    }

    // Carregar o SOS completo com relacionamentos
    const sosCompleto = await Sos.findByPk(sos.id, {
      include: [
        { model: User, as: 'usuario' },
        { model: Delegacia, as: 'delegacia' }
      ]
    });

    // Notifica a sala específica da delegacia
    if (delegaciaId) {
      req.io.to(`delegacia_${delegaciaId}`).emit('novo_sos', sosCompleto.toJSON());
    } else {
      // Notifica uma sala geral de 'admin' se nenhuma delegacia for encontrada
      req.io.to('admin_geral').emit('novo_sos_nao_roteado', sosCompleto.toJSON());
    }
    
    // Notifica todos os clientes conectados (para atualização em tempo real)
    req.io.emit('novo_sos_global', sosCompleto.toJSON());

    await logAudit(usuarioId, 'CREATE', 'sos', sos.id, sosCompleto.toJSON());
    return res.status(201).json(sosCompleto);
  } catch (error) {
    console.error('Erro ao criar registro de SOS:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao criar registro de SOS.' });
  }
};

// Obter todos os registros de SOS
exports.getAllSos = async (req, res) => {
  try {
    const whereClause = {};

    // Se o usuário for uma autoridade, filtre pela sua delegacia
    if (req.user && req.user.tipo === 'autoridade') {
      whereClause.delegacia_id = req.user.delegacia_id;
    } 
    // Opcional: se for um usuário normal, pode ver apenas os seus próprios SOS
    else if (req.user && req.user.tipo === 'user') {
      whereClause.usuario_id = req.user.id;
    }

    const allSos = await Sos.findAll({ 
      where: whereClause,
      include: [
        { model: User, as: 'usuario', attributes: ['nome_completo', 'telefone'] },
        { model: Delegacia, as: 'delegacia' }
      ],
      order: [['createdAt', 'DESC']]
    });

    return res.status(200).json(allSos);
  } catch (error) {
    console.error('Erro ao buscar registros de SOS:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar registros de SOS.' });
  }
};

// Obter um registro de SOS por ID
exports.getSosById = async (req, res) => {
  try {
    const sos = await Sos.findByPk(req.params.id, {
      include: [
        { model: User, as: 'usuario' },
        { model: Delegacia, as: 'delegacia' }
      ]
    });

    if (!sos) {
      return res.status(404).json({ error: 'Registro de SOS não encontrado.' });
    }

    // Validação de segurança: uma autoridade só pode ver detalhes de um SOS da sua delegacia
    if (req.user && req.user.tipo === 'autoridade' && sos.delegacia_id !== req.user.delegacia_id) {
      return res.status(403).json({ error: 'Acesso negado. Este chamado pertence a outra jurisdição.' });
    }

    return res.status(200).json(sos);
  } catch (error) {
    console.error('Erro ao buscar registro de SOS por ID:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao buscar registro de SOS.' });
  }
};

// Atualizar um registro de SOS por ID
exports.updateSos = async (req, res) => {
  try {
    const sos = await Sos.findByPk(req.params.id);
    if (!sos) {
      return res.status(404).json({ error: 'Registro de SOS não encontrado para atualização.' });
    }

    // Validação de segurança
    if (req.user && req.user.tipo === 'autoridade' && sos.delegacia_id !== req.user.delegacia_id) {
      return res.status(403).json({ error: 'Acesso negado. Você não pode atualizar um chamado de outra jurisdição.' });
    }

    const [updated] = await Sos.update(req.body, {
      where: { id: req.params.id }
    });

    if (updated) {
      const updatedSos = await Sos.findByPk(req.params.id, {
        include: [
          { model: User, as: 'usuario' },
          { model: Delegacia, as: 'delegacia' }
        ]
      });
      // Verificar se req.user existe antes de usar
      if (req.user) {
        await logAudit(req.user.id, 'UPDATE', 'sos', updatedSos.id, { newData: updatedSos.toJSON() });
      }

      // Notifica a delegacia sobre a atualização
      if (updatedSos.delegacia_id) {
        req.io.to(`delegacia_${updatedSos.delegacia_id}`).emit('update_sos', updatedSos.toJSON());
      }

      return res.status(200).json(updatedSos);
    }
    // Este return pode não ser alcançado devido ao findByPk acima, mas é um fallback.
    return res.status(404).json({ error: 'Registro de SOS não encontrado para atualização.' });
  } catch (error) {
    console.error('Erro ao atualizar registro de SOS:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao atualizar registro de SOS.' });
  }
};

// Deletar um registro de SOS por ID
exports.deleteSos = async (req, res) => {
  try {
    // Adicionar validação de segurança semelhante ao update se necessário
    const deleted = await Sos.destroy({
      where: { id: req.params.id }
    });
    if (deleted) {
      // Verificar se req.user existe antes de usar
      if (req.user) {
        await logAudit(req.user.id, 'DELETE', 'sos', req.params.id, { message: 'Registro de SOS deletado' });
      }
      // Notificar sobre deleção se necessário
      return res.status(204).send();
    }
    return res.status(404).json({ error: 'Registro de SOS não encontrado para exclusão.' });
  } catch (error) {
    console.error('Erro ao deletar registro de SOS:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao deletar registro de SOS.' });
  }
};
