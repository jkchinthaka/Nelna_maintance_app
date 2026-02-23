// ============================================================================
// Nelna Maintenance System - Notification Service Unit Tests
// ============================================================================
const { NotFoundError, BadRequestError } = require('../../../src/utils/errors');

// ── Mock Prisma ─────────────────────────────────────────────────────────────
const mockPrisma = {
  user: {
    findUnique: jest.fn(),
    updateMany: jest.fn(),
  },
  notification: {
    create: jest.fn(),
    createMany: jest.fn(),
    findMany: jest.fn(),
    findFirst: jest.fn(),
    update: jest.fn(),
    updateMany: jest.fn(),
    delete: jest.fn(),
    deleteMany: jest.fn(),
    count: jest.fn(),
  },
};

jest.mock('../../../src/config/database', () => mockPrisma);
jest.mock('../../../src/config/firebase', () => ({
  getMessaging: jest.fn(() => null), // FCM disabled in tests
}));
jest.mock('../../../src/config/logger', () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}));

const NotificationService = require('../../../src/services/notification.service');

beforeEach(() => jest.clearAllMocks());

// ═════════════════════════════════════════════════════════════════════════════
// createNotification
// ═════════════════════════════════════════════════════════════════════════════
describe('NotificationService.createNotification', () => {
  it('should create a notification for a valid user', async () => {
    mockPrisma.user.findUnique.mockResolvedValue({ id: 1, fcmToken: null });
    mockPrisma.notification.create.mockResolvedValue({ id: 10 });

    const result = await NotificationService.createNotification(
      1,
      'Test Title',
      'Test Body',
      'SYSTEM'
    );

    expect(result.id).toBe(10);
    expect(mockPrisma.notification.create).toHaveBeenCalledTimes(1);
  });

  it('should throw BadRequestError when required fields are missing', async () => {
    await expect(
      NotificationService.createNotification(null, '', '', '')
    ).rejects.toThrow(BadRequestError);
  });

  it('should throw NotFoundError when user does not exist', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(null);

    await expect(
      NotificationService.createNotification(999, 'T', 'B', 'SYSTEM')
    ).rejects.toThrow(NotFoundError);
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// createBulkNotifications
// ═════════════════════════════════════════════════════════════════════════════
describe('NotificationService.createBulkNotifications', () => {
  it('should create notifications for multiple users', async () => {
    mockPrisma.notification.createMany.mockResolvedValue({ count: 3 });

    const result = await NotificationService.createBulkNotifications(
      [1, 2, 3],
      'Title',
      'Body',
      'SYSTEM'
    );

    expect(result.count).toBe(3);
  });

  it('should throw BadRequestError for empty array', async () => {
    await expect(
      NotificationService.createBulkNotifications([], 'T', 'B', 'SYSTEM')
    ).rejects.toThrow(BadRequestError);
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// getUserNotifications
// ═════════════════════════════════════════════════════════════════════════════
describe('NotificationService.getUserNotifications', () => {
  it('should return paginated notifications', async () => {
    mockPrisma.notification.findMany.mockResolvedValue([{ id: 1 }]);
    mockPrisma.notification.count.mockResolvedValue(1);

    const result = await NotificationService.getUserNotifications(1, {});

    expect(result.notifications).toHaveLength(1);
    expect(result.pagination.total).toBe(1);
  });

  it('should filter by isRead', async () => {
    mockPrisma.notification.findMany.mockResolvedValue([]);
    mockPrisma.notification.count.mockResolvedValue(0);

    await NotificationService.getUserNotifications(1, { isRead: 'true' });

    const call = mockPrisma.notification.findMany.mock.calls[0][0];
    expect(call.where.isRead).toBe(true);
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// markAsRead
// ═════════════════════════════════════════════════════════════════════════════
describe('NotificationService.markAsRead', () => {
  it('should mark a notification as read', async () => {
    mockPrisma.notification.findFirst.mockResolvedValue({ id: 5, userId: 1, isRead: false });
    mockPrisma.notification.update.mockResolvedValue({ id: 5, isRead: true });

    const result = await NotificationService.markAsRead(5, 1);

    expect(result.isRead).toBe(true);
  });

  it('should return immediately if already read', async () => {
    mockPrisma.notification.findFirst.mockResolvedValue({ id: 5, userId: 1, isRead: true });

    const result = await NotificationService.markAsRead(5, 1);

    expect(result.isRead).toBe(true);
    expect(mockPrisma.notification.update).not.toHaveBeenCalled();
  });

  it('should throw NotFoundError when notification not found', async () => {
    mockPrisma.notification.findFirst.mockResolvedValue(null);

    await expect(NotificationService.markAsRead(999, 1)).rejects.toThrow(NotFoundError);
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// markAllAsRead
// ═════════════════════════════════════════════════════════════════════════════
describe('NotificationService.markAllAsRead', () => {
  it('should update all unread notifications', async () => {
    mockPrisma.notification.updateMany.mockResolvedValue({ count: 5 });

    const result = await NotificationService.markAllAsRead(1);

    expect(result.count).toBe(5);
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// getUnreadCount
// ═════════════════════════════════════════════════════════════════════════════
describe('NotificationService.getUnreadCount', () => {
  it('should return unread count', async () => {
    mockPrisma.notification.count.mockResolvedValue(3);

    const result = await NotificationService.getUnreadCount(1);

    expect(result.unreadCount).toBe(3);
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// deleteNotification
// ═════════════════════════════════════════════════════════════════════════════
describe('NotificationService.deleteNotification', () => {
  it('should delete existing notification', async () => {
    mockPrisma.notification.findFirst.mockResolvedValue({ id: 3, userId: 1 });
    mockPrisma.notification.delete.mockResolvedValue({});

    const result = await NotificationService.deleteNotification(3, 1);

    expect(result.deleted).toBe(true);
  });

  it('should throw NotFoundError when not found', async () => {
    mockPrisma.notification.findFirst.mockResolvedValue(null);

    await expect(NotificationService.deleteNotification(999, 1)).rejects.toThrow(NotFoundError);
  });
});
