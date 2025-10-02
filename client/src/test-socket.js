// Teste de conexão WebSocket
const socket = io('http://localhost:3002');

socket.on('connect', () => {
  console.log('Conectado com sucesso ao servidor WebSocket');
});

socket.on('disconnect', () => {
  console.log('Desconectado do servidor WebSocket');
});

socket.on('connect_error', (error) => {
  console.error('Erro de conexão:', error);
});