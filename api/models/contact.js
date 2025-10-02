'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class Contact extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
    }
  }
  Contact.init({
    usuario_id: DataTypes.BIGINT,
    nome: DataTypes.STRING,
    telefone: DataTypes.STRING,
    parentesco: DataTypes.STRING
  }, {
    sequelize,
    modelName: 'Contact',
    tableName: 'contatos_emergencia'
  });
  return Contact;
};