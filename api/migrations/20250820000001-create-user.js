'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('usuarios', {
      id: {
        type: Sequelize.BIGINT.UNSIGNED,
        allowNull: false,
        autoIncrement: true,
        primaryKey: true
      },
      nome_completo: {
        type: Sequelize.STRING(150),
        allowNull: false
      },
      email: {
        type: Sequelize.STRING(150),
        allowNull: false,
        unique: true
      },
      senha: {
        type: Sequelize.STRING(255),
        allowNull: false
      },
      telefone: {
        type: Sequelize.STRING(20),
        allowNull: false,
        unique: true
      },
      cidade: {
        type: Sequelize.STRING(100),
        allowNull: false
      },
      estado: {
        type: Sequelize.STRING(50),
        allowNull: false
      },
      endereco: {
        type: Sequelize.STRING(255),
        allowNull: true
      },
      genero: {
        type: Sequelize.ENUM('Feminino', 'Nao_Binario', 'Masculino', 'Outro'),
        allowNull: false,
        defaultValue: 'Outro'
      },
      cor: {
        type: Sequelize.ENUM('Branca', 'Preta', 'Parda', 'Amarela', 'Indigena', 'Outra'),
        allowNull: false,
        defaultValue: 'outra'
      },
      documento_identificacao: {
        type: Sequelize.STRING(50),
        allowNull: true
      },
      consentimento: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false
      },
      resetPasswordToken: {
        type: Sequelize.STRING,
        allowNull: true
      },
      resetPasswordExpires: {
        type: Sequelize.DATE,
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
  async down(queryInterface, _Sequelize) {
    await queryInterface.dropTable('usuarios');
  }
};