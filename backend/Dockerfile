# ============================================
# Nelna Maintenance Management System - Backend
# Multi-stage production Dockerfile
# ============================================

# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache python3 make g++

# Copy package files first for better caching
COPY package*.json ./
COPY prisma ./prisma/

# Install all dependencies (including devDependencies for prisma generate)
RUN npm ci

# Generate Prisma client
RUN npx prisma generate

# Copy source code
COPY . .

# Stage 2: Production
FROM node:20-alpine AS production

# Add labels
LABEL maintainer="Nelna Company IT <it@nelna.com>"
LABEL description="Nelna Maintenance Management System API"
LABEL version="1.0.0"

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nelna -u 1001 -G nodejs

WORKDIR /app

# Install production dependencies only
COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci --only=production && \
    npx prisma generate && \
    npm cache clean --force

# Copy source from builder
COPY --from=builder /app/src ./src

# Create necessary directories
RUN mkdir -p logs uploads && \
    chown -R nelna:nodejs /app

# Switch to non-root user
USER nelna

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/v1/health || exit 1

# Start command
CMD ["node", "src/server.js"]
