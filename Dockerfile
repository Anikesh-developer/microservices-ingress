# Stage 1: Build
FROM node:20 AS build

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Stage 2: Production
FROM node:20-slim

WORKDIR /app

# Copy everything from build stage
COPY --from=build /app . 

EXPOSE 80
CMD ["node", "index.js"]
