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
} = require('../utils/errors');

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
   * Register a new user
   */
  async register(userData) {
    // Check if email already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: userData.email },
    });
    if (existingUser) {
      throw new ConflictError('Email address is already registered');
    }

    // Verify role exists
    const role = await prisma.role.findUnique({
      where: { id: userData.roleId },
    });
    if (!role) {
      throw new BadRequestError('Invalid role specified');
    }

    // Hash password
    const passwordHash = await bcrypt.hash(userData.password, 12);

    // Create user
    const user = await prisma.user.create({
      data: {
        companyId: userData.companyId,
        branchId: userData.branchId || null,
        roleId: userData.roleId,
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
