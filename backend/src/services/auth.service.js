// ============================================================================
// Nelna Maintenance System - Auth Service (Business Logic Layer)
// ============================================================================
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const config = require('../config');
const prisma = require('../config/database');
const {
  UnauthorizedError,
  BadRequestError,
  NotFoundError,
  ConflictError,
  ForbiddenError,
} = require('../utils/errors');
const { SELF_REGISTER_ROLES, ADMIN_ROLES } = require('../utils/roleConstants');

class AuthService {
  /**
   * Login user with email and password
   */
  async login(email, password) {
    const user = await prisma.user.findUnique({
      where: { email },
      include: {
        role: true,
        company: true,
        branch: true,
      },
    });

    if (!user || user.deletedAt) {
      throw new UnauthorizedError('Invalid email or password');
    }

    if (!user.isActive) {
      throw new UnauthorizedError('Account is deactivated. Contact your administrator.');
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedError('Invalid email or password');
    }

    // Generate tokens
    const accessToken = this._generateAccessToken(user);
    const refreshToken = this._generateRefreshToken(user);

    // Save refresh token and update last login
    await prisma.user.update({
      where: { id: user.id },
      data: {
        refreshToken,
        lastLoginAt: new Date(),
      },
    });

    return {
      user: this._sanitizeUser(user),
      accessToken,
      refreshToken,
    };
  }

  /**
   * Register a new user with role-based access control.
   *
   * Rules:
   *  - Unauthenticated (self-register): only Technician (4) or Driver (6) allowed
   *  - Super Admin / Company Admin (caller): can create any role
   *  - Other authenticated users: forbidden from creating accounts
   *
   * @param {object} userData  - registration payload
   * @param {object|null} caller - req.user attached by optionalAuth (null = public)
   */
  async register(userData, caller = null) {
    const requestedRoleId = parseInt(userData.roleId, 10);

    // ── Enforce role-based registration rules ─────────────────────────────
    if (!caller) {
      // Public self-registration: only technician / driver
      if (!SELF_REGISTER_ROLES.includes(requestedRoleId)) {
        throw new ForbiddenError(
          'Self-registration is only allowed for Technician and Driver roles'
        );
      }
    } else {
      // Authenticated caller
      if (!ADMIN_ROLES.includes(caller.roleId)) {
        throw new ForbiddenError(
          'Only Super Admin or Company Admin can create user accounts'
        );
      }
      // Prevent company_admin from creating super_admin
      if (caller.roleId !== 1 && requestedRoleId === 1) {
        throw new ForbiddenError(
          'Only Super Admin can create another Super Admin account'
        );
      }
    }

    // ── Check duplicate email ─────────────────────────────────────────────
    const existingUser = await prisma.user.findUnique({
      where: { email: userData.email },
    });
    if (existingUser) {
      throw new ConflictError('Email address is already registered');
    }

    // ── Verify role exists ────────────────────────────────────────────────
    const role = await prisma.role.findUnique({
      where: { id: requestedRoleId },
    });
    if (!role) {
      throw new BadRequestError('Invalid role specified');
    }

    // ── Hash password ─────────────────────────────────────────────────────
    const passwordHash = await bcrypt.hash(userData.password, 12);

    // ── Create user ───────────────────────────────────────────────────────
    const user = await prisma.user.create({
      data: {
        companyId: userData.companyId,
        branchId: userData.branchId || null,
        roleId: requestedRoleId,
        employeeId: userData.employeeId || null,
        firstName: userData.firstName,
        lastName: userData.lastName,
        email: userData.email,
        passwordHash,
        phone: userData.phone || null,
      },
      include: {
        role: true,
        company: true,
        branch: true,
      },
    });

    const accessToken = this._generateAccessToken(user);
    const refreshToken = this._generateRefreshToken(user);

    await prisma.user.update({
      where: { id: user.id },
      data: { refreshToken },
    });

    // ── Audit log ─────────────────────────────────────────────────────────
    try {
      await prisma.auditLog.create({
        data: {
          userId: caller ? caller.id : user.id,
          action: 'CREATE',
          module: 'users',
          entityType: 'User',
          entityId: user.id,
          newValues: {
            email: user.email,
            roleId: user.roleId,
            roleName: role.name,
            registeredBy: caller ? caller.email : 'self-registration',
          },
          ipAddress: userData._ip || null,
          userAgent: userData._userAgent || null,
        },
      });
    } catch (_) {
      // audit failure should not block registration
    }

    return {
      user: this._sanitizeUser(user),
      accessToken,
      refreshToken,
    };
  }

  /**
   * Refresh access token
   */
  async refreshToken(token) {
    try {
      const decoded = jwt.verify(token, config.jwt.refreshSecret);

      const user = await prisma.user.findUnique({
        where: { id: decoded.userId },
        include: { role: true, company: true, branch: true },
      });

      if (!user || !user.isActive || user.deletedAt) {
        throw new UnauthorizedError('Invalid refresh token');
      }

      if (user.refreshToken !== token) {
        throw new UnauthorizedError('Refresh token has been revoked');
      }

      const accessToken = this._generateAccessToken(user);
      const newRefreshToken = this._generateRefreshToken(user);

      await prisma.user.update({
        where: { id: user.id },
        data: { refreshToken: newRefreshToken },
      });

      return {
        accessToken,
        refreshToken: newRefreshToken,
      };
    } catch (error) {
      if (error instanceof UnauthorizedError) throw error;
      throw new UnauthorizedError('Invalid or expired refresh token');
    }
  }

  /**
   * Logout user
   */
  async logout(userId) {
    await prisma.user.update({
      where: { id: userId },
      data: { refreshToken: null },
    });
  }

  /**
   * Change password
   */
  async changePassword(userId, currentPassword, newPassword) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundError('User not found');

    const isValid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isValid) {
      throw new BadRequestError('Current password is incorrect');
    }

    const passwordHash = await bcrypt.hash(newPassword, 12);
    await prisma.user.update({
      where: { id: userId },
      data: { passwordHash, refreshToken: null },
    });
  }

  /**
   * Get current user profile
   */
  async getProfile(userId) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        role: {
          include: {
            permissions: {
              include: { permission: true },
            },
          },
        },
        company: true,
        branch: true,
      },
    });

    if (!user || user.deletedAt) throw new NotFoundError('User not found');
    return this._sanitizeUser(user);
  }

  /**
   * Update FCM token for push notifications
   */
  async updateFCMToken(userId, fcmToken) {
    await prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });
  }

  // === Private methods ===

  _generateAccessToken(user) {
    return jwt.sign(
      {
        userId: user.id,
        companyId: user.companyId,
        branchId: user.branchId,
        roleId: user.roleId,
        roleName: user.role.name,
      },
      config.jwt.secret,
      { expiresIn: config.jwt.expiry }
    );
  }

  _generateRefreshToken(user) {
    return jwt.sign(
      { userId: user.id },
      config.jwt.refreshSecret,
      { expiresIn: config.jwt.refreshExpiry }
    );
  }

  _sanitizeUser(user) {
    const { passwordHash, refreshToken, passwordResetToken, passwordResetExpiry, ...sanitized } = user;
    return sanitized;
  }
}

module.exports = new AuthService();
