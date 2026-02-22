// ============================================================================
// Nelna Maintenance System - JWT Authentication Middleware
// ============================================================================
const jwt = require('jsonwebtoken');
const config = require('../config');
const prisma = require('../config/database');
const { UnauthorizedError, ForbiddenError } = require('../utils/errors');

/**
 * Authenticate JWT token from Authorization header
 */
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedError('Access token is required');
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      throw new UnauthorizedError('Access token is required');
    }

    const decoded = jwt.verify(token, config.jwt.secret);

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      include: {
        role: {
          include: {
            permissions: {
              include: {
                permission: true,
              },
            },
          },
        },
        company: true,
        branch: true,
      },
    });

    if (!user || !user.isActive || user.deletedAt) {
      throw new UnauthorizedError('User account is inactive or not found');
    }

    // Attach user and permissions to request
    req.user = {
      id: user.id,
      companyId: user.companyId,
      branchId: user.branchId,
      roleId: user.roleId,
      roleName: user.role.name,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      permissions: user.role.permissions.map((rp) => ({
        module: rp.permission.module,
        action: rp.permission.action,
        resource: rp.permission.resource,
      })),
    };

    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return next(new UnauthorizedError('Invalid access token'));
    }
    if (error.name === 'TokenExpiredError') {
      return next(new UnauthorizedError('Access token has expired'));
    }
    next(error);
  }
};

/**
 * Authorize by role names
 * @param {...string} roles - Allowed role names
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return next(new UnauthorizedError('Authentication required'));
    }
    if (!roles.includes(req.user.roleName)) {
      return next(new ForbiddenError('You do not have permission to access this resource'));
    }
    next();
  };
};

/**
 * Check specific permission
 * @param {string} module - Module name
 * @param {string} action - Action (create, read, update, delete)
 * @param {string} resource - Resource name
 */
const checkPermission = (module, action, resource) => {
  return (req, res, next) => {
    if (!req.user) {
      return next(new UnauthorizedError('Authentication required'));
    }

    // Super Admin bypasses permission checks
    if (req.user.roleName === 'super_admin') {
      return next();
    }

    const hasPermission = req.user.permissions.some(
      (p) => p.module === module && p.action === action && p.resource === resource
    );

    if (!hasPermission) {
      return next(new ForbiddenError(`Permission denied: ${module}.${action}.${resource}`));
    }
    next();
  };
};

/**
 * Optional authentication - attaches user if token present
 */
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      const decoded = jwt.verify(token, config.jwt.secret);
      const user = await prisma.user.findUnique({
        where: { id: decoded.userId },
        include: { role: true },
      });
      if (user && user.isActive) {
        req.user = {
          id: user.id,
          companyId: user.companyId,
          branchId: user.branchId,
          roleId: user.roleId,
          roleName: user.role.name,
        };
      }
    }
  } catch {
    // Token invalid - continue without auth
  }
  next();
};

module.exports = { authenticate, authorize, checkPermission, optionalAuth };
