
// Middleware para verificar se o usuário tem o cargo necessário
exports.isUnidade = (req, res, next) => {
  // O middleware de autenticação já deve ter sido executado
  if (req.user && req.user.cargo === 'Unidade') {
    return next();
  }
  return res.status(403).json({ error: 'Acesso negado. Requer cargo de Unidade.' });
};