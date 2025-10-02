'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class RastreamentoApuros extends Model {
    static associate(models) {
      // Associação com SOS
      this.belongsTo(models.Sos, {
        foreignKey: 'sos_id',
        as: 'sos',
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE'
      });
    }
  }
  RastreamentoApuros.init({
    sos_id: {
      type: DataTypes.BIGINT,
      allowNull: false
    },
    latitude: {
      type: DataTypes.DECIMAL(10, 8),
      allowNull: false
    },
    longitude: {
      type: DataTypes.DECIMAL(11, 8),
      allowNull: false
    },
    precisao: DataTypes.DECIMAL(5, 2),
    nivel_bateria: DataTypes.DECIMAL(5, 2),
    registrado_em: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    }
  }, {
    sequelize,
    modelName: 'RastreamentoApuros',
    tableName: 'rastreamento_apuros'
  });
  return RastreamentoApuros;
};
