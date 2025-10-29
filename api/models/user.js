'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class User extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
      this.hasMany(models.Sos, {
        foreignKey: 'usuario_id',
        as: 'sos'
      });
    }
  }
  User.init({
    id: {
      type: DataTypes.BIGINT.UNSIGNED,
      primaryKey: true,
      autoIncrement: true,
      allowNull: false
    },
    nome_completo: {
      type: DataTypes.STRING(150),
      allowNull: false
    },
    email: {
      type: DataTypes.STRING(150),
      allowNull: false,
      unique: true
    },
    senha: {
      type: DataTypes.STRING(255),
      allowNull: false
    },
    telefone: {
      type: DataTypes.STRING(20),
      allowNull: false,
      unique: true
    },
    cidade: {
      type: DataTypes.STRING(100),
      allowNull: false
    },
    estado: {
      type: DataTypes.CHAR(2),
      allowNull: false
    },
    endereco: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    genero: {
      type: DataTypes.ENUM('Feminino', 'Nao_Binario', 'Masculino', 'Outro'),
      allowNull: false,
      defaultValue: 'Outro'
    },
    cor: {
      type: DataTypes.ENUM('Branca', 'Preta', 'Parda', 'Amarela', 'Indigena', 'Outra'),
      allowNull: false,
      defaultValue: 'outra'
    },
    documento_identificacao: {
      type: DataTypes.STRING(50),
      allowNull: true
    },
    consentimento: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false
    },
    resetPasswordToken: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    resetPasswordExpires: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    createdAt: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW
    },
    updatedAt: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW
    }
  }, {
    sequelize,
    modelName: 'User',
    tableName: 'usuarios',
    timestamps: true
  });
  return User;
};