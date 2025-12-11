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
        type: Sequelize.ENUM('Agente', 'Unidade'),
        allowNull: false,
        defaultValue: 'Agente'
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
      inviteToken: {
        type: Sequelize.STRING,
        allowNull: true,
        unique: true
      },
      inviteExpires: {
        type: Sequelize.DATE,
        allowNull: true
      },
      invitedBy: {
        type: Sequelize.BIGINT,
        allowNull: true,
        references: {
          model: 'autoridades',
          key: 'id'
        },
        onUpdate: 'SET NULL',
        onDelete: 'SET NULL'
      },
      acceptedAt: {
        type: Sequelize.DATE,
        allowNull: true
      },
      resetPasswordToken: {
        type: Sequelize.STRING,
        allowNull: true
      },
      resetPasswordExpires: {
        type: Sequelize.DATE,
        allowNull: true
      },
      pendingApproval: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false
      },
      approvalToken: {
        type: Sequelize.STRING,
        allowNull: true,
        unique: true
      },
      approvalExpires: {
        type: Sequelize.DATE,
        allowNull: true
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
  async down(queryInterface, _Sequelize) {
    await queryInterface.dropTable('autoridades');
  }
};