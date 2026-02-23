# ============================================
# Nelna Maintenance System - Render Deployment
# ============================================

FROM node:20-alpine

# Install OpenSSL (Prisma requirement on Alpine)
RUN apk add --no-cache openssl

WORKDIR /app

# Copy package files first (better layer caching)
COPY backend/package*.json ./
COPY backend/prisma ./prisma/

# Install dependencies
RUN npm ci

# Generate Prisma client
RUN npx prisma generate

# Copy backend source
COPY backend/src ./src

# Expose port
EXPOSE 3000

# Start app (DATABASE_URL comes from Render environment variables)
CMD sh -c "npx prisma db push --skip-generate && node prisma/seed.js && node src/server.js"