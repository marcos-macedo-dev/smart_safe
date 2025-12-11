'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class Autoridade extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
      this.belongsTo(models.Delegacia, {
        foreignKey: 'delegacia_id',
        as: 'delegacia'
      });
    }
  }
  Autoridade.init({
    nome: {
      type: DataTypes.STRING,
      allowNull: false
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true
    },
    senha: {
      type: DataTypes.STRING,
      allowNull: true // Pode ser nulo inicialmente para usuários convidados
    },
    cargo: {
      type: DataTypes.ENUM('Agente', 'Unidade'),
      allowNull: false,
      defaultValue: 'Agente'
    },
    ativo: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true
    },
    delegacia_id: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    // Campos para sistema de convites
    inviteToken: {
      type: DataTypes.STRING,
      allowNull: true,
      unique: true
    },
    inviteExpires: {
      type: DataTypes.DATE,
      allowNull: true
    },
    invitedBy: {
      type: DataTypes.BIGINT,
      allowNull: true,
      references: {
        model: 'autoridades',
        key: 'id'
      }
    },
    acceptedAt: {
      type: DataTypes.DATE,
      allowNull: true
    },
    // Campos para recuperação de senha
    resetPasswordToken: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    resetPasswordExpires: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    // Campos para aprovação de registro
    pendingApproval: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false
    },
    approvalToken: {
      type: DataTypes.STRING,
      allowNull: true,
      unique: true
    },
    approvalExpires: {
      type: DataTypes.DATE,
      allowNull: true
    }
  }, {
    sequelize,
    modelName: 'Autoridade',
    tableName: 'autoridades'
  });
  return Autoridade;
};