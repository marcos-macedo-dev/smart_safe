require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const {
  Server
} = require('socket.io');
const routes = require('./routes'); // index.js
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*'
  }
});

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Injeta io nas rotas que precisarem (rastreamento de apuros)
app.use('/api', (req, res, next) => {
  req.io = io;
  next();
});
app.use('/api', routes);

app.get('/test', (req, res) => {
  io.emit('teste', 'Oi, eu sou o servidor!');
  res.send('Mensagem enviada para os clientes via WebSocket!');
});

// WebSocket: join em sala do SOS
io.on('connection', (socket) => {
  console.log('Cliente conectado via WebSocket');

  socket.on('join_sos', (sos_id) => {
    socket.join(`sos_${sos_id}`);
    console.log(`Cliente entrou na sala SOS ${sos_id}`);
  });

  socket.on('disconnect', () => {
    console.log('Cliente desconectado do WebSocket');
  });
});

server.listen(3002, () => { console.log('Server running on http://localhost:3002'); });