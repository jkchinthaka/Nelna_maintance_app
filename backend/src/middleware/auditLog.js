// ============================================================================
// Nelna Maintenance System - Audit Logger Middleware
// ============================================================================
const prisma = require('../config/database');
const logger = require('../config/logger');

/**
 * Log audit trail for data mutations
 * @param {string} action - CREATE, UPDATE, DELETE
 * @param {string} module - Module name
 * @param {string} entityType - Entity type (e.g., 'Vehicle')
 */
const auditLog = (action, module, entityType) => {
  return async (req, res, next) => {
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
              oldValues: req._auditOldValues || null,
              newValues: action !== 'DELETE' ? (req.body || null) : null,
              ipAddress: req.ip || req.connection?.remoteAddress,
              userAgent: req.headers['user-agent'] || null,
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
};

/**
 * Capture existing data before update/delete for audit trail
 * @param {string} model - Prisma model name
 */
const captureOldValues = (model) => {
  return async (req, res, next) => {
    try {
      const id = parseInt(req.params.id, 10);
      if (id && prisma[model]) {
        const oldRecord = await prisma[model].findUnique({ where: { id } });
        req._auditOldValues = oldRecord;
      }
    } catch (error) {
      logger.error('Capture old values failed', { error: error.message });
    }
    next();
  };
};

module.exports = { auditLog, captureOldValues };
