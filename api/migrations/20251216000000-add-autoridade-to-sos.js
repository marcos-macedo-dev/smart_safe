'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('sos', 'autoridade_id', {
      type: Sequelize.BIGINT,
      allowNull: true,
      references: {
        model: 'autoridades',
        key: 'id',
      },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL',
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeColumn('sos', 'autoridade_id');
  },
};
