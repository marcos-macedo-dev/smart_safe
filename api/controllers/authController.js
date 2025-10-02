const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');
const crypto = require('crypto');

const { User, Autoridade } = require('../models');
const { sendTemplateEmail } = require('../utils/emailService');

const JWT_SECRET = process.env.JWT_SECRET || 'supersecretkey';

// Função para validar força da senha
const validatePassword = (password) => {
  // Requisitos mínimos de senha:
  // - Pelo menos 8 caracteres
  // - Pelo menos uma letra maiúscula
  // - Pelo menos uma letra minúscula
  // - Pelo menos um número
  // - Pelo menos um caractere especial
  const strongPasswordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
  return strongPasswordRegex.test(password);
};

exports.login = async (req, res) => {
  try {
    const { email, senha } = req.body;
    if (!email || !senha)
      return res.status(400).json({
        message: 'Email e senha são obrigatórios'
      });

    // 1. Tenta autenticar como Autoridade
    const autoridade = await Autoridade.findOne({
      where: {
        email
      }
    });

    if (autoridade) {
      // Verificar se é um usuário convidado que ainda não aceitou o convite
      if (!autoridade.senha) {
        return res.status(401).json({
          message: 'Você foi convidado para se juntar à sua delegacia. Por favor, aceite o convite primeiro.'
        });
      }
      
      if (!autoridade.ativo) {
        return res.status(403).json({
          message: 'Este usuário de autoridade está inativo.'
        });
      }

      const isMatch = await bcrypt.compare(senha, autoridade.senha);
      if (isMatch) {
        const token = jwt.sign({
          id: autoridade.id,
          email: autoridade.email,
          delegacia_id: autoridade.delegacia_id,
          cargo: autoridade.cargo,
          tipo: 'autoridade'
        }, JWT_SECRET, {
          expiresIn: '7d'
        });

        return res.json({
          user: {
            id: autoridade.id,
            nome: autoridade.nome,
            email: autoridade.email,
            delegacia_id: autoridade.delegacia_id,
            cargo: autoridade.cargo,
            tipo: 'autoridade'
          },
          token
        });
      }
    }

    // 2. Se não for Autoridade, tenta autenticar como User (cidadã)
    const user = await User.findOne({
      where: {
        email
      }
    });
    if (!user) return res.status(401).json({
      message: 'Credenciais inválidas'
    });

    const isMatch = await bcrypt.compare(senha, user.senha);
    if (!isMatch) return res.status(401).json({
      message: 'Credenciais inválidas'
    });

    const token = jwt.sign({
      id: user.id,
      email: user.email,
      tipo: 'user'
    }, JWT_SECRET, {
      expiresIn: '7d'
    });

    const refreshToken = jwt.sign({
      id: user.id,
      email: user.email,
      tipo: 'user'
    }, JWT_SECRET, {
      expiresIn: '30d'
    });

    res.json({
      user: user,
      token
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      message: 'Erro no servidor'
    });
  }
};

exports.logout = (req, res) => {
  res.json({
    message: 'Logout bem-sucedido'
  });
};

