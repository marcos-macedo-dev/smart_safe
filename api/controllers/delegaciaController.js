const {
    Delegacia
} = require('../models');
const {
    Op
} = require('sequelize');

/**
 * Registrar uma nova delegacia
 * Body params: { nome, endereco, latitude, longitude, telefone }
 */
exports.create = async (req, res) => {
    try {
        const {
            nome,
            endereco,
            latitude,
            longitude,
            telefone
        } = req.body;

        if (!nome || !endereco || latitude == null || longitude == null || !telefone) {
            return res.status(400).json({
                error: 'Todos os campos são obrigatórios'
            });
        }

        const delegacia = await Delegacia.create({
            nome,
            endereco,
            latitude,
            longitude,
            telefone
        });

        res.status(201).json(delegacia);
    } catch (error) {
        console.error(error);
        res.status(500).json({
            error: 'Erro ao registrar delegacia'
        });
    }
};

/**
 * Listar todas as delegacias
 */
exports.listAll = async (req, res) => {
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
        
        res.status(200).json({
            delegacias: delegacias,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total: count,
                totalPages: Math.ceil(count / limit)
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            error: 'Erro ao buscar delegacias'
        });
    }
};

/**
 * Buscar delegacias próximas de uma posição (lat/lng)
 * Query params: ?latitude=-7.2&longitude=-40.1&radius=5 (km)
 */
exports.findNearby = async (req, res) => {
    try {
        const {
            latitude,
            longitude,
            radius = 5
        } = req.query;
        if (!latitude || !longitude) {
            return res.status(400).json({
                error: 'latitude e longitude são obrigatórios'
            });
        }

        // Fórmula simplificada de distância aproximada em km
        const lat = parseFloat(latitude);
        const lng = parseFloat(longitude);
        const r = parseFloat(radius);

        const delegacias = await Delegacia.findAll();
        const nearby = delegacias.filter(d => {
            const dLat = (d.latitude - lat) * 110.574; // km por grau latitude
            const dLng = (d.longitude - lng) * 111.320 * Math.cos(lat * Math.PI / 180);
            const distance = Math.sqrt(dLat * dLat + dLng * dLng);
            return distance <= r;
        });

        res.json(nearby);
    } catch (error) {
        console.error(error);
        res.status(500).json({
            error: 'Erro ao buscar delegacias próximas'
        });
    }
};

/**
 * Atualizar uma delegacia existente
 * Body params: { nome, endereco, latitude, longitude, telefone }
 */
exports.update = async (req, res) => {
    try {
        const {
            id
        } = req.params;
        const {
            nome,
            endereco,
            latitude,
            longitude,
            telefone
        } = req.body;

        const delegacia = await Delegacia.findByPk(id);
        if (!delegacia) {
            return res.status(404).json({
                error: 'Delegacia não encontrada'
            });
        }

        await delegacia.update({
            nome,
            endereco,
            latitude,
            longitude,
            telefone
        });

        res.status(200).json({
            message: 'Delegacia atualizada com sucesso'
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            error: 'Erro ao atualizar delegacia'
        });
    }
};

/**
 * Deletar uma delegacia existente
 */
exports.delete = async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const delegacia = await Delegacia.findByPk(id);
        if (!delegacia) {
            return res.status(404).json({
                error: 'Delegacia não encontrada'
            });
        }
        await delegacia.destroy();
        res.status(200).json({
            message: 'Delegacia deletada com sucesso'
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            error: 'Erro ao deletar delegacia'
        });
    }
};