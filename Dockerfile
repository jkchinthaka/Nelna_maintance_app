# ============================================
# Nelna Maintenance System - Render Deployment
# ============================================
FROM node:20-alpine

# Install OpenSSL (required by Prisma on Alpine)
RUN apk add --no-cache openssl

WORKDIR /app

# Copy package files and prisma schema first (for Docker layer caching)
COPY backend/package*.json ./
COPY backend/prisma ./prisma/

# Install ALL dependencies (prisma CLI is a devDependency needed for generate & db push)
RUN npm ci

# Generate Prisma client (dummy DATABASE_URL needed at build time; real one is set at runtime)
ENV DATABASE_URL=postgresql://postgres:Chinthaka2002@#@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres
RUN npx prisma generate
ENV DATABASE_URL=""

# Copy backend source
COPY backend/src ./src

# Expose port
EXPOSE 3000

# Start: push schema, seed (idempotent), then run server
CMD sh -c "npx prisma db push --skip-generate && node prisma/seed.js && node src/server.js"