// Request Password Reset para usuários (cidadãs) - gera OTP e envia por email
exports.requestPasswordResetUser = async (req, res) => {
  try {
    const { email } = req.body;
    
    // Procurar usuário cidadã
    const user = await User.findOne({
      where: {
        email
      }
    });

    // Se não encontrar o usuário, enviar mensagem genérica
    if (!user) {
      return res.status(200).json({
        message: 'Se o email estiver em nosso sistema, um código de verificação foi enviado.'
      });
    }

    // Gerar código OTP de 6 dígitos
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpires = Date.now() + 900000; // 15 minutos

    // Atualizar o usuário com o OTP
    await user.update({
      resetPasswordToken: otp,
      resetPasswordExpires: otpExpires,
    });

    // Enviar OTP por email
    try {
      await sendTemplateEmail({
        email: user.email,
        subject: 'Código de Verificação - Redefinição de Senha Smart Safe',
        template: 'otp-code', // Usando o novo template específico para OTP
        placeholders: {
          otp_code: otp // Passando o OTP como placeholder
        }
      });

      res.status(200).json({
        message: 'Se o email estiver em nosso sistema, um código de verificação foi enviado.'
      });
    } catch (emailError) {
      console.error('Erro ao enviar e-mail de redefinição para usuário:', emailError);
      // Limpar token se falhar ao enviar email
      await user.update({
        resetPasswordToken: null,
        resetPasswordExpires: null,
      });
      return res.status(500).json({
        message: 'Erro ao enviar e-mail de redefinição. Tente novamente mais tarde.'
      });
    }
  } catch (err) {
    console.error('Erro no requestPasswordResetUser:', err);
    res.status(500).json({
      message: 'Erro no servidor'
    });
  }
};

// Request Password Reset para autoridades - gera token e envia por email
exports.requestPasswordResetAuthority = async (req, res) => {
  try {
    const { email } = req.body;
    
    // Procurar autoridade
    const autoridade = await Autoridade.findOne({
      where: {
        email
      }
    });

    // Se não encontrar a autoridade, enviar mensagem genérica
    if (!autoridade) {
      return res.status(200).json({
        message: 'Se o email estiver em nosso sistema, um link de redefinição foi enviado.'
      });
    }

    // Gerar token de redefinição
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetExpires = Date.now() + 3600000; // 1 hour from now

    // Atualizar a autoridade com o token
    await autoridade.update({
      resetPasswordToken: resetToken,
      resetPasswordExpires: resetExpires,
    });

    // Construir URL específica para autoridades
    const resetURL = `${process.env.FRONTEND_URL || 'http://localhost:5173'}/reset-password?token=${resetToken}&type=autoridade`;

    try {
      await sendTemplateEmail({
        email: autoridade.email,
        subject: 'Redefinição de Senha Smart Safe - Autoridade',
        template: 'reset-password',
        placeholders: {
          reset_url: resetURL
        }
      });

      res.status(200).json({
        message: 'Se o email estiver em nosso sistema, um link de redefinição foi enviado.'
      });
    } catch (emailError) {
      console.error('Erro ao enviar e-mail de redefinição para autoridade:', emailError);
      // Limpar token se falhar ao enviar email
      await autoridade.update({
        resetPasswordToken: null,
        resetPasswordExpires: null,
      });
      return res.status(500).json({
        message: 'Erro ao enviar e-mail de redefinição. Tente novamente mais tarde.'
      });
    }
  } catch (err) {
    console.error('Erro no requestPasswordResetAuthority:', err);
    res.status(500).json({
      message: 'Erro no servidor'
    });
  }
};

// Reset Password para usuários (cidadãs) usando OTP
exports.resetPasswordWithOtp = async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;

    // Validação de campos
    if (!email || !otp || !newPassword) {
      return res.status(400).json({
        message: 'Email, código de verificação e nova senha são obrigatórios.'
      });
    }

    // Validar força da senha
    if (!validatePassword(newPassword)) {
      return res.status(400).json({
        message: 'A senha deve ter pelo menos 8 caracteres, incluindo letras maiúsculas, minúsculas, números e caracteres especiais.'
      });
    }

    // Procurar usuário cidadã com o OTP válido
    const user = await User.findOne({
      where: {
        email: email,
        resetPasswordToken: otp,
        resetPasswordExpires: {
          [Op.gt]: Date.now(), // OTP must not be expired
        },
      },
    });

    // Se não encontrar usuário com o OTP válido
    if (!user) {
      return res.status(400).json({
        message: 'Código inválido ou expirado.'
      });
    }

    // Criptografar a nova senha
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Atualizar a senha do usuário e limpar o OTP
    await user.update({
      senha: hashedPassword,
      resetPasswordToken: null,
      resetPasswordExpires: null,
    });

    res.status(200).json({
      message: 'Senha redefinida com sucesso.'
    });
  } catch (err) {
    console.error('Erro no resetPasswordWithOtp:', err);
    res.status(500).json({
      message: 'Erro no servidor'
    });
  }
};

