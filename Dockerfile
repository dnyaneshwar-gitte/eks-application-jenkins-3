FROM node:20

WORKDIR /opt

COPY . .

RUN npm install

EXPOSE 3000

CMD ["npx", "vite", "--host"]