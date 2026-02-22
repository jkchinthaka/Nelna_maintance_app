// ============================================================================
// Nelna Maintenance System - Environment Configuration
// ============================================================================
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const config = {
  app: {
    name: process.env.APP_NAME || 'Nelna Maintenance System',
    version: process.env.APP_VERSION || '1.0.0',
    env: process.env.NODE_ENV || 'development',
    port: parseInt(process.env.PORT, 10) || 3000,
  },
  db: {
    url: process.env.DATABASE_URL,
  },
  jwt: {
    secret: process.env.JWT_SECRET,
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    expiry: process.env.JWT_EXPIRY || '24h',
    refreshExpiry: process.env.JWT_REFRESH_EXPIRY || '7d',
  },
  cors: {
    origin: process.env.CORS_ORIGIN
      ? process.env.CORS_ORIGIN.split(',')
      : ['http://localhost:3000'],
  },
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS, 10) || 900000,
    max: parseInt(process.env.RATE_LIMIT_MAX, 10) || 100,
  },
  upload: {
    maxSize: parseInt(process.env.UPLOAD_MAX_SIZE, 10) || 10485760,
    path: process.env.UPLOAD_PATH || './uploads',
  },
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    dir: process.env.LOG_DIR || './logs',
  },
  mail: {
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT, 10) || 587,
    secure: process.env.SMTP_SECURE === 'true',
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
    from: process.env.SMTP_FROM || 'noreply@nelna.com',
  },
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID,
    privateKey: process.env.FIREBASE_PRIVATE_KEY,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  },
};

// Validate required configuration
const requiredConfigs = ['jwt.secret', 'jwt.refreshSecret', 'db.url'];
for (const key of requiredConfigs) {
  const keys = key.split('.');
  let value = config;
  for (const k of keys) {
    value = value?.[k];
  }
  if (!value) {
    if (config.app.env === 'production') {
      throw new Error(`Missing required configuration: ${key}`);
    }
    console.warn(`⚠️  Warning: Missing configuration: ${key}`);
  }
}

module.exports = config;
