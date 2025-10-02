'use strict';

module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.addColumn('autoridades', 'resetPasswordToken', {
      type: Sequelize.STRING,
      allowNull: true,
    });
    await queryInterface.addColumn('autoridades', 'resetPasswordExpires', {
      type: Sequelize.DATE,
      allowNull: true,
    });
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.removeColumn('autoridades', 'resetPasswordToken');
    await queryInterface.removeColumn('autoridades', 'resetPasswordExpires');
  }
};