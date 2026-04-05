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
let Sentry = null;
try {
  Sentry = require('@sentry/node');
  if (config.sentry.dsn) {
    Sentry.init({
      dsn: config.sentry.dsn,
      environment: config.app.env,
      tracesSampleRate: config.sentry.tracesRate,
      profilesSampleRate: config.sentry.profilesRate,
      sendDefaultPii: false,
    });
    logger.info('Sentry error monitoring initialised');
  } else {
    Sentry = null; // DSN not set — disable Sentry entirely
  }
} catch (err) {
  logger.warn('Sentry not available, skipping error monitoring');
  Sentry = null;
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

const { v4: uuidv4 } = require('uuid');

const app = express();

// ============================================================================
// Security Middleware
// ============================================================================
app.use(helmet({
  // Block cross-origin resource sharing at the browser level unless the
  // response explicitly permits it (images/attachments served from /uploads
  // are tagged cross-origin so Flutter/web clients can load them).
  crossOriginResourcePolicy: { policy: 'cross-origin' },

  // Content Security Policy — restrict sources to same-origin by default.
  // This is an API-only server so a strict policy is safe.
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'"],
      imgSrc: ["'self'", 'data:', 'blob:'],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"],
      baseUri: ["'self'"],
      formAction: ["'self'"],
      frameAncestors: ["'none'"],
    },
  },

  // HTTP Strict Transport Security — tell browsers to only use HTTPS for 1 yr.
  hsts: {
    maxAge: 31_536_000,
    includeSubDomains: true,
    preload: true,
  },

  // Prevent this API from being embedded in iframes (clickjacking).
  frameguard: { action: 'deny' },

  // Leak no referrer information to third-party URLs.
  referrerPolicy: { policy: 'no-referrer' },

  // Disallow cross-domain Flash/PDF access (legacy, belt-and-braces).
  permittedCrossDomainPolicies: { permittedPolicies: 'none' },
}));
app.use(cors({
  origin: config.cors.origin,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'X-Request-ID'],
  exposedHeaders: ['X-Correlation-ID'],
}));

// ── Correlation-ID middleware ─────────────────────────────────────────────
// Reads X-Request-ID from the client (or generates a new one), binds it to
// req.correlationId, tags the Sentry scope, and echoes it back in the response.
app.use((req, res, next) => {
  const id = req.headers['x-request-id'] || req.headers['x-correlation-id'] || uuidv4();
  req.correlationId = id;
  res.setHeader('X-Correlation-ID', id);
  if (Sentry) {
    Sentry.getCurrentScope().setTag('correlation_id', id);
  }
  next();
});

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
  stream: logger.stream,
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
// Suppress favicon 404s (browsers auto-request these)
app.get('/favicon.ico', (_req, res) => res.status(204).end());
app.get('/favicon.png', (_req, res) => res.status(204).end());
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
// System info: requires authentication + super_admin role
const { authenticate, authorize } = require('./middleware/auth');

app.get(`${API_PREFIX}/system/info`, authenticate, authorize('super_admin'), (req, res) => {
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
if (Sentry) {
  Sentry.setupExpressErrorHandler(app);
}
app.use(errorHandler);

module.exports = app;
