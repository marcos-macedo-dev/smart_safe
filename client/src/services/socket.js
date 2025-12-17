import { io } from 'socket.io-client';

// URL do servidor WebSocket
const SOCKET_URL = 'https://api.nuvemtec.shop';

class SocketService {
  constructor() {
    this.socket = null;
    this.isConnected = false;
  }

  connect() {
    if (this.socket && this.isConnected) {
      console.log('Já conectado ao WebSocket');
      return;
    }

    try {
      console.log('Tentando conectar ao WebSocket em:', SOCKET_URL);

      this.socket = io(SOCKET_URL, {
        transports: ['websocket', 'polling'],
        reconnection: true,
        reconnectionAttempts: 5,
        reconnectionDelay: 1000,
      });

      this.socket.on('connect', () => {
        console.log('Conectado ao WebSocket com ID:', this.socket.id);
        this.isConnected = true;
      });

      this.socket.on('disconnect', () => {
        console.log('Desconectado do WebSocket');
        this.isConnected = false;
      });

      this.socket.on('connect_error', (error) => {
        console.error('Erro de conexão WebSocket:', error);
        this.isConnected = false;
      });

      this.socket.on('error', (error) => {
        console.error('Erro no WebSocket:', error);
      });

      console.log('Tentando conectar ao WebSocket em:', SOCKET_URL);
    } catch (error) {
      console.error('Erro ao inicializar WebSocket:', error);
    }
  }

  disconnect() {
    if (this.socket) {
      this.socket.disconnect();
      this.isConnected = false;
      console.log('WebSocket desconectado');
    }
  }

  joinSosRoom(sosId) {
    if (this.socket && this.isConnected) {
      this.socket.emit('join_sos', sosId);
      console.log(`Entrou na sala SOS ${sosId}`);
    } else {
      console.warn('Não é possível entrar na sala SOS: WebSocket não conectado');
    }
  }

  on(event, callback) {
    if (this.socket) {
      this.socket.on(event, callback);
    } else {
      console.warn(`Tentando escutar evento ${event} mas socket não está inicializado`);
    }
  }

  off(event, callback) {
    if (this.socket) {
      this.socket.off(event, callback);
    }
  }

  emit(event, data) {
    if (this.socket && this.isConnected) {
      this.socket.emit(event, data);
    } else {
      console.warn(`Não é possível emitir evento ${event}: WebSocket não conectado`);
    }
  }
}

// Exportar uma instância singleton
export default new SocketService();
