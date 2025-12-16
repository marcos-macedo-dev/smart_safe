/**
 * Remove campos sensíveis (como senha) de um objeto de usuário ou autoridade.
 * Funciona tanto com instâncias do Sequelize quanto com objetos puros.
 * @param {Object} data - Instância Sequelize ou Objeto
 * @returns {Object} Objeto limpo
 */
const excludePassword = (data) => {
  if (!data) return null;
  
  // Se for array, aplica em todos os itens
  if (Array.isArray(data)) {
    return data.map(item => excludePassword(item));
  }

  // Converte instância Sequelize para JSON se necessário
  const json = data.toJSON ? data.toJSON() : data;
  
  // Desestrutura removendo a senha
  const { senha, ...rest } = json;
  return rest;
};

module.exports = {
  excludePassword
};
