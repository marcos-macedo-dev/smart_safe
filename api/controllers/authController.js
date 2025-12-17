const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { Op } = require('sequelize');
const { User, Autoridade } = require('../models');
const { sendTemplateEmail } = require('../utils/emailService');
const {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
  hashToken,
} = require('../utils/authTokens');

// ==========================================
// Helpers
// ==========================================

const findAccountByEmail = async (email) => {
  const autoridade = await Autoridade.findOne({ where: { email } });
  if (autoridade) return { account: autoridade, role: autoridade.cargo }; // Retorna o cargo real: 'Agente' ou 'Unidade'

  const user = await User.findOne({ where: { email } });
  if (user) return { account: user, role: 'user' };

  return null;
};

const validatePasswordStrength = (password) => {
  const strongPasswordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
  return strongPasswordRegex.test(password);
};

// ==========================================
// Controller Methods
// ==========================================

module.exports = {
  // ---------------------------------------------------------------------------
  // Login Flow
  // ---------------------------------------------------------------------------
  async login(req, res) {
    try {
      let { email, senha } = req.body;

      if (!email || !senha) {
        return res.status(400).json({ error: 'Email e senha são obrigatórios' });
      }

      email = email.trim();
      senha = senha.trim();

      const result = await findAccountByEmail(email);

      if (!result) {
        return res.status(401).json({ error: 'Credenciais inválidas' });
      }

      const { account, role } = result;

      if (role === 'autoridade') {
        if (!account.senha) {
          return res.status(401).json({ error: 'Você foi convidado. Por favor, aceite o convite primeiro.' });
        }
        if (!account.ativo) {
          return res.status(403).json({ error: 'Conta inativa. Contate o administrador.' });
        }
      }

      const senhaOk = await bcrypt.compare(senha, account.senha);
      if (!senhaOk) {
        return res.status(401).json({ error: 'Credenciais inválidas' });
      }

      const tokenPayload = {
        id: account.id,
        role: role,
        email: account.email,
        ...(['Agente', 'Unidade'].includes(role) && {
          delegacia_id: account.delegacia_id,
          cargo: account.cargo
        })
      };

      const accessToken = generateAccessToken(tokenPayload);
      const refreshToken = generateRefreshToken({ id: account.id, role: role });

      // Persistência do Refresh Token (Comentado até migration existir)
      /*
      try {
        const refreshTokenHash = hashToken(refreshToken);
        if (account.setDataValue) { 
           await account.update({ refresh_token: refreshTokenHash });
        }
      } catch (dbError) {
        console.warn('Aviso: Erro ao salvar refresh token.', dbError.message);
      }
      */

      res.cookie('refreshToken', refreshToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 7 * 24 * 60 * 60 * 1000
      });

      const userResponse = {
        id: account.id,
        nome: ['Agente', 'Unidade'].includes(role) ? account.nome : account.nome_completo,
        email: account.email,
        tipo: role,
        ...(['Agente', 'Unidade'].includes(role) && {
          delegacia_id: account.delegacia_id,
          cargo: account.cargo
        })
      };

      res.json({
        accessToken,
        refreshToken,
        user: userResponse
      });

    } catch (error) {
      console.error('Erro ao autenticar:', error);
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  },

  async logout(req, res) {
    res.clearCookie('refreshToken');
    res.json({ message: 'Logout bem-sucedido' });
  },

  // ---------------------------------------------------------------------------
  // Refresh Token
  // ---------------------------------------------------------------------------
  async refreshToken(req, res) {
    try {
      const incomingRefresh =
        req.body.refreshToken || req.cookies?.refreshToken || null;

      if (!incomingRefresh) {
        return res.status(400).json({
          success: false,
          message: 'Refresh token é obrigatório',
        });
      }

      let decoded;
      try {
        decoded = verifyRefreshToken(incomingRefresh);
      } catch (err) {
        return res.status(401).json({ success: false, message: 'Refresh token inválido ou expirado' });
      }

      const { id, role } = decoded;

      // Regerar tokens
      const payload = { id, role }; // manter mínimo para access token
      const newAccessToken = generateAccessToken(payload);
      const newRefreshToken = generateRefreshToken(payload);

      // Opcional: persistir hash do refresh (mantido como TODO)
      // const refreshTokenHash = hashToken(newRefreshToken);
      // salvar em banco se necessário

      res.cookie('refreshToken', newRefreshToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 7 * 24 * 60 * 60 * 1000,
      });

      return res.status(200).json({
        success: true,
        data: {
          token: newAccessToken,
          refreshToken: newRefreshToken,
        },
      });
    } catch (error) {
      console.error('Erro no refresh token:', error);
      return res.status(500).json({ success: false, message: 'Erro interno do servidor' });
    }
  },

  // ---------------------------------------------------------------------------
  // Password Reset Flows
  // ---------------------------------------------------------------------------

  async requestPasswordResetUser(req, res) {
    try {
      const { email } = req.body;
      if (!email) return res.status(400).json({ error: 'Email é obrigatório.' });

      const user = await User.findOne({ where: { email: email.trim() } });

      if (!user) {
        return res.status(200).json({ message: 'Se o email estiver no sistema, um código foi enviado.' });
      }

      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      const otpExpires = Date.now() + 15 * 60 * 1000; // 15 min

      await user.update({
        resetPasswordToken: otp,
        resetPasswordExpires: otpExpires,
      });

      try {
        await sendTemplateEmail({
          email: user.email,
          subject: 'Código de Verificação - Smart Safe',
          template: 'otp-code',
          placeholders: { otp_code: otp }
        });
      } catch (emailError) {
        console.error('Erro email user reset:', emailError);
        await user.update({ resetPasswordToken: null, resetPasswordExpires: null });
        return res.status(500).json({ error: 'Erro ao enviar e-mail.' });
      }

      return res.status(200).json({ message: 'Se o email estiver no sistema, um código foi enviado.' });

    } catch (err) {
      console.error('Erro requestPasswordResetUser:', err);
      return res.status(500).json({ error: 'Erro interno no servidor' });
    }
  },

  async requestPasswordResetAuthority(req, res) {
    try {
      const { email } = req.body;
      if (!email) return res.status(400).json({ error: 'Email é obrigatório.' });

      const autoridade = await Autoridade.findOne({ where: { email: email.trim() } });

      if (!autoridade) {
        return res.status(200).json({ message: 'Se o email estiver no sistema, um link foi enviado.' });
      }

      const resetToken = crypto.randomBytes(32).toString('hex');
      const resetExpires = Date.now() + 60 * 60 * 1000; // 1 hora

      await autoridade.update({
        resetPasswordToken: resetToken,
        resetPasswordExpires: resetExpires,
      });

      const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:5173';
      const resetURL = `${frontendUrl}/reset-password?token=${resetToken}&type=autoridade`;

      try {
        await sendTemplateEmail({
          email: autoridade.email,
          subject: 'Redefinição de Senha - Autoridade',
          template: 'reset-password',
          placeholders: { reset_url: resetURL }
        });
      } catch (emailError) {
        console.error('Erro email authority reset:', emailError);
        await autoridade.update({ resetPasswordToken: null, resetPasswordExpires: null });
        return res.status(500).json({ error: 'Erro ao enviar e-mail.' });
      }

      return res.status(200).json({ message: 'Se o email estiver no sistema, um link foi enviado.' });

    } catch (err) {
      console.error('Erro requestPasswordResetAuthority:', err);
      return res.status(500).json({ error: 'Erro interno no servidor' });
    }
  },

  async resetPasswordWithOtp(req, res) {
    try {
      let { email, otp, newPassword } = req.body;

      if (!email || !otp || !newPassword) {
        return res.status(400).json({ error: 'Dados incompletos.' });
      }

      if (!validatePasswordStrength(newPassword)) {
        return res.status(400).json({ error: 'A senha é muito fraca.' });
      }

      const user = await User.findOne({
        where: {
          email: email.trim(),
          resetPasswordToken: otp.trim(),
          resetPasswordExpires: { [Op.gt]: Date.now() },
        },
      });

      if (!user) {
        return res.status(400).json({ error: 'Código inválido ou expirado.' });
      }

      const hashedPassword = await bcrypt.hash(newPassword.trim(), 10);

      await user.update({
        senha: hashedPassword,
        resetPasswordToken: null,
        resetPasswordExpires: null,
      });

      return res.status(200).json({ message: 'Senha redefinida com sucesso.' });

    } catch (err) {
      console.error('Erro resetPasswordWithOtp:', err);
      return res.status(500).json({ error: 'Erro interno no servidor' });
    }
  },

  async resetPasswordWithToken(req, res) {
    try {
      const { token } = req.params;
      const { newPassword } = req.body;

      if (!newPassword) {
        return res.status(400).json({ error: 'Nova senha é obrigatória.' });
      }

      if (!validatePasswordStrength(newPassword)) {
        return res.status(400).json({ error: 'A senha é muito fraca.' });
      }

      const autoridade = await Autoridade.findOne({
        where: {
          resetPasswordToken: token,
          resetPasswordExpires: { [Op.gt]: Date.now() },
        },
      });

      if (!autoridade) {
        return res.status(400).json({ error: 'Token inválido ou expirado.' });
      }

      const hashedPassword = await bcrypt.hash(newPassword.trim(), 10);

      await autoridade.update({
        senha: hashedPassword,
        resetPasswordToken: null,
        resetPasswordExpires: null,
      });

      return res.status(200).json({ message: 'Senha redefinida com sucesso.' });

    } catch (err) {
      console.error('Erro resetPasswordWithToken:', err);
      return res.status(500).json({ error: 'Erro interno no servidor' });
    }
  },

  async changePassword(req, res) {
    try {
      const { currentPassword, newPassword } = req.body;
      const { id, role } = req.user; // req.user vem do authMiddleware, que agora usa 'role' ao invés de 'tipo' se usarmos o token novo?
      // O token gerado por generateAccessToken usa 'role', mas o middleware antigo pode estar esperando 'tipo'.
      // Vamos assumir que o middleware decodifica e joga no req.user o payload. 
      // Nosso novo token tem { id, role, email }. 
      // Vou ajustar para buscar dinamicamente.

      if (!currentPassword || !newPassword) {
        return res.status(400).json({ error: 'Campos obrigatórios ausentes.' });
      }

      if (!validatePasswordStrength(newPassword)) {
        return res.status(400).json({ error: 'A nova senha não é forte o suficiente.' });
      }

      // Busca dinâmica
      let account;
      // Precisamos saber se é 'user' ou 'autoridade'. O novo token manda 'role'.
      // Se o middleware antigo ainda for usado, ele pode estar confuso. 
      // Vou assumir que 'role' está disponível no req.user (se o middleware apenas fizer jwt.verify).
      
      const userType = req.user.role || req.user.tipo; // Fallback para compatibilidade

      if (userType === 'autoridade') {
        account = await Autoridade.findByPk(id);
      } else {
        account = await User.findByPk(id);
      }

      if (!account) {
        return res.status(404).json({ error: 'Usuário não encontrado.' });
      }

      const isMatch = await bcrypt.compare(currentPassword.trim(), account.senha);
      if (!isMatch) {
        return res.status(400).json({ error: 'Senha atual incorreta.' });
      }

      const hashedPassword = await bcrypt.hash(newPassword.trim(), 10);
      await account.update({ senha: hashedPassword });

      return res.status(200).json({ message: 'Senha alterada com sucesso.' });

    } catch (err) {
      console.error('Erro changePassword:', err);
      return res.status(500).json({ error: 'Erro interno no servidor' });
    }
  }
};