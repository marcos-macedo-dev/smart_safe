const { Delegacia } = require('../models');
const { Op } = require('sequelize');

module.exports = {
  /**
   * Registrar uma nova delegacia
   */
  async create(req, res) {
    try {
      let { nome, endereco, latitude, longitude, telefone } = req.body;

      if (!nome || !endereco || latitude == null || longitude == null || !telefone) {
        return res.status(400).json({ error: 'Todos os campos são obrigatórios: nome, endereco, latitude, longitude, telefone.' });
      }

      // Sanitização
      nome = nome.trim();
      endereco = endereco.trim();
      telefone = telefone.trim();
      latitude = parseFloat(latitude);
      longitude = parseFloat(longitude);

      if (isNaN(latitude) || isNaN(longitude)) {
        return res.status(400).json({ error: 'Latitude e Longitude devem ser números válidos.' });
      }

      const delegacia = await Delegacia.create({
        nome,
        endereco,
        latitude,
        longitude,
        telefone
      });

      return res.status(201).json(delegacia);

    } catch (error) {
      console.error('Erro em createDelegacia:', error);
      return res.status(500).json({ error: 'Erro interno ao registrar delegacia.' });
    }
  },

  /**
   * Listar todas as delegacias (com paginação)
   */
  async listAll(req, res) {
    try {
      const { page = 1, limit = 100, ativa } = req.query;
      const offset = (page - 1) * limit;
      
      const whereClause = {};
      if (ativa !== undefined) {
        whereClause.ativa = ativa === 'true';
      }
      
      const { count, rows: delegacias } = await Delegacia.findAndCountAll({
        where: whereClause,
        limit: parseInt(limit),
        offset: parseInt(offset),
        order: [['nome', 'ASC']]
      });
      
      return res.json({
        delegacias,
        pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total: count,
            totalPages: Math.ceil(count / limit)
        }
      });

    } catch (error) {
      console.error('Erro em listAllDelegacias:', error);
      return res.status(500).json({ error: 'Erro interno ao buscar delegacias.' });
    }
  },

  /**
   * Buscar delegacias próximas (Geospatial simples)
   */
  async findNearby(req, res) {
    try {
      const { latitude, longitude, radius = 5 } = req.query;

      if (!latitude || !longitude) {
        return res.status(400).json({ error: 'Parâmetros latitude e longitude são obrigatórios.' });
      }

      const lat = parseFloat(latitude);
      const lng = parseFloat(longitude);
      const r = parseFloat(radius);

      if (isNaN(lat) || isNaN(lng) || isNaN(r)) {
        return res.status(400).json({ error: 'Coordenadas ou raio inválidos.' });
      }

      // TODO: Em produção com PostGIS, usar ST_DWithin. 
      // Aqui usamos a fórmula Haversine aproximada no código (menos performático para muitos dados, mas ok para MVP)
      const delegacias = await Delegacia.findAll();
      
      const nearby = delegacias.filter(d => {
        const dLat = (d.latitude - lat) * 110.574; // km por grau latitude
        const dLng = (d.longitude - lng) * 111.320 * Math.cos(lat * Math.PI / 180);
        const distance = Math.sqrt(dLat * dLat + dLng * dLng);
        return distance <= r;
      });

      return res.json(nearby);

    } catch (error) {
      console.error('Erro em findNearbyDelegacias:', error);
      return res.status(500).json({ error: 'Erro interno ao buscar delegacias próximas.' });
    }
  },

  /**
   * Atualizar uma delegacia
   */
  async update(req, res) {
    try {
      const { id } = req.params;
      let { nome, endereco, latitude, longitude, telefone } = req.body;

      const delegacia = await Delegacia.findByPk(id);
      if (!delegacia) {
        return res.status(404).json({ error: 'Delegacia não encontrada.' });
      }

      // Sanitização e updates condicionais
      if (nome) delegacia.nome = nome.trim();
      if (endereco) delegacia.endereco = endereco.trim();
      if (telefone) delegacia.telefone = telefone.trim();
      if (latitude !== undefined) delegacia.latitude = parseFloat(latitude);
      if (longitude !== undefined) delegacia.longitude = parseFloat(longitude);

      await delegacia.save();

      return res.json(delegacia);

    } catch (error) {
      console.error('Erro em updateDelegacia:', error);
      return res.status(500).json({ error: 'Erro interno ao atualizar delegacia.' });
    }
  },

  /**
   * Deletar uma delegacia
   */
  async delete(req, res) {
    try {
      const { id } = req.params;

      const delegacia = await Delegacia.findByPk(id);
      if (!delegacia) {
        return res.status(404).json({ error: 'Delegacia não encontrada.' });
      }

      await delegacia.destroy();
      
      return res.status(200).json({ message: 'Delegacia deletada com sucesso.' });

    } catch (error) {
      console.error('Erro em deleteDelegacia:', error);
      return res.status(500).json({ error: 'Erro interno ao deletar delegacia.' });
    }
  }
};
