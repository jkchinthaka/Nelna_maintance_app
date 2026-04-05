// ============================================================================
// Nelna Maintenance System - Audit Logger Middleware
// ============================================================================
const prisma = require('../config/database');
const logger = require('../config/logger');

// Fields that must NEVER appear in audit logs (security)
const SENSITIVE_KEYS = new Set([
  'password', 'passwordHash', 'password_hash', 'currentPassword', 'newPassword',
  'refreshToken', 'refresh_token', 'accessToken', 'token', 'secret',
  'fcmToken', 'fcm_token', 'passwordResetToken', 'password_reset_token',
  'privateKey', 'private_key', 'creditCard', 'cvv', '_ip', '_userAgent',
]);

/**
 * Produce a JSON string safe for audit storage.
 * Strips sensitive keys and private underscore metadata.
 * @param {*} value
 * @returns {string|null}
 */
function toAuditJson(value) {
  if (value === null || value === undefined) return null;
  try {
    return JSON.stringify(value, (key, val) => {
      if (SENSITIVE_KEYS.has(key) || key.startsWith('_')) return '[REDACTED]';
      return val;
    });
  } catch {
    return null;
  }
}

// Allowlisted Prisma model names for captureOldValues (prevents prototype injection)
const AUDITABLE_MODELS = new Set([
  'user', 'vehicle', 'machine', 'asset', 'product', 'supplier',
  'serviceRequest', 'purchaseOrder', 'expense', 'branch', 'company',
]);

/**
 * Log audit trail for data mutations
 * @param {string} action - CREATE, UPDATE, DELETE
 * @param {string} module - Module name
 * @param {string} entityType - Entity type (e.g., 'Vehicle')
 */
const auditLog = (action, module, entityType) => async (req, res, next) => {
  // Store original json method
  const originalJson = res.json.bind(res);

  res.json = async function (body) {
    try {
      if (body.success && req.user) {
        await prisma.auditLog.create({
          data: {
            userId: req.user.id,
            action,
            module,
            entityType,
            entityId: body.data?.id || parseInt(req.params.id, 10) || null,
            // Stored as NVarChar(Max) JSON strings in SQL Server
            oldValues: toAuditJson(req._auditOldValues || null),
            newValues: action !== 'DELETE' ? toAuditJson(req.body || null) : null,
            ipAddress: req.ip || req.socket?.remoteAddress || null,
            userAgent: (req.headers['user-agent'] || '').slice(0, 500) || null,
          },
        });
      }
    } catch (error) {
      logger.error('Audit log creation failed', { error: error.message });
    }

    return originalJson(body);
  };

  next();
};

/**
 * Capture existing data before update/delete for audit trail.
 * Only operates on allowlisted model names to prevent prototype injection.
 * @param {string} model - Prisma model name (must be in AUDITABLE_MODELS)
 */
const captureOldValues = (model) => async (req, res, next) => {
  try {
    const id = parseInt(req.params.id, 10);

    if (!AUDITABLE_MODELS.has(model)) {
      logger.warn(`Audit: Model "${model}" is not in the audit allowlist — skipping.`);
      return next();
    }

    if (id && prisma[model] && typeof prisma[model].findUnique === 'function') {
      const oldRecord = await prisma[model].findUnique({ where: { id } });
      req._auditOldValues = oldRecord;
    }
  } catch (error) {
    logger.error('Capture old values failed', { error: error.message, model });
  }
  next();
};

module.exports = { auditLog, captureOldValues };
