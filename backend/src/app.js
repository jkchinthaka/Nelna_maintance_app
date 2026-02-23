// ============================================================================
// Nelna Maintenance System - Express Application Setup
// ============================================================================
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const path = require('path');

const config = require('./config');
const logger = require('./config/logger');
const errorHandler = require('./middleware/errorHandler');
const { NotFoundError } = require('./utils/errors');

// ── Sentry error monitoring (optional) ──────────────────────────────────────
const Sentry = require('@sentry/node');
if (config.sentry.dsn) {
  Sentry.init({
    dsn: config.sentry.dsn,
    environment: config.app.env,
    tracesSampleRate: config.app.env === 'production' ? 0.2 : 1.0,
  });
  logger.info('Sentry error monitoring initialised');
}

// Import routes
const authRoutes = require('./routes/auth.routes');
const vehicleRoutes = require('./routes/vehicle.routes');
const machineRoutes = require('./routes/machine.routes');
const serviceRoutes = require('./routes/service.routes');
const inventoryRoutes = require('./routes/inventory.routes');
const assetRoutes = require('./routes/asset.routes');
const reportRoutes = require('./routes/report.routes');
const uploadRoutes = require('./routes/upload.routes');
const roleRoutes = require('./routes/role.routes');

const app = express();

// ============================================================================
// Security Middleware
// ============================================================================
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));
app.use(cors({
  origin: config.cors.origin,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.max,
  message: {
    success: false,
    message: 'Too many requests, please try again later',
    errorCode: 'RATE_LIMIT_EXCEEDED',
  },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

// Stricter rate limiting for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20,
  message: {
    success: false,
    message: 'Too many authentication attempts, please try again later',
    errorCode: 'AUTH_RATE_LIMIT_EXCEEDED',
  },
});
app.use('/api/v1/auth/login', authLimiter);
app.use('/api/v1/auth/register', authLimiter);

// ============================================================================
// Body Parsing & Compression
// ============================================================================
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(compression());

// ============================================================================
// Request Logging
// ============================================================================
const morganFormat = config.app.env === 'production' ? 'combined' : 'dev';
app.use(morgan(morganFormat, {
  stream: { write: (message) => logger.info(message.trim()) },
  skip: (req) => req.url === '/api/v1/health',
}));

// ============================================================================
// Static Files
// ============================================================================
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

// ============================================================================
// Root Route (health check for Render / load balancers)
// ============================================================================
app.all('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Nelna Maintenance System API',
    api: '/api/v1',
    health: '/api/v1/health',
  });
});

// ============================================================================
// API Routes
// ============================================================================
const API_PREFIX = '/api/v1';

app.use(`${API_PREFIX}/auth`, authRoutes);
app.use(`${API_PREFIX}/vehicles`, vehicleRoutes);
app.use(`${API_PREFIX}/machines`, machineRoutes);
app.use(`${API_PREFIX}/services`, serviceRoutes);
app.use(`${API_PREFIX}/inventory`, inventoryRoutes);
app.use(`${API_PREFIX}/assets`, assetRoutes);
app.use(`${API_PREFIX}/reports`, reportRoutes);
app.use(`${API_PREFIX}/uploads`, uploadRoutes);
app.use(`${API_PREFIX}/roles`, roleRoutes);

// ============================================================================
// Health Check
// ============================================================================
app.get(`${API_PREFIX}/health`, (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Nelna Maintenance System API is running',
    data: {
      name: config.app.name,
      version: config.app.version,
      environment: config.app.env,
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    },
  });
});

// ============================================================================
// System Info (Admin only)
// ============================================================================
app.get(`${API_PREFIX}/system/info`, (req, res) => {
  res.status(200).json({
    success: true,
    data: {
      nodeVersion: process.version,
      platform: process.platform,
      memory: process.memoryUsage(),
      uptime: process.uptime(),
    },
  });
});

// ============================================================================
// 404 Handler
// ============================================================================
app.use('*', (req, res, next) => {
  next(new NotFoundError(`Route ${req.originalUrl} not found`));
});

// ============================================================================
// Global Error Handler
// ============================================================================
// Report errors to Sentry (when configured) before Express handles them
if (config.sentry.dsn) {
  Sentry.setupExpressErrorHandler(app);
}
app.use(errorHandler);

module.exports = app;
