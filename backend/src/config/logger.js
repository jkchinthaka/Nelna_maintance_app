// ============================================================================
// Nelna Maintenance System - Winston Logger Configuration
// ============================================================================
const winston = require('winston');
const path = require('path');
const config = require('./index');

const logDir = config.logging.dir;

const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.json()
);

const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'HH:mm:ss' }),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    const metaStr = Object.keys(meta).length ? JSON.stringify(meta) : '';
    return `${timestamp} [${level}]: ${message} ${metaStr}`;
  })
);

// Vercel / serverless environments have a read-only filesystem.
// Use file transports only when NOT running on Vercel.
const isServerless = !!process.env.VERCEL;

const transports = [];

if (!isServerless) {
  transports.push(
    // Error log file
    new winston.transports.File({
      filename: path.join(logDir, 'error.log'),
      level: 'error',
      maxsize: 5242880, // 5MB
      maxFiles: 10,
    }),
    // Combined log file
    new winston.transports.File({
      filename: path.join(logDir, 'combined.log'),
      maxsize: 10485760, // 10MB
      maxFiles: 20,
    }),
    // Audit log file
    new winston.transports.File({
      filename: path.join(logDir, 'audit.log'),
      level: 'info',
      maxsize: 10485760,
      maxFiles: 30,
    }),
  );
}

// Always add console transport (Vercel captures stdout/stderr automatically)
if (config.app.env !== 'production' || isServerless) {
  transports.push(
    new winston.transports.Console({
      format: consoleFormat,
    })
  );
}

const logger = winston.createLogger({
  level: config.logging.level,
  format: logFormat,
  defaultMeta: { service: config.app.name },
  transports,
});

module.exports = logger;
