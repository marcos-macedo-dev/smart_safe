'use strict';

module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.addColumn('autoridades', 'pendingApproval', {
      type: Sequelize.BOOLEAN,
      allowNull: false,
      defaultValue: false
    });

    await queryInterface.addColumn('autoridades', 'approvalToken', {
      type: Sequelize.STRING,
      allowNull: true,
      unique: true
    });

    await queryInterface.addColumn('autoridades', 'approvalExpires', {
      type: Sequelize.DATE,
      allowNull: true
    });
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.removeColumn('autoridades', 'pendingApproval');
    await queryInterface.removeColumn('autoridades', 'approvalToken');
    await queryInterface.removeColumn('autoridades', 'approvalExpires');
  }
};