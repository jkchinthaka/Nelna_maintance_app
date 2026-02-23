# ============================================
# Nelna Maintenance System - Docker Build
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

# Start app (DATABASE_URL from environment: postgresql://postgres:Chinthaka2002@#@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres)
CMD sh -c "npx prisma db push --skip-generate && npx prisma db seed && node src/server.js"