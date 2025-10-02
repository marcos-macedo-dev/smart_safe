const { RastreamentoApuros } = require('../models');

class RastreamentoApurosController {

  // Criar novo ponto de rastreamento
  static async create(req, res) {
    try {
      const io = req.io; // pega io injetado pelo middleware do server.js
      const { sos_id, latitude, longitude, precisao, nivel_bateria } = req.body;

      if (!sos_id || !latitude || !longitude) {
        return res.status(400).json({ error: 'sos_id, latitude e longitude são obrigatórios.' });
      }

      const novoRastreamento = await RastreamentoApuros.create({
        sos_id,
        latitude,
        longitude,
        precisao,
        nivel_bateria,
        registrado_em: new Date()
      });

      // Emite atualização em tempo real via WebSocket
      if (io) {
        io.to(`sos_${sos_id}`).emit('rastreamento_update', novoRastreamento);
      }

      return res.status(201).json(novoRastreamento);
    } catch (error) {
      console.error('Erro ao criar rastreamento:', error);
      return res.status(500).json({ error: 'Erro ao criar rastreamento.' });
    }
  }

  // Listar todos os rastreamentos de um SOS
  static async getBySos(req, res) {
    try {
      const { sos_id } = req.params;

      if (!sos_id) {
        return res.status(400).json({ error: 'sos_id é obrigatório.' });
      }

      const rastreamentos = await RastreamentoApuros.findAll({
        where: { sos_id },
        order: [['registrado_em', 'ASC']]
      });

      return res.json(rastreamentos);
    } catch (error) {
      console.error('Erro ao buscar rastreamentos:', error);
      return res.status(500).json({ error: 'Erro ao buscar rastreamentos.' });
    }
  }
}

module.exports = RastreamentoApurosController;
