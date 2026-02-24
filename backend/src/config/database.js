// ============================================================================
// Nelna Maintenance System - Prisma Database Client
// Serverless-compatible singleton pattern (Vercel / AWS Lambda)
// ============================================================================
const { PrismaClient } = require('@prisma/client');
const config = require('./index');

// Prevent multiple PrismaClient instances in serverless hot-reloads
const globalForPrisma = globalThis;

const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    log:
      config.app.env === 'development'
        ? ['query', 'info', 'warn', 'error']
        : ['error'],
    errorFormat: config.app.env === 'development' ? 'pretty' : 'minimal',
    datasources: {
      db: {
        url: process.env.DATABASE_URL,
      },
    },
  });

if (config.app.env !== 'production') {
  globalForPrisma.prisma = prisma;
}

// Middleware: Soft delete filter
prisma.$use(async (params, next) => {
  // Soft delete: intercept delete calls
  if (params.action === 'delete') {
    const softDeleteModels = [
      'User', 'Vehicle', 'Machine', 'Product', 'Supplier',
      'ServiceRequest', 'Asset', 'Company', 'Branch',
    ];
    if (softDeleteModels.includes(params.model)) {
      params.action = 'update';
      params.args.data = { deletedAt: new Date() };
    }
  }

  // Soft delete: intercept deleteMany calls
  if (params.action === 'deleteMany') {
    const softDeleteModels = [
      'User', 'Vehicle', 'Machine', 'Product', 'Supplier',
      'ServiceRequest', 'Asset', 'Company', 'Branch',
    ];
    if (softDeleteModels.includes(params.model)) {
      params.action = 'updateMany';
      if (params.args.data !== undefined) {
        params.args.data.deletedAt = new Date();
      } else {
        params.args.data = { deletedAt: new Date() };
      }
    }
  }

  return next(params);
});

module.exports = prisma;
