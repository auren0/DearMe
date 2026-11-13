FROM node:26-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY server.js ./

RUN mkdir -p /app/data && chown -R node:node /app
USER node

ENV PORT=8787
EXPOSE 8787

CMD ["node", "server.js"]
