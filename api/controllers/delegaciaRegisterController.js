// Buscar dados reais da solicitação de registro de delegacia pelo token
exports.getPendingDelegaciaRegistration = async (req, res) => {
  try {
    const {
      token
    } = req.query;
    if (!token) {
      return res.status(400).json({
        error: 'Token não fornecido.'
      });
    }
    const administrador = await Autoridade.findOne({
      where: {
        approvalToken: token,
        approvalExpires: {
          [Op.gt]: new Date()
        },
        pendingApproval: true
      },
      include: [{
        model: Delegacia,
        as: 'delegacia'
      }]
    });
    if (!administrador) {
      return res.status(404).json({
        error: 'Solicitação não encontrada ou expirada.'
      });
    }
    return res.json({
      delegacia_nome: administrador.delegacia?.nome,
      delegacia_endereco: administrador.delegacia?.endereco,
      delegacia_latitude: administrador.delegacia?.latitude,
      delegacia_longitude: administrador.delegacia?.longitude,
      delegacia_telefone: administrador.delegacia?.telefone,
      administrador_nome: administrador.nome,
      administrador_email: administrador.email
    });
  } catch (error) {
    console.error('Erro ao buscar solicitação de registro de delegacia:', error);
    res.status(500).json({
      error: 'Erro ao buscar solicitação de registro de delegacia.'
    });
  }
};
const {
  Delegacia,
  Autoridade
} = require('../models');
const {
  Op
} = require('sequelize');
const {
  sendTemplateEmail
} = require('../utils/emailService');
const crypto = require('crypto');

exports.registerDelegacia = async (req, res) => {
  try {
    console.log('Iniciando solicitação de registro de delegacia:', req.body);
    const {
      delegaciaData,
      administradorData
    } = req.body;

    // Validar dados obrigatórios
    if (!delegaciaData.nome || !delegaciaData.endereco ||
      !administradorData.nome || !administradorData.email) {
      console.log('Dados obrigatórios faltando');
      return res.status(400).json({
        error: 'Dados obrigatórios faltando'
      });
    }

    // Verificar se o email do administrador já existe
    const existingAdmin = await Autoridade.findOne({
      where: {
        email: administradorData.email
      }
    });
    if (existingAdmin) {
      console.log('Email já em uso:', administradorData.email);
      return res.status(409).json({
        error: 'Este email já está em uso'
      });
    }

    // Verificar se a delegacia já existe
    const existingDelegacia = await Delegacia.findOne({
      where: {
        nome: delegaciaData.nome
      }
    });
    if (existingDelegacia) {
      console.log('Delegacia já existe:', delegaciaData.nome);
      return res.status(409).json({
        error: 'Esta delegacia já está registrada'
      });
    }

    // Gerar token de aprovação
    const approvalToken = crypto.randomBytes(32).toString('hex');
    const approvalExpires = new Date(Date.now() + 48 * 60 * 60 * 1000); // 48 horas

    // Salvar solicitação pendente (você pode criar uma tabela para isso ou usar uma abordagem temporária)
    // Por enquanto, vamos criar a delegacia como inativa e o administrador como pendente
    const delegacia = await Delegacia.create({
      ...delegaciaData,
      telefone: delegaciaData.telefone || null,
      ativa: false // Delegacia inativa até aprovação
    });

    // Criar administrador pendente
    const administrador = await Autoridade.create({
      nome: administradorData.nome,
      email: administradorData.email,
      cargo: 'Admin',
      delegacia_id: delegacia.id,
      // Marcar como pendente de aprovação
      senha: null,
      ativo: false,
      pendingApproval: true, // Campo que você pode adicionar ao modelo
      approvalToken: approvalToken,
      approvalExpires: approvalExpires
    });

    // Enviar email para aprovação (para você, administrador master)
    const approveURL = `${process.env.FRONTEND_URL || 'http://localhost:5173'}/approve-delegacia?token=${approvalToken}`;
    const rejectURL = `${process.env.FRONTEND_URL || 'http://localhost:5173'}/reject-delegacia?token=${approvalToken}`;

    try {
      await sendTemplateEmail({
        email: process.env.ADMIN_MASTER_EMAIL || 'marcosmacedo784@gmail.com', // Seu email
        subject: `Solicitação de Registro - ${delegacia.nome} - Smart Safe`,
        template: 'delegacia-approval-request',
        placeholders: {
          delegacia_nome: delegacia.nome,
          administrador_nome: administrador.nome,
          administrador_email: administrador.email,
          delegacia_endereco: delegacia.endereco,
          approve_url: approveURL,
          reject_url: rejectURL
        }
      });

      res.status(201).json({
        message: 'Solicitação de registro enviada para aprovação. Aguarde o email de confirmação.',
        delegacia: {
          id: delegacia.id,
          nome: delegacia.nome
        }
      });
    } catch (emailError) {
      console.error('Erro ao enviar email de aprovação:', emailError);
      // Em caso de erro no email, remover a delegacia e administrador
      await administrador.destroy();
      await delegacia.destroy();
      return res.status(500).json({
        error: 'Erro ao enviar solicitação de aprovação. Tente novamente.'
      });
    }
  } catch (error) {
    console.error('Erro na solicitação de registro de delegacia:', error);
    res.status(500).json({
      error: 'Erro ao processar solicitação de registro'
    });
  }
};

