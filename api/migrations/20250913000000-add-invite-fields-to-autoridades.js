'use strict';

module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.addColumn('autoridades', 'inviteToken', {
      type: Sequelize.STRING,
      allowNull: true,
      unique: true
    });

    await queryInterface.addColumn('autoridades', 'inviteExpires', {
      type: Sequelize.DATE,
      allowNull: true
    });

    await queryInterface.addColumn('autoridades', 'invitedBy', {
      type: Sequelize.BIGINT,
      allowNull: true,
      references: {
        model: 'autoridades',
        key: 'id'
      }
    });

    await queryInterface.addColumn('autoridades', 'acceptedAt', {
      type: Sequelize.DATE,
      allowNull: true
    });
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.removeColumn('autoridades', 'inviteToken');
    await queryInterface.removeColumn('autoridades', 'inviteExpires');
    await queryInterface.removeColumn('autoridades', 'invitedBy');
    await queryInterface.removeColumn('autoridades', 'acceptedAt');
  }
};

