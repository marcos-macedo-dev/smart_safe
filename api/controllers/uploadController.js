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
  if (!file) {
    console.log('[uploadFileToR2] Nenhum arquivo fornecido.');
    return null;
  }
  if (!bucketName) {
    console.error('[uploadFileToR2] R2 bucket name não configurado. Defina R2_BUCKET_NAME.');
    throw new Error('R2 bucket name não configurado. Defina R2_BUCKET_NAME.');
  }

  const prefix = folder ? `${folder}/` : '';
  const objectKey = `${prefix}${Date.now()}-${file.originalname}`;

  console.log(`[uploadFileToR2] Iniciando upload para R2. Key: ${objectKey}, ContentType: ${file.mimetype}`);
  try {
    await r2Client.send(new PutObjectCommand({
      Bucket: bucketName,
      Key: objectKey,
      Body: file.buffer,
      ContentType: file.mimetype,
    }));
    console.log(`[uploadFileToR2] Upload para R2 concluído com sucesso. Key: ${objectKey}`);
    return objectKey;
  } catch (err) {
    console.error(`[uploadFileToR2] Erro ao fazer upload para R2 (Key: ${objectKey}):`, err);
    throw err; // Re-lançar o erro para ser capturado pelo controlador
  }
};

const generateSignedUrl = async (objectKey) => {
  if (!objectKey || objectKey.startsWith('http')) {
    console.log(`[generateSignedUrl] Chave de objeto já é uma URL ou nula: ${objectKey}. Retornando como está.`);
    return objectKey;
  }
  if (!bucketName) {
    console.error('[generateSignedUrl] R2 bucket name não configurado. Defina R2_BUCKET_NAME.');
    throw new Error('R2 bucket name não configurado. Defina R2_BUCKET_NAME.');
  }

  console.log(`[generateSignedUrl] Gerando URL assinada para Key: ${objectKey}`);
  try {
    const command = new GetObjectCommand({
      Bucket: bucketName,
      Key: objectKey,
    });
    const url = await getSignedUrl(r2Client, command, { expiresIn: 60 * 60 * 24 });
    console.log(`[generateSignedUrl] URL assinada gerada com sucesso para Key: ${objectKey}`);
    return url;
  } catch (err) {
    console.error(`[generateSignedUrl] Erro ao gerar URL assinada para Key: ${objectKey}:`, err);
    throw err; // Re-lançar o erro para ser capturado pelo controlador
  }
};

exports.uploadFile = async (req, res) => {
  console.log('[uploadController] Função uploadFile iniciada.');

  if (!req.file) {
    console.warn('[uploadController] NENHUM arquivo recebido na requisição.');
    return res.status(400).json({
      error: 'No file uploaded.'
    });
  }

  console.log(`[uploadController] Arquivo recebido: ${req.file.originalname}, Tamanho: ${req.file.size} bytes, Mimetype: ${req.file.mimetype}`);

  try {
    const file = req.file;
    let folder;
    if (file.mimetype.startsWith('video')) folder = 'video';
    else if (file.mimetype.startsWith('audio')) folder = 'audio';
    else folder = 'foto';
    console.log(`[uploadController] Pasta de destino determinada: ${folder}`);

    const objectKey = await uploadFileToR2(file, folder);
    if (!objectKey) {
      console.error('[uploadController] uploadFileToR2 retornou null ou vazio. Abortando.');
      return res.status(500).json({ error: 'Falha interna no upload do arquivo.' });
    }

    let tipoMidia;
    if (file.mimetype.startsWith('video')) tipoMidia = 'video';
    else if (file.mimetype.startsWith('audio')) tipoMidia = 'audio';
    else tipoMidia = 'foto';
    console.log(`[uploadController] Tipo de mídia determinado: ${tipoMidia}`);

    console.log('[uploadController] Criando registro de mídia no banco de dados...');
    const media = await Media.create({
      caminho: objectKey, // salva o caminho do arquivo no R2
      tipo: tipoMidia,
      sos_id: null, // Será associado ao SOS posteriormente, se for o caso
    });
    console.log(`[uploadController] Registro de mídia criado com ID: ${media.id}, Caminho: ${objectKey}`);

    const signedUrl = await generateSignedUrl(objectKey);
    console.log('[uploadController] URL assinada gerada e retornando resposta.');

    res.status(200).json({ ...media.toJSON(), caminho: signedUrl });
  } catch (error) {
    console.error('[uploadController] Erro geral no processo de upload:', error);
    res.status(500).json({
      error: 'Upload failed',
      details: error.message
    });
  }
};

exports.uploadFileToR2 = uploadFileToR2; // Exportar a função auxiliar
exports.generateSignedUrl = generateSignedUrl;
