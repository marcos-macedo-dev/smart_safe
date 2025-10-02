'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class AuditLog extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
    }
  }
  AuditLog.init({
    id: {
      type: DataTypes.BIGINT.UNSIGNED,
      primaryKey: true,
      autoIncrement: true,
      allowNull: false
    },
    ator_id: {
      type: DataTypes.BIGINT.UNSIGNED,
      allowNull: false
    },
    acao: {
      type: DataTypes.STRING(50),
      allowNull: false
    },
    tipo_alvo: {
      type: DataTypes.STRING(50),
      allowNull: false
    },
    id_alvo: {
      type: DataTypes.BIGINT.UNSIGNED,
      allowNull: false
    },
    detalhes: {
      type: DataTypes.JSON,
      allowNull: true
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
    modelName: 'AuditLog',
    tableName: 'registro_auditoria',
    timestamps: true
  });
  return AuditLog;
};