FROM node:20-alpine

WORKDIR /app

# Instalar dependências do sistema necessárias para compilação (se houver módulos nativos)
RUN apk add --no-cache python3 make g++

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3002

CMD ["node", "server.js"]
