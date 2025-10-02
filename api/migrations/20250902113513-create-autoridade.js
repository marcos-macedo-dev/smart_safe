'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('autoridades', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.BIGINT
      },
      nome: {
        allowNull: false,
        type: Sequelize.STRING
      },
      email: {
        allowNull: false,
        unique: true,
        type: Sequelize.STRING
      },
      senha: {
        allowNull: true,
        type: Sequelize.STRING
      },
      cargo: {
        type: Sequelize.ENUM('Operador', 'Admin'),
        allowNull: false,
        defaultValue: 'Operador'
      },
      ativo: {
        allowNull: false,
        defaultValue: true,
        type: Sequelize.BOOLEAN
      },
      delegacia_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'Delegacias', // Nome da tabela de referência
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('autoridades');
  }
};