// Nova função para aprovar o registro
exports.approveDelegaciaRegistration = async (req, res) => {
  try {
    const {
      token
    } = req.body;

    // Verificar se o token é válido
    const administrador = await Autoridade.findOne({
      where: {
        approvalToken: token,
        approvalExpires: {
          [Op.gt]: new Date()
        },
        pendingApproval: true
      },
      include: [{
        model: Delegacia,
        as: 'delegacia'
      }]
    });

    if (!administrador) {
      return res.status(400).json({
        error: 'Token de aprovação inválido ou expirado.'
      });
    }

    // Ativar a delegacia
    await administrador.delegacia.update({
      ativa: true
    });

    // Gerar token de convite para o administrador
    const inviteToken = crypto.randomBytes(32).toString('hex');
    const inviteExpires = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 dias

    // Atualizar o administrador com o token de convite
    await administrador.update({
      approvalToken: null,
      approvalExpires: null,
      pendingApproval: false,
      inviteToken: inviteToken,
      inviteExpires: inviteExpires
    });

    // Enviar email de convite para o administrador
    const acceptURL = `${process.env.FRONTEND_URL || 'http://localhost:5173'}/accept-invite?token=${inviteToken}`;

    try {
      await sendTemplateEmail({
        email: administrador.email,
        subject: `Bem-vindo ao Smart Safe - ${administrador.delegacia.nome}`,
        template: 'delegacia-welcome',
        placeholders: {
          nome: administrador.nome,
          delegacia_nome: administrador.delegacia.nome,
          accept_url: acceptURL
        }
      });

      res.status(200).json({
        message: 'Registro aprovado com sucesso! O convite foi enviado para o administrador.'
      });
    } catch (emailError) {
      console.error('Erro ao enviar email de convite:', emailError);
      return res.status(500).json({
        error: 'Erro ao enviar convite para o administrador. Entre em contato com o suporte.'
      });
    }
  } catch (error) {
    console.error('Erro ao aprovar registro de delegacia:', error);
    res.status(500).json({
      error: 'Erro ao aprovar registro de delegacia'
    });
  }
};

// Nova função para rejeitar o registro
exports.rejectDelegaciaRegistration = async (req, res) => {
  try {
    const {
      token
    } = req.body;

    // Verificar se o token é válido
    const administrador = await Autoridade.findOne({
      where: {
        approvalToken: token,
        approvalExpires: {
          [Op.gt]: new Date()
        },
        pendingApproval: true
      },
      include: [{
        model: Delegacia,
        as: 'delegacia'
      }]
    });

    if (!administrador) {
      return res.status(400).json({
        error: 'Token de aprovação inválido ou expirado.'
      });
    }

    // Remover o administrador e a delegacia
    await administrador.destroy();
    await administrador.delegacia.destroy();

    res.status(200).json({
      message: 'Solicitação de registro rejeitada.'
    });
  } catch (error) {
    console.error('Erro ao rejeitar registro de delegacia:', error);
    res.status(500).json({
      error: 'Erro ao rejeitar registro de delegacia'
    });
  }
};