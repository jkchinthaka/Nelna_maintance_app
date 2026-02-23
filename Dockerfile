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

# Generate Prisma client
# Note: Prisma generate doesn't need a valid DATABASE_URL, it just generates the client
RUN npx prisma generate

# Copy backend source
COPY backend/src ./src

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/v1/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Start: validate env, push schema, seed, then run server
# DATABASE_URL must be provided as environment variable from Render
CMD sh -c " \
  if [ -z \"\$DATABASE_URL\" ]; then \
    echo '❌ ERROR: DATABASE_URL environment variable not set'; \
    echo 'Please set DATABASE_URL in Render dashboard'; \
    exit 1; \
  fi && \
  echo '✅ DATABASE_URL is set' && \
  npx prisma db push --skip-generate && \
  npx prisma db seed && \
  node src/server.js \
"