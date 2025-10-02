'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('registro_auditoria', {
      id: {
        type: Sequelize.BIGINT.UNSIGNED,
        allowNull: false,
        autoIncrement: true,
        primaryKey: true
      },
      ator_id: {
        type: Sequelize.BIGINT.UNSIGNED,
        allowNull: false
      },
      acao: {
        type: Sequelize.STRING(50),
        allowNull: false
      },
      tipo_alvo: {
        type: Sequelize.STRING(50),
        allowNull: false
      },
      id_alvo: {
        type: Sequelize.BIGINT.UNSIGNED,
        allowNull: false
      },
      detalhes: {
        type: Sequelize.JSON,
        allowNull: true
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP')
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('registro_auditoria');
  }
};