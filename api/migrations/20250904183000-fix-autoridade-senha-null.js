'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    // Alterar a coluna senha para permitir valores nulos
    await queryInterface.changeColumn('autoridades', 'senha', {
      type: Sequelize.STRING,
      allowNull: true
    });
  },

  down: async (queryInterface, Sequelize) => {
    // Reverter a alteração
    await queryInterface.changeColumn('autoridades', 'senha', {
      type: Sequelize.STRING,
      allowNull: false
    });
  }
};