const {
  Storage
} = require('@google-cloud/storage');
const path = require('path');
const {
  Media
} = require('../models');

const storage = new Storage({
  keyFilename: path.join(__dirname, '../config/synthetic-diode-466014-j9-63af3654359a.json'),
});
const bucket = storage.bucket('smart_safe_files'); // nome do bucket

// Função auxiliar para fazer upload de arquivo para o GCS e retornar a URL
const uploadFileToGCS = async (file, folder) => {
  if (!file) return null;

  const prefix = folder ? `${folder}/` : '';
  const gcsFileName = `${prefix}${Date.now()}-${file.originalname}`;
  const gcsFile = bucket.file(gcsFileName);

  const stream = gcsFile.createWriteStream({
    resumable: false,
    metadata: {
      contentType: file.mimetype
    },
  });

  return new Promise((resolve, reject) => {
    stream.on('error', (err) => reject(err));
    stream.on('finish', () => {
      resolve(gcsFileName);
    });
    stream.end(file.buffer);
  });
};

exports.uploadFile = async (req, res) => {
  if (!req.file) return res.status(400).json({
    error: 'No file uploaded.'
  });

  try {
    const file = req.file;
    let folder;
    if (file.mimetype.startsWith('video')) folder = 'video';
    else if (file.mimetype.startsWith('audio')) folder = 'audio';
    else folder = 'foto';

    const gcsFileName = await uploadFileToGCS(file, folder);

    let tipoMidia;
    if (file.mimetype.startsWith('video')) tipoMidia = 'video';
    else if (file.mimetype.startsWith('audio')) tipoMidia = 'audio';
    else tipoMidia = 'foto';

    const media = await Media.create({
      caminho: gcsFileName, // salva o caminho do arquivo no GCS
      tipo: tipoMidia,
      sos_id: null,
    });

    const [signedUrl] = await bucket.file(gcsFileName).getSignedUrl({
      action: 'read',
      expires: Date.now() + 1000 * 60 * 60 * 24, // 24 horas de validade
    });

    res.status(200).json({ ...media.toJSON(), caminho: signedUrl });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      error: 'Upload failed'
    });
  }
};

exports.uploadFileToGCS = uploadFileToGCS; // Exportar a função auxiliar
exports.bucket = bucket; // Exportar o bucket para uso em outros controllers
