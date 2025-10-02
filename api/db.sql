-- Excluir o banco de dados se ele já existir (opcional, para um começo limpo)
DROP DATABASE IF EXISTS smart_safe;

-- Criar o banco de dados
CREATE DATABASE IF NOT EXISTS smart_safe;

-- Usar o banco de dados recém-criado
USE smart_safe;

-- Tabela de Usuários (sem dependências externas)
CREATE TABLE IF NOT EXISTS `usuarios` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nome_completo` VARCHAR(150) NOT NULL,
  `email` VARCHAR(150) NOT NULL UNIQUE,
  `senha` VARCHAR(255) NOT NULL,
  `telefone` VARCHAR(20) NOT NULL UNIQUE,
  `cidade` VARCHAR(100) NOT NULL,
  `estado` VARCHAR(50) NOT NULL,
  `endereco` VARCHAR(255) NULL,
  `genero` ENUM('Feminino', 'Nao_Binario', 'Outro') NOT NULL DEFAULT 'Outro',
  `cor` ENUM('Branca', 'Preta', 'Parda', 'Amarela', 'Indigena', 'Outra') NOT NULL DEFAULT 'outra',
  `documento_identificacao` VARCHAR(50) NULL,
  `consentimento` BOOLEAN NOT NULL DEFAULT false,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);

-- Tabela de Delegacias (sem dependências externas)
CREATE TABLE IF NOT EXISTS `Delegacias` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(255) NOT NULL,
  `endereco` VARCHAR(255) NOT NULL,
  `latitude` DOUBLE NOT NULL,
  `longitude` DOUBLE NOT NULL,
  `telefone` VARCHAR(255) NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);

-- Tabela de Registro de Auditoria (sem dependências externas diretas com FK)
CREATE TABLE IF NOT EXISTS `registro_auditoria` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ator_id` BIGINT UNSIGNED NOT NULL,
  `acao` VARCHAR(50) NOT NULL,
  `tipo_alvo` VARCHAR(50) NOT NULL,
  `id_alvo` BIGINT UNSIGNED NOT NULL,
  `detalhes` JSON NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);

-- Tabela de Contatos de Emergência (depende de `usuarios`)
CREATE TABLE IF NOT EXISTS `contatos_emergencia` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `usuario_id` BIGINT UNSIGNED NOT NULL,
  `nome` VARCHAR(150) NOT NULL,
  `telefone` VARCHAR(20) NOT NULL,
  `parentesco` VARCHAR(50) NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`usuario_id`) REFERENCES `usuarios`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Tabela de SOS (depende de `usuarios`)
CREATE TABLE IF NOT EXISTS `sos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `usuario_id` BIGINT UNSIGNED NOT NULL,
  `caminho_audio` TEXT NULL,
  `caminho_video` TEXT NULL,
  `latitude` DECIMAL(10, 8) NULL,
  `longitude` DECIMAL(11, 8) NULL,
  `status` ENUM('pendente', 'ativo', 'aguardando_autoridade', 'fechado', 'cancelado') NOT NULL DEFAULT 'pendente',
  `encerrado_em` DATETIME NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`usuario_id`) REFERENCES `usuarios`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Tabela de Mídia (depende de `sos`)
CREATE TABLE IF NOT EXISTS `midia` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `sos_id` BIGINT UNSIGNED NULL,
  `tipo` ENUM('foto', 'video', 'audio') NOT NULL,
  `caminho` TEXT NOT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`sos_id`) REFERENCES `sos`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Tabela de Localizações de Incidentes (depende de `sos`)
CREATE TABLE IF NOT EXISTS `localizacoes_incidente` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `sos_id` BIGINT UNSIGNED NOT NULL,
  `latitude` DECIMAL(10, 8) NOT NULL,
  `longitude` DECIMAL(11, 8) NOT NULL,
  `precisao` DECIMAL(5, 2) NULL,
  `nivel_bateria` DECIMAL(5, 2) NULL,
  `registrado_em` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`sos_id`) REFERENCES `sos`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Tabela de Rastreamento de Apuros (depende de `sos`)
CREATE TABLE IF NOT EXISTS `rastreamento_apuros` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `sos_id` BIGINT UNSIGNED NOT NULL,
  `latitude` DECIMAL(10, 8) NOT NULL,
  `longitude` DECIMAL(11, 8) NOT NULL,
  `precisao` DECIMAL(5, 2) NULL,
  `nivel_bateria` DECIMAL(5, 2) NULL,
  `registrado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`sos_id`) REFERENCES `sos`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
);
