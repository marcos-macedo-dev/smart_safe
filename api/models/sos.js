'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class Sos extends Model {
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

      this.belongsTo(models.User, {
        foreignKey: 'usuario_id',
        as: 'usuario'
      });

      this.hasMany(models.Media, {
        foreignKey: 'sos_id',
        as: 'midia'
      });
    }
  }
  Sos.init({
    id: {
      type: DataTypes.BIGINT.UNSIGNED,
      primaryKey: true,
      autoIncrement: true,
      allowNull: false
    },
    usuario_id: {
      type: DataTypes.BIGINT.UNSIGNED,
      allowNull: false,
      references: {
        model: 'usuarios',
        key: 'id'
      },
      onUpdate: 'CASCADE',
      onDelete: 'CASCADE'
    },
    caminho_audio: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    caminho_video: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    latitude: {
      type: DataTypes.DECIMAL(10, 8),
      allowNull: true
    },
    longitude: {
      type: DataTypes.DECIMAL(11, 8),
      allowNull: true
    },
    delegacia_id: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    status: {
      type: DataTypes.ENUM('pendente', 'ativo', 'aguardando_autoridade', 'fechado', 'cancelado'),
      allowNull: false,
      defaultValue: 'pendente'
    },
    encerrado_em: {
      type: DataTypes.DATE,
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
    modelName: 'Sos',
    tableName: 'sos',
    timestamps: true
  });
  return Sos;
};