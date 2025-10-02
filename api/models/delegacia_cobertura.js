'use strict';
const {
  Model
} = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class DelegaciaCobertura extends Model {
    static associate(models) {
      // FK -> Delegacia
      DelegaciaCobertura.belongsTo(models.Delegacia, {
        foreignKey: 'delegacia_id',
        as: 'delegacia'
      });
    }
  }

  DelegaciaCobertura.init({
    delegacia_id: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    tipo: {
      type: DataTypes.ENUM('municipio', 'estado', 'raio'),
      allowNull: false
    },
    valor: {
      type: DataTypes.STRING,
      allowNull: false
    }
  }, {
    sequelize,
    modelName: 'DelegaciaCobertura',
    tableName: 'delegacia_coberturas',
  });

  return DelegaciaCobertura;
};
