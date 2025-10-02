const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const {
  Op
} = require('sequelize');
const {
  Autoridade,
  Delegacia
} = require('../models');
const { sendTemplateEmail } = require('../utils/emailService');
const crypto = require('crypto');

const JWT_SECRET = process.env.JWT_SECRET || 'supersecretkey';

// Função para enviar convite por email
exports.sendInvite = async (req, res) => {
  try {
    const {
      email,
      nome,
      cargo,
      delegacia_id
    } = req.body;
    const invitingAdmin = req.user; // Admin que está enviando o convite

    // Verificar se o usuário já existe
    const existingUser = await Autoridade.findOne({
      where: {
        email
      }
    });
    if (existingUser) {
      return res.status(400).json({
        error: 'Este email já está em uso.'
      });
    }

    // Verificar se a delegacia existe
    const delegacia = await Delegacia.findByPk(delegacia_id);
    if (!delegacia) {
      return res.status(404).json({
        error: 'Delegacia não encontrada.'
      });
    }

    // Gerar token de convite
    const inviteToken = crypto.randomBytes(32).toString('hex');
    const inviteExpires = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 dias

    // Criar o registro do usuário convidado
    const invitedUser = await Autoridade.create({
      nome,
      email,
      cargo,
      delegacia_id,
      inviteToken,
      inviteExpires,
      invitedBy: invitingAdmin.id,
      ativo: true
    });

    // Enviar email com o link de aceitação
    const acceptURL = `${process.env.FRONTEND_URL || 'http://localhost:5173'}/accept-invite?token=${inviteToken}`;

    const message = `
      Olá ${nome},
      
      Você foi convidado para se juntar à ${delegacia.nome} como ${cargo}.
      
      Por favor, clique no link abaixo para aceitar o convite e definir sua senha:
      ${acceptURL}
      
      Este link expirará em 7 dias.
      
      Se você não solicitou este convite, por favor ignore este email.
    `;

    try {
      await sendTemplateEmail({
        email,
        subject: `Convite para ${delegacia.nome} - Smart Safe`,
        template: 'invite',
        placeholders: {
          nome: nome,
          delegacia_nome: delegacia.nome,
          cargo: cargo,
          accept_url: acceptURL
        }
      });

      res.status(200).json({
        message: 'Convite enviado com sucesso!',
        user: {
          id: invitedUser.id,
          nome: invitedUser.nome,
          email: invitedUser.email,
          cargo: invitedUser.cargo,
          delegacia_id: invitedUser.delegacia_id
        }
      });
    } catch (emailError) {
      console.error('Erro ao enviar email de convite:', emailError);
      // Remover o usuário se falhar ao enviar o email
      await invitedUser.destroy();
      return res.status(500).json({
        error: 'Erro ao enviar email de convite. Tente novamente mais tarde.'
      });
    }
  } catch (error) {
    console.error('Erro ao enviar convite:', error);
    res.status(500).json({
      error: 'Erro interno do servidor.'
    });
  }
};

// Função para aceitar convite e definir senha
exports.acceptInvite = async (req, res) => {
  try {
    const {
      token,
      senha
    } = req.body;

    // Verificar se o token é válido
    const invitedUser = await Autoridade.findOne({
      where: {
        inviteToken: token,
        inviteExpires: {
          [Op.gt]: new Date()
        }
      }
    });

    if (!invitedUser) {
      return res.status(400).json({
        error: 'Token de convite inválido ou expirado.'
      });
    }

    // Verificar se a senha foi fornecida
    if (!senha) {
      return res.status(400).json({
        error: 'Senha é obrigatória.'
      });
    }

    // Criptografar a senha
    const hashedPassword = await bcrypt.hash(senha, 10);

    // Atualizar o usuário com a senha e remover o token de convite
    await invitedUser.update({
      senha: hashedPassword,
      inviteToken: null,
      inviteExpires: null,
      acceptedAt: new Date(),
      ativo: true // Tornar o usuário ativo quando aceitar o convite
    });

    // Gerar token JWT
    const authToken = jwt.sign({
      id: invitedUser.id,
      email: invitedUser.email,
      delegacia_id: invitedUser.delegacia_id,
      cargo: invitedUser.cargo,
      tipo: 'autoridade'
    }, JWT_SECRET, {
      expiresIn: '7d'
    });

    res.json({
      message: 'Convite aceito com sucesso!',
      user: {
        id: invitedUser.id,
        nome: invitedUser.nome,
        email: invitedUser.email,
        delegacia_id: invitedUser.delegacia_id,
        cargo: invitedUser.cargo,
        tipo: 'autoridade'
      },
      token: authToken
    });
  } catch (error) {
    console.error('Erro ao aceitar convite:', error);
    res.status(500).json({
      error: 'Erro interno do servidor.'
    });
  }
};

// Função para verificar token de convite (para frontend)
exports.verifyInviteToken = async (req, res) => {
  try {
    const {
      token
    } = req.params;

    // Verificar se o token é válido
    const invitedUser = await Autoridade.findOne({
      where: {
        inviteToken: token,
        inviteExpires: {
          [Op.gt]: new Date()
        }
      },
      include: [{
        model: Delegacia,
        as: 'delegacia',
        attributes: ['nome']
      }]
    });

    if (!invitedUser) {
      return res.status(400).json({
        error: 'Token de convite inválido ou expirado.'
      });
    }

    res.json({
      valid: true,
      user: {
        nome: invitedUser.nome,
        email: invitedUser.email,
        cargo: invitedUser.cargo,
        delegacia: invitedUser.delegacia.nome
      }
    });
  } catch (error) {
    console.error('Erro ao verificar token de convite:', error);
    res.status(500).json({
      error: 'Erro interno do servidor.'
    });
  }
};