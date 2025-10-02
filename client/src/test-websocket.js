// Teste simples do WebSocket
import socket from './services/socket.js';

console.log('Testando conexão WebSocket...');

// Conectar ao WebSocket
socket.connect();

// Escutar eventos de conexão
socket.on('connect', () => {
  console.log('Conectado com sucesso!');
  
  // Testar emitir um evento
  socket.emit('teste', 'Mensagem de teste do client');
});

// Escutar eventos de teste do servidor
socket.on('teste', (data) => {
  console.log('Recebido do servidor:', data);
});

// Escutar eventos de desconexão
socket.on('disconnect', () => {
  console.log('Desconectado do servidor');
});