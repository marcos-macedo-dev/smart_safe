const { Media } = require('../models');
const logAudit = require('../utils/auditLogger');
const { bucket } = require('./uploadController');

// Criar um novo registro de mídia
exports.createMedia = async (req, res) => {
  try {
    let media;
    if (Array.isArray(req.body)) {
      media = await Media.bulkCreate(req.body);
      for (const item of media) {
        await logAudit(req.user ? req.user.id : null, 'CREATE', 'midia', item.id, item.toJSON());
      }
    } else {
      media = await Media.create(req.body);
      await logAudit(req.user ? req.user.id : null, 'CREATE', 'midia', media.id, media.toJSON());
    }
    return res.status(201).json(media);
  } catch (error) {
    console.error('Erro ao criar registro de mídia:', error);
    console.error('Detalhes do erro:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao criar registro de mídia.' });
  }
};

// Obter todos os registros de mídia (opcionalmente por sos_id)
exports.getAllMedia = async (req, res) => {
  try {
    const query = {};
    if (req.query.sos_id) {
      query.sos_id = req.query.sos_id;
    }
    const allMedia = await Media.findAll({
      where: query
    });

    const mediaWithSignedUrls = await Promise.all(
      allMedia.map(async (media) => {
        if (!media.caminho || media.caminho.startsWith('http')) {
          return media;
        }
        const [signedUrl] = await bucket.file(media.caminho).getSignedUrl({
          action: 'read',
          expires: Date.now() + 1000 * 60 * 60 * 24, // 24 horas
        });
        return { ...media.toJSON(),
          caminho: signedUrl
        };
      })
    );

    return res.status(200).json(mediaWithSignedUrls);
  } catch (error) {
    console.error('Erro ao buscar registros de mídia:', error);
    return res.status(500).json({
      error: 'Erro interno do servidor ao buscar registros de mídia.'
    });
  }
};

// Obter um registro de mídia por ID
exports.getMediaById = async (req, res) => {
  try {
    const media = await Media.findByPk(req.params.id);
    if (!media) {
      return res.status(404).json({
        error: 'Registro de mídia não encontrado.'
      });
    }

    if (!media.caminho || media.caminho.startsWith('http')) {
      return res.status(200).json(media);
    }

    const [signedUrl] = await bucket.file(media.caminho).getSignedUrl({
      action: 'read',
      expires: Date.now() + 1000 * 60 * 60 * 24, // 24 horas
    });

    return res.status(200).json({ ...media.toJSON(),
      caminho: signedUrl
    });
  } catch (error) {
    console.error('Erro ao buscar registro de mídia por ID:', error);
    return res.status(500).json({
      error: 'Erro interno do servidor ao buscar registro de mídia por ID.'
    });
  }
};

// Atualizar um registro de mídia por ID
exports.updateMedia = async (req, res) => {
  try {
    const [updated] = await Media.update(req.body, {
      where: { id: req.params.id }
    });
    if (updated) {
      const updatedMedia = await Media.findByPk(req.params.id);
      await logAudit(req.user ? req.user.id : null, 'UPDATE', 'midia', updatedMedia.id, { oldData: req.originalBody, newData: updatedMedia.toJSON() }); // Assuming req.originalBody exists from a middleware
      return res.status(200).json(updatedMedia);
    }
    return res.status(404).json({ error: 'Registro de mídia não encontrado para atualização.' });
  } catch (error) {
    console.error('Erro ao atualizar registro de mídia:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao atualizar registro de mídia.' });
  }
};

// Deletar um registro de mídia por ID
exports.deleteMedia = async (req, res) => {
  try {
    const deleted = await Media.destroy({
      where: { id: req.params.id }
    });
    if (deleted) {
      await logAudit(req.user ? req.user.id : null, 'DELETE', 'midia', req.params.id, { message: 'Registro de mídia deletado' });
      return res.status(204).send(); // No Content
    }
    return res.status(404).json({ error: 'Registro de mídia não encontrado para exclusão.' });
  } catch (error) {
    console.error('Erro ao deletar registro de mídia:', error);
    return res.status(500).json({ error: 'Erro interno do servidor ao deletar registro de mídia.' });
  }
};