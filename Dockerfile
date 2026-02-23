# ============================================
# Nelna Maintenance System - Render Deployment
# ============================================
FROM node:20-alpine

WORKDIR /app

# Copy backend package files
COPY backend/package*.json ./
COPY backend/prisma ./prisma/

# Install dependencies
RUN npm ci --only=production

# Generate Prisma client
RUN npx prisma generate

# Copy backend source
COPY backend/src ./src
COPY backend/prisma ./prisma

# Expose port
EXPOSE 3000

# Start: push schema, seed (idempotent), then run server
CMD npx prisma db push --skip-generate && node prisma/seed.js && node src/server.js
