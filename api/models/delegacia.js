'use strict';
const {
  Model
} = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class Delegacia extends Model {
    static associate(models) {
      // define association here
      Delegacia.hasMany(models.DelegaciaCobertura, { foreignKey: 'delegacia_id', as: 'coberturas' });
      // Caso queira relacionar SOS a Delegacia
      // Delegacia.hasMany(models.Sos, { foreignKey: 'delegacia_id' });
    }
  }

  Delegacia.init({
    nome: {
      type: DataTypes.STRING,
      allowNull: false
    },
    endereco: {
      type: DataTypes.STRING,
      allowNull: false
    },
    latitude: {
      type: DataTypes.DOUBLE,
      allowNull: false
    },
    longitude: {
      type: DataTypes.DOUBLE,
      allowNull: false
    },
    telefone: {
      type: DataTypes.STRING
    },
    ativa: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true
    }
  }, {
    sequelize,
    modelName: 'Delegacia',
    tableName: 'Delegacias', // pluralização padrão
  });

  return Delegacia;
};