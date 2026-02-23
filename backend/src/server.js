// ============================================================================
// Nelna Maintenance System - Server Entry Point
// ============================================================================
const app = require('./app');
const config = require('./config');
const logger = require('./config/logger');
const prisma = require('./config/database');

const PORT = config.app.port;
const MAX_RETRIES = 5;
const RETRY_DELAY_MS = 3000; // 3 seconds, increases with each retry

async function connectWithRetry() {
  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      await prisma.$connect();
      logger.info('✅ Database connection established successfully');
      return;
    } catch (error) {
      if (attempt === MAX_RETRIES) {
        throw error;
      }
      const delay = RETRY_DELAY_MS * attempt;
      logger.warn(
        `⏳ Database connection attempt ${attempt}/${MAX_RETRIES} failed: ${error.message}. Retrying in ${delay / 1000}s...`
      );
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }
}

async function startServer() {
  try {
    // Test database connection with retry
    await connectWithRetry();

    // Start HTTP server
    const server = app.listen(PORT, () => {
      logger.info(`🚀 ${config.app.name} v${config.app.version} started`);
      logger.info(`📡 Environment: ${config.app.env}`);
      logger.info(`🌐 Server running on http://localhost:${PORT}`);
      logger.info(`📋 API Base: http://localhost:${PORT}/api/v1`);
      logger.info(`❤️  Health Check: http://localhost:${PORT}/api/v1/health`);
    });

    // Graceful shutdown
    const gracefulShutdown = async (signal) => {
      logger.info(`\n${signal} received. Starting graceful shutdown...`);

      server.close(async () => {
        logger.info('HTTP server closed');
        await prisma.$disconnect();
        logger.info('Database connection closed');
        process.exit(0);
      });

      // Force shutdown after 30 seconds
      setTimeout(() => {
        logger.error('Forced shutdown after timeout');
        process.exit(1);
      }, 30000);
    };

    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));

    // Handle unhandled rejections
    process.on('unhandledRejection', (reason, promise) => {
      logger.error('Unhandled Rejection at:', { promise, reason: reason?.message || reason });
    });

    // Handle uncaught exceptions
    process.on('uncaughtException', (error) => {
      logger.error('Uncaught Exception:', { message: error.message, stack: error.stack });
      gracefulShutdown('uncaughtException');
    });

  } catch (error) {
    logger.error('❌ Failed to start server:', { message: error.message, stack: error.stack });
    await prisma.$disconnect();
    process.exit(1);
  }
}

startServer();
