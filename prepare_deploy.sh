#!/bin/bash

# Nome do arquivo de saída
OUTPUT_FILE="deploy_bundle.tar.gz"

echo "📦 Preparando pacote de deploy..."

# Verifica se o arquivo compose existe
if [ ! -f "docker-compose.server.yml" ]; then
    echo "❌ Erro: docker-compose.server.yml não encontrado."
    exit 1
fi

# Cria o arquivo tar.gz excluindo node_modules locais e outros arquivos desnecessários
tar --exclude='api/node_modules' \
    --exclude='api/.git' \
    --exclude='api/.env' \
    -czvf $OUTPUT_FILE \
    api \
    docker-compose.server.yml

echo ""
echo "✅ Pacote criado com sucesso: $OUTPUT_FILE"
echo ""
echo "🚀 Instruções para Deploy:"
echo "1. Envie o arquivo para sua VM: scp $OUTPUT_FILE user@sua-vm-ip:~ /"
echo "2. Acesse a VM: ssh user@sua-vm-ip"
echo "3. Descompacte: tar -xzvf $OUTPUT_FILE"
echo "4. Suba os containers: docker-compose -f docker-compose.server.yml up -d --build"
