# ============================================
# Nelna Maintenance System - Render Deployment
# ============================================
FROM node:20-alpine

WORKDIR /app

# Copy backend package files and prisma schema
COPY backend/package*.json ./
COPY backend/prisma ./prisma/

# Install ALL dependencies (prisma CLI is a devDependency needed for generate & db push)
RUN npm ci

# Generate Prisma client
RUN npx prisma generate

# Copy backend source
COPY backend/src ./src

# Expose port
EXPOSE 3000

# Start: push schema, seed (idempotent), then run server
CMD sh -c "npx prisma db push --skip-generate && node prisma/seed.js && node src/server.js"
