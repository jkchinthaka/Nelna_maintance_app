// ============================================================================
// Nelna Maintenance System - Auth Service Unit Tests
// ============================================================================
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { UnauthorizedError, ConflictError, BadRequestError, NotFoundError } = require('../../../src/utils/errors');

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

beforeEach(() => {
  jest.clearAllMocks();
  jwt.sign.mockReturnValue('mock-token');
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
// register
// ═════════════════════════════════════════════════════════════════════════════
describe('AuthService.register', () => {
  const regData = {
    firstName: 'Jane',
    lastName: 'Doe',
    email: 'jane@test.com',
    password: 'Str0ng!Pass',
    companyId: 1,
    roleId: 2,
  };

  it('should create a new user and return tokens', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(null);
    mockPrisma.role.findUnique.mockResolvedValue({ id: 2, name: 'company_admin' });
    bcrypt.hash.mockResolvedValue('hashed-pw');
    mockPrisma.user.create.mockResolvedValue({ ...sampleUser, id: 10, email: 'jane@test.com' });
    mockPrisma.user.update.mockResolvedValue({});

    const result = await AuthService.register(regData);

    expect(result.user).toBeDefined();
    expect(result.accessToken).toBe('mock-token');
    expect(mockPrisma.user.create).toHaveBeenCalledTimes(1);
  });

  it('should throw ConflictError for duplicate email', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(sampleUser);

    await expect(AuthService.register(regData)).rejects.toThrow(ConflictError);
  });

  it('should throw BadRequestError for invalid role', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(null);
    mockPrisma.role.findUnique.mockResolvedValue(null);

    await expect(AuthService.register(regData)).rejects.toThrow(BadRequestError);
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
