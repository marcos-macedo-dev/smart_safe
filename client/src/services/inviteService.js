import http from './http';

const inviteService = {
  verifyInviteToken(token) {
    return http.get(`/invites/verify/${token}`);
  },

  acceptInvite(data) {
    return http.post('/invites/accept', data);
  },

  sendInvite(data) {
    return http.post('/invites/send', data);
  }
};

export default inviteService;
 