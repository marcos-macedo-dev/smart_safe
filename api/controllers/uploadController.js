const { S3Client, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { Media } = require('../models');

const REQUIRED_ENV_VARS = ['R2_ENDPOINT', 'R2_ACCESS_KEY_ID', 'R2_SECRET_ACCESS_KEY', 'R2_BUCKET_NAME'];

const missingEnv = REQUIRED_ENV_VARS.filter((key) => !process.env[key]);
if (missingEnv.length > 0) {
  console.warn('[storage] Missing Cloudflare R2 environment variables:', missingEnv.join(', '));
}

const r2Client = new S3Client({
  region: process.env.R2_REGION || 'auto',
  endpoint: process.env.R2_ENDPOINT,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID,
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
  },
  forcePathStyle: true,
});

const bucketName = process.env.R2_BUCKET_NAME;

// Função auxiliar para fazer upload de arquivo para o R2 e retornar a key
const uploadFileToR2 = async (file, folder) => {
  if (!file) return null;
  if (!bucketName) {
    throw new Error('R2 bucket name não configurado. Defina R2_BUCKET_NAME.');
  }

  const prefix = folder ? `${folder}/` : '';
  const objectKey = `${prefix}${Date.now()}-${file.originalname}`;

  await r2Client.send(new PutObjectCommand({
    Bucket: bucketName,
    Key: objectKey,
    Body: file.buffer,
    ContentType: file.mimetype,
  }));

  return objectKey;
};

const generateSignedUrl = async (objectKey) => {
  if (!objectKey || objectKey.startsWith('http')) return objectKey;
  if (!bucketName) {
    throw new Error('R2 bucket name não configurado. Defina R2_BUCKET_NAME.');
  }

  const command = new GetObjectCommand({
    Bucket: bucketName,
    Key: objectKey,
  });

  return getSignedUrl(r2Client, command, { expiresIn: 60 * 60 * 24 });
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

    const objectKey = await uploadFileToR2(file, folder);

    let tipoMidia;
    if (file.mimetype.startsWith('video')) tipoMidia = 'video';
    else if (file.mimetype.startsWith('audio')) tipoMidia = 'audio';
    else tipoMidia = 'foto';

    const media = await Media.create({
      caminho: objectKey, // salva o caminho do arquivo no R2
      tipo: tipoMidia,
      sos_id: null,
    });

    const signedUrl = await generateSignedUrl(objectKey);

    res.status(200).json({ ...media.toJSON(), caminho: signedUrl });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      error: 'Upload failed'
    });
  }
};

exports.uploadFileToR2 = uploadFileToR2; // Exportar a função auxiliar
exports.generateSignedUrl = generateSignedUrl;
