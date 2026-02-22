// ============================================================================
// Nelna Maintenance System - Notification Service (Business Logic)
// ============================================================================
const prisma = require('../config/database');
const { NotFoundError, BadRequestError } = require('../utils/errors');
const { parsePagination } = require('../utils/helpers');

class NotificationService {
  /**
   * Create a new notification for a user
   * @param {number} userId - Target user ID
   * @param {string} title - Notification title
   * @param {string} body - Notification body text
   * @param {string} type - Notification type (e.g., 'SERVICE_REQUEST', 'INVENTORY_ALERT', 'SYSTEM')
   * @param {object|null} data - Optional JSON metadata (e.g., entity IDs, links)
   * @returns {object} Created notification
   */
  async createNotification(userId, title, body, type, data = null) {
    if (!userId || !title || !body || !type) {
      throw new BadRequestError('userId, title, body, and type are required');
    }

    // Verify user exists
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, fcmToken: true },
    });
    if (!user) throw new NotFoundError('User not found');

    const notification = await prisma.notification.create({
      data: {
        userId,
        title,
        body,
        type,
        data: data || undefined,
      },
    });

    // TODO: Integrate push notification (FCM) here if user.fcmToken is available
    // if (user.fcmToken) {
    //   await this._sendPushNotification(user.fcmToken, title, body, data);
    // }

    return notification;
  }

  /**
   * Create notifications for multiple users at once
   * @param {number[]} userIds - Array of user IDs
   * @param {string} title - Notification title
   * @param {string} body - Notification body text
   * @param {string} type - Notification type
   * @param {object|null} data - Optional JSON metadata
   * @returns {object} Count of created notifications
   */
  async createBulkNotifications(userIds, title, body, type, data = null) {
    if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
      throw new BadRequestError('userIds array is required and must not be empty');
    }

    const notifications = userIds.map((userId) => ({
      userId,
      title,
      body,
      type,
      data: data || undefined,
    }));

    const result = await prisma.notification.createMany({
      data: notifications,
      skipDuplicates: true,
    });

    return { count: result.count };
  }

  /**
   * Get paginated notifications for a user
   * @param {number} userId - User ID
   * @param {object} query - Query params (page, limit, isRead, type)
   * @returns {object} Notifications and pagination metadata
   */
  async getUserNotifications(userId, query = {}) {
    const { page, limit, skip } = parsePagination(query);

    const where = { userId };

    // Filter by read status
    if (query.isRead !== undefined) {
      where.isRead = query.isRead === 'true' || query.isRead === true;
    }

    // Filter by type
    if (query.type) {
      where.type = query.type;
    }

    const [notifications, total] = await Promise.all([
      prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.notification.count({ where }),
    ]);

    return { notifications, pagination: { page, limit, total } };
  }

  /**
   * Mark a single notification as read
   * @param {number} notificationId - Notification ID
   * @param {number} userId - User ID (for ownership validation)
   * @returns {object} Updated notification
   */
  async markAsRead(notificationId, userId) {
    const notification = await prisma.notification.findFirst({
      where: { id: notificationId, userId },
    });

    if (!notification) {
      throw new NotFoundError('Notification not found');
    }

    if (notification.isRead) {
      return notification; // Already read
    }

    return prisma.notification.update({
      where: { id: notificationId },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });
  }

  /**
   * Mark all notifications as read for a user
   * @param {number} userId - User ID
   * @returns {object} Count of updated notifications
   */
  async markAllAsRead(userId) {
    const result = await prisma.notification.updateMany({
      where: {
        userId,
        isRead: false,
      },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });

    return { count: result.count };
  }

  /**
   * Get unread notification count for a user
   * @param {number} userId - User ID
   * @returns {object} Unread count
   */
  async getUnreadCount(userId) {
    const count = await prisma.notification.count({
      where: {
        userId,
        isRead: false,
      },
    });

    return { unreadCount: count };
  }

  /**
   * Delete a notification
   * @param {number} notificationId - Notification ID
   * @param {number} userId - User ID (for ownership validation)
   */
  async deleteNotification(notificationId, userId) {
    const notification = await prisma.notification.findFirst({
      where: { id: notificationId, userId },
    });

    if (!notification) {
      throw new NotFoundError('Notification not found');
    }

    await prisma.notification.delete({
      where: { id: notificationId },
    });

    return { deleted: true };
  }

  /**
   * Delete all read notifications for a user (cleanup)
   * @param {number} userId - User ID
   * @returns {object} Count of deleted notifications
   */
  async deleteReadNotifications(userId) {
    const result = await prisma.notification.deleteMany({
      where: {
        userId,
        isRead: true,
      },
    });

    return { count: result.count };
  }

  // ==========================================================================
  // CONVENIENCE METHODS FOR OTHER SERVICES
  // ==========================================================================

  /**
   * Notify about a new service request
   */
  async notifyServiceRequest(serviceRequest, targetUserIds) {
    return this.createBulkNotifications(
      targetUserIds,
      `New Service Request: ${serviceRequest.ticketNo}`,
      `${serviceRequest.subject} - Priority: ${serviceRequest.priority}`,
      'SERVICE_REQUEST',
      {
        entityType: 'ServiceRequest',
        entityId: serviceRequest.id,
        ticketNo: serviceRequest.ticketNo,
        status: serviceRequest.status,
      }
    );
  }

  /**
   * Notify about low stock
   */
  async notifyLowStock(product, targetUserIds) {
    return this.createBulkNotifications(
      targetUserIds,
      `Low Stock Alert: ${product.name}`,
      `${product.name} (${product.sku}) has reached reorder level. Current stock: ${product.currentStock} ${product.unit}`,
      'INVENTORY_ALERT',
      {
        entityType: 'Product',
        entityId: product.id,
        sku: product.sku,
        currentStock: product.currentStock,
        reorderLevel: product.reorderLevel,
      }
    );
  }

  /**
   * Notify about machine breakdown
   */
  async notifyMachineBreakdown(machine, breakdown, targetUserIds) {
    return this.createBulkNotifications(
      targetUserIds,
      `Machine Breakdown: ${machine.machineCode}`,
      `${machine.name} reported a ${breakdown.severity} severity breakdown: ${breakdown.description}`,
      'MACHINE_BREAKDOWN',
      {
        entityType: 'BreakdownLog',
        entityId: breakdown.id,
        machineId: machine.id,
        machineCode: machine.machineCode,
        severity: breakdown.severity,
      }
    );
  }

  /**
   * Notify about asset transfer
   */
  async notifyAssetTransfer(asset, transfer, targetUserIds) {
    return this.createBulkNotifications(
      targetUserIds,
      `Asset Transfer: ${asset.assetCode}`,
      `${asset.name} transferred from ${transfer.fromLocation} to ${transfer.toLocation}`,
      'ASSET_TRANSFER',
      {
        entityType: 'AssetTransfer',
        entityId: transfer.id,
        assetId: asset.id,
        assetCode: asset.assetCode,
      }
    );
  }

  /**
   * Notify about upcoming warranty expiry
   */
  async notifyWarrantyExpiry(asset, targetUserIds) {
    const expiryDate = new Date(asset.warrantyExpiry).toLocaleDateString();
    return this.createBulkNotifications(
      targetUserIds,
      `Warranty Expiring: ${asset.assetCode || asset.machineCode || asset.registrationNo}`,
      `Warranty for ${asset.name} expires on ${expiryDate}. Please review.`,
      'WARRANTY_EXPIRY',
      {
        entityType: asset.assetCode ? 'Asset' : asset.machineCode ? 'Machine' : 'Vehicle',
        entityId: asset.id,
        warrantyExpiry: asset.warrantyExpiry,
      }
    );
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  /**
   * Send push notification via FCM (placeholder)
   * @private
   */
  // async _sendPushNotification(fcmToken, title, body, data) {
  //   // Integrate with Firebase Admin SDK
  //   // const message = { notification: { title, body }, data, token: fcmToken };
  //   // await admin.messaging().send(message);
  // }
}

module.exports = new NotificationService();
