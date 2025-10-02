const {
    delegacia_cobertura,
    Delegacias
} = require('../models');

// Criar cobertura
exports.create = async (req, res) => {
    try {
        const cobertura = await delegacia_cobertura.create(req.body);
        return res.status(201).json(cobertura);
    } catch (err) {
        return res.status(400).json({
            error: err.message
        });
    }
};

// Listar todas
exports.findAll = async (req, res) => {
    try {
        const coberturas = await delegacia_cobertura.findAll({
            include: [{
                model: Delegacias,
                as: 'delegacia'
            }]
        });
        return res.json(coberturas);
    } catch (err) {
        return res.status(500).json({
            error: err.message
        });
    }
};

// Buscar por ID
exports.findOne = async (req, res) => {
    try {
        const cobertura = await delegacia_cobertura.findByPk(req.params.id, {
            include: [{
                model: Delegacias,
                as: 'delegacia'
            }]
        });
        if (!cobertura) return res.status(404).json({
            error: 'Cobertura não encontrada'
        });
        return res.json(cobertura);
    } catch (err) {
        return res.status(500).json({
            error: err.message
        });
    }
};

// Atualizar
exports.update = async (req, res) => {
    try {
        const cobertura = await delegacia_cobertura.findByPk(req.params.id);
        if (!cobertura) return res.status(404).json({
            error: 'Cobertura não encontrada'
        });

        await cobertura.update(req.body);
        return res.json(cobertura);
    } catch (err) {
        return res.status(400).json({
            error: err.message
        });
    }
};

// Deletar
exports.delete = async (req, res) => {
    try {
        const cobertura = await delegacia_cobertura.findByPk(req.params.id);
        if (!cobertura) return res.status(404).json({
            error: 'Cobertura não encontrada'
        });

        await cobertura.destroy();
        return res.status(204).send();
    } catch (err) {
        return res.status(500).json({
            error: err.message
        });
    }
};
