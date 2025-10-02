const express = require('express');
const router = express.Router();
const delegaciaController = require('../controllers/delegaciaController');

// rota para criar delegacia
router.post('/', delegaciaController.create); 

// Listar todas
router.get('/', delegaciaController.listAll);

// Buscar próximas
router.get('/proximas', delegaciaController.findNearby);

// Atualizar uma delegacia
router.put('/:id', delegaciaController.update);

// Deletar uma delegacia
router.delete('/:id', delegaciaController.delete);

module.exports = router;
