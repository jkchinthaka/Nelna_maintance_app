// ============================================================================
// Nelna Maintenance System - Auth Service Unit Tests
// ============================================================================
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { UnauthorizedError, ConflictError, BadRequestError, NotFoundError, ForbiddenError } = require('../../../src/utils/errors');

// ── Mock Prisma ─────────────────────────────────────────────────────────────
const mockPrisma = {
  user: {
    findUnique: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
  },
  role: {
    findUnique: jest.fn(),
  },
  auditLog: {
    create: jest.fn(),
  },
};

jest.mock('../../../src/config/database', () => mockPrisma);
jest.mock('bcryptjs');
jest.mock('jsonwebtoken');

// Import AFTER mocking
const AuthService = require('../../../src/services/auth.service');

// ── Helpers ─────────────────────────────────────────────────────────────────

const sampleUser = {
  id: 1,
  companyId: 1,
  branchId: 1,
  roleId: 2,
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@test.com',
  passwordHash: '$2a$12$hash',
  isActive: true,
  deletedAt: null,
  refreshToken: 'old-refresh',
  role: { id: 2, name: 'company_admin', displayName: 'Company Admin' },
  company: { id: 1, name: 'Test Co', code: 'TC' },
  branch: { id: 1, name: 'HQ', code: 'HQ' },
};

/** Convenience caller objects used to simulate req.user */
const superAdminCaller = { id: 1, roleId: 1, roleName: 'super_admin', email: 'sa@test.com' };
const companyAdminCaller = { id: 2, roleId: 2, roleName: 'company_admin', email: 'ca@test.com' };
const technicianCaller = { id: 3, roleId: 4, roleName: 'technician', email: 'tech@test.com' };

beforeEach(() => {
  jest.clearAllMocks();
  jwt.sign.mockReturnValue('mock-token');
  mockPrisma.auditLog.create.mockResolvedValue({});
});