// Reset Password para autoridades usando token
exports.resetPasswordWithToken = async (req, res) => {
  try {
    const { token } = req.params;
    const { newPassword } = req.body;

    // Validação de campos
    if (!newPassword) {
      return res.status(400).json({
        message: 'Nova senha é obrigatória.'
      });
    }

    // Validar força da senha
    if (!validatePassword(newPassword)) {
      return res.status(400).json({
        message: 'A senha deve ter pelo menos 8 caracteres, incluindo letras maiúsculas, minúsculas, números e caracteres especiais.'
      });
    }

    // Procurar autoridade com o token válido
    const autoridade = await Autoridade.findOne({
      where: {
        resetPasswordToken: token,
        resetPasswordExpires: {
          [Op.gt]: Date.now(), // Token must not be expired
        },
      },
    });

    // Se não encontrar autoridade com o token válido
    if (!autoridade) {
      return res.status(400).json({
        message: 'Token inválido ou expirado.'
      });
    }

    // Criptografar a nova senha
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Atualizar a senha da autoridade e limpar o token
    await autoridade.update({
      senha: hashedPassword,
      resetPasswordToken: null,
      resetPasswordExpires: null,
    });

    res.status(200).json({
      message: 'Senha redefinida com sucesso.'
    });
  } catch (err) {
    console.error('Erro no resetPasswordWithToken:', err);
    res.status(500).json({
      message: 'Erro no servidor'
    });
  }
};

// Change Password para usuários autenticados
exports.changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const user = req.user;

    // Validação de campos
    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        message: 'Senha atual e nova senha são obrigatórias.'
      });
    }

    // Validar força da senha
    if (!validatePassword(newPassword)) {
      return res.status(400).json({
        message: 'A senha deve ter pelo menos 8 caracteres, incluindo letras maiúsculas, minúsculas, números e caracteres especiais.'
      });
    }

    // Verificar se o usuário é uma autoridade ou um usuário comum
    if (user.tipo === 'autoridade') {
      const autoridade = await Autoridade.findByPk(user.id);
      
      if (!autoridade) {
        return res.status(404).json({
          message: 'Autoridade não encontrada.'
        });
      }

      // Verificar a senha atual
      const isMatch = await bcrypt.compare(currentPassword, autoridade.senha);
      if (!isMatch) {
        return res.status(400).json({
          message: 'Senha atual incorreta.'
        });
      }

      // Criptografar a nova senha
      const hashedPassword = await bcrypt.hash(newPassword, 10);
      
      // Atualizar a senha
      await autoridade.update({
        senha: hashedPassword
      });

      return res.status(200).json({
        message: 'Senha alterada com sucesso.'
      });
    } else {
      // Usuário comum
      const usuario = await User.findByPk(user.id);
      
      if (!usuario) {
        return res.status(404).json({
          message: 'Usuário não encontrado.'
        });
      }

      // Verificar a senha atual
      const isMatch = await bcrypt.compare(currentPassword, usuario.senha);
      if (!isMatch) {
        return res.status(400).json({
          message: 'Senha atual incorreta.'
        });
      }

      // Criptografar a nova senha
      const hashedPassword = await bcrypt.hash(newPassword, 10);
      
      // Atualizar a senha
      await usuario.update({
        senha: hashedPassword
      });

      return res.status(200).json({
        message: 'Senha alterada com sucesso.'
      });
    }
  } catch (err) {
    console.error('Erro no changePassword:', err);
    res.status(500).json({
      message: 'Erro no servidor'
    });
  }
};
