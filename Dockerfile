# Stage 1: Build stage
FROM node:20 AS build

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
# RUN npm run build   # creates /app/build

# Stage 2: Production stage
FROM node:20-slim

WORKDIR /app

# Install a lightweight static server
RUN npm install -g serve

# Copy only the production build from Stage 1
COPY --from=build /app/package*.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app . 

EXPOSE 80
CMD ["npm", "start"]