// ═════════════════════════════════════════════════════════════════════════════
// login
// ═════════════════════════════════════════════════════════════════════════════
describe('AuthService.login', () => {
  it('should return user + tokens on successful login', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(sampleUser);
    mockPrisma.user.update.mockResolvedValue({});
    bcrypt.compare.mockResolvedValue(true);

    const result = await AuthService.login('john@test.com', 'password123');

    expect(result.user).toBeDefined();
    expect(result.accessToken).toBe('mock-token');
    expect(result.refreshToken).toBe('mock-token');
    // password should be stripped
    expect(result.user.passwordHash).toBeUndefined();
  });

  it('should throw UnauthorizedError for non-existent user', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(null);

    await expect(AuthService.login('nope@test.com', 'pw')).rejects.toThrow(UnauthorizedError);
  });

  it('should throw UnauthorizedError for deleted user', async () => {
    mockPrisma.user.findUnique.mockResolvedValue({ ...sampleUser, deletedAt: new Date() });

    await expect(AuthService.login('john@test.com', 'pw')).rejects.toThrow(UnauthorizedError);
  });

  it('should throw UnauthorizedError for deactivated user', async () => {
    mockPrisma.user.findUnique.mockResolvedValue({ ...sampleUser, isActive: false });

    await expect(AuthService.login('john@test.com', 'pw')).rejects.toThrow(UnauthorizedError);
  });

  it('should throw UnauthorizedError for wrong password', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(sampleUser);
    bcrypt.compare.mockResolvedValue(false);

    await expect(AuthService.login('john@test.com', 'wrong')).rejects.toThrow(UnauthorizedError);
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// register — role-based access control
// ═════════════════════════════════════════════════════════════════════════════
describe('AuthService.register', () => {
  const baseRegData = {
    firstName: 'Jane',
    lastName: 'Doe',
    email: 'jane@test.com',
    password: 'Str0ng!Pass',
    companyId: 1,
  };

  const mockCreatedUser = (roleId) => ({
    ...sampleUser,
    id: 10,
    email: 'jane@test.com',
    roleId,
    role: { id: roleId, name: `role_${roleId}` },
  });

  // helper to set up "happy path" mocks for user creation
  const setupCreateMocks = (roleId) => {
    mockPrisma.user.findUnique.mockResolvedValue(null);
    mockPrisma.role.findUnique.mockResolvedValue({ id: roleId, name: `role_${roleId}` });
    bcrypt.hash.mockResolvedValue('hashed-pw');
    mockPrisma.user.create.mockResolvedValue(mockCreatedUser(roleId));
    mockPrisma.user.update.mockResolvedValue({});
  };

  // ── Self-registration (no caller / public) ──────────────────────────────

  it('should allow self-registration as Technician (roleId=4)', async () => {
    setupCreateMocks(4);
    const result = await AuthService.register({ ...baseRegData, roleId: 4 }, null);
    expect(result.user).toBeDefined();
    expect(result.accessToken).toBe('mock-token');
    expect(mockPrisma.user.create).toHaveBeenCalledTimes(1);
  });

  it('should allow self-registration as Driver (roleId=6)', async () => {
    setupCreateMocks(6);
    const result = await AuthService.register({ ...baseRegData, roleId: 6 }, null);
    expect(result.user).toBeDefined();
    expect(result.accessToken).toBe('mock-token');
  });

  it('should REJECT self-registration as Super Admin (roleId=1)', async () => {
    await expect(
      AuthService.register({ ...baseRegData, roleId: 1 }, null)
    ).rejects.toThrow(ForbiddenError);
    expect(mockPrisma.user.create).not.toHaveBeenCalled();
  });

  it('should REJECT self-registration as Company Admin (roleId=2)', async () => {
    await expect(
      AuthService.register({ ...baseRegData, roleId: 2 }, null)
    ).rejects.toThrow(ForbiddenError);
  });

  it('should REJECT self-registration as Maintenance Manager (roleId=3)', async () => {
    await expect(
      AuthService.register({ ...baseRegData, roleId: 3 }, null)
    ).rejects.toThrow(ForbiddenError);
  });

  it('should REJECT self-registration as Store Manager (roleId=5)', async () => {
    await expect(
      AuthService.register({ ...baseRegData, roleId: 5 }, null)
    ).rejects.toThrow(ForbiddenError);
  });

  it('should REJECT self-registration as Finance Officer (roleId=7)', async () => {
    await expect(
      AuthService.register({ ...baseRegData, roleId: 7 }, null)
    ).rejects.toThrow(ForbiddenError);
  });

  // ── Admin-created accounts ──────────────────────────────────────────────

  it('should allow Super Admin to create any role', async () => {
    for (const roleId of [1, 2, 3, 4, 5, 6, 7]) {
      jest.clearAllMocks();
      jwt.sign.mockReturnValue('mock-token');
      mockPrisma.auditLog.create.mockResolvedValue({});
      setupCreateMocks(roleId);
      const result = await AuthService.register(
        { ...baseRegData, roleId },
        superAdminCaller
      );
      expect(result.user).toBeDefined();
    }
  });

  it('should allow Company Admin to create roles 2-7', async () => {
    for (const roleId of [2, 3, 4, 5, 6, 7]) {
      jest.clearAllMocks();
      jwt.sign.mockReturnValue('mock-token');
      mockPrisma.auditLog.create.mockResolvedValue({});
      setupCreateMocks(roleId);
      const result = await AuthService.register(
        { ...baseRegData, roleId },
        companyAdminCaller
      );
      expect(result.user).toBeDefined();
    }
  });

  it('should REJECT Company Admin creating a Super Admin', async () => {
    await expect(
      AuthService.register({ ...baseRegData, roleId: 1 }, companyAdminCaller)
    ).rejects.toThrow(ForbiddenError);
  });

  // ── Non-admin authenticated users ───────────────────────────────────────

  it('should REJECT Technician from creating any account', async () => {
    await expect(
      AuthService.register({ ...baseRegData, roleId: 4 }, technicianCaller)
    ).rejects.toThrow(ForbiddenError);
  });

  // ── Duplicate email / invalid role ──────────────────────────────────────

  it('should throw ConflictError for duplicate email', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(sampleUser);
    await expect(
      AuthService.register({ ...baseRegData, roleId: 4 }, null)
    ).rejects.toThrow(ConflictError);
  });

  it('should throw BadRequestError for non-existent role', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(null);
    mockPrisma.role.findUnique.mockResolvedValue(null);
    await expect(
      AuthService.register({ ...baseRegData, roleId: 4 }, null)
    ).rejects.toThrow(BadRequestError);
  });

  // ── Audit logging ──────────────────────────────────────────────────────

  it('should write an audit log on successful registration', async () => {
    setupCreateMocks(4);
    await AuthService.register({ ...baseRegData, roleId: 4 }, null);
    expect(mockPrisma.auditLog.create).toHaveBeenCalledTimes(1);
    const auditArg = mockPrisma.auditLog.create.mock.calls[0][0].data;
    expect(auditArg.action).toBe('CREATE');
    expect(auditArg.module).toBe('users');
    expect(auditArg.entityType).toBe('User');
  });

  it('should record admin email when admin creates user', async () => {
    setupCreateMocks(3);
    await AuthService.register({ ...baseRegData, roleId: 3 }, superAdminCaller);
    const auditArg = mockPrisma.auditLog.create.mock.calls[0][0].data;
    expect(auditArg.newValues.registeredBy).toBe('sa@test.com');
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// logout
// ═════════════════════════════════════════════════════════════════════════════
describe('AuthService.logout', () => {
  it('should clear the refresh token', async () => {
    mockPrisma.user.update.mockResolvedValue({});

    await AuthService.logout(1);

    expect(mockPrisma.user.update).toHaveBeenCalledWith({
      where: { id: 1 },
      data: { refreshToken: null },
    });
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// changePassword
// ═════════════════════════════════════════════════════════════════════════════
describe('AuthService.changePassword', () => {
  it('should hash and update the password', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(sampleUser);
    bcrypt.compare.mockResolvedValue(true);
    bcrypt.hash.mockResolvedValue('new-hash');
    mockPrisma.user.update.mockResolvedValue({});

    await AuthService.changePassword(1, 'oldPw', 'newPw!123');

    expect(mockPrisma.user.update).toHaveBeenCalledWith({
      where: { id: 1 },
      data: { passwordHash: 'new-hash', refreshToken: null },
    });
  });

  it('should throw NotFoundError when user does not exist', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(null);

    await expect(AuthService.changePassword(999, 'pw', 'new')).rejects.toThrow(NotFoundError);
  });

  it('should throw BadRequestError when current password is wrong', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(sampleUser);
    bcrypt.compare.mockResolvedValue(false);

    await expect(AuthService.changePassword(1, 'wrong', 'new')).rejects.toThrow(BadRequestError);
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// updateFCMToken
// ═════════════════════════════════════════════════════════════════════════════
describe('AuthService.updateFCMToken', () => {
  it('should update the user FCM token', async () => {
    mockPrisma.user.update.mockResolvedValue({});

    await AuthService.updateFCMToken(1, 'fcm-token-123');

    expect(mockPrisma.user.update).toHaveBeenCalledWith({
      where: { id: 1 },
      data: { fcmToken: 'fcm-token-123' },
    });
  });
});
