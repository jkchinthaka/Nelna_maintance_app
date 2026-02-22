// ============================================================================
// Nelna Maintenance System - Scheduled Tasks (Cron Jobs)
// ============================================================================
const cron = require('node-cron');
const logger = require('../config/logger');
const prisma = require('../config/database');
const notificationService = require('../services/notification.service');

/**
 * Initialize all scheduled tasks
 */
const initScheduledTasks = () => {
  logger.info('⏰ Initializing scheduled tasks...');

  // Every day at 8:00 AM - Check vehicle service reminders
  cron.schedule('0 8 * * *', async () => {
    logger.info('Running: Vehicle service reminder check');
    try {
      const vehicles = await prisma.vehicle.findMany({
        where: {
          deletedAt: null,
          status: { not: 'DISPOSED' },
        },
        include: {
          drivers: {
            where: { isActive: true },
            include: { driver: true },
          },
        },
      });

      const now = new Date();
      const thirtyDaysFromNow = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

      for (const vehicle of vehicles) {
        // Service due reminder
        if (vehicle.nextServiceDate && vehicle.nextServiceDate <= thirtyDaysFromNow) {
          for (const vd of vehicle.drivers) {
            await notificationService.createNotification(
              vd.driver.id,
              'Vehicle Service Reminder',
              `Vehicle ${vehicle.registrationNo} service is due on ${vehicle.nextServiceDate.toISOString().split('T')[0]}`,
              'VEHICLE_SERVICE_REMINDER',
              { vehicleId: vehicle.id }
            );
          }
        }

        // Insurance expiry reminder
        if (vehicle.insuranceExpiry && vehicle.insuranceExpiry <= thirtyDaysFromNow) {
          const managers = await prisma.user.findMany({
            where: {
              role: { name: { in: ['company_admin', 'maintenance_manager'] } },
              branchId: vehicle.branchId,
              isActive: true,
            },
          });
          for (const manager of managers) {
            await notificationService.createNotification(
              manager.id,
              'Insurance Expiry Alert',
              `Vehicle ${vehicle.registrationNo} insurance expires on ${vehicle.insuranceExpiry.toISOString().split('T')[0]}`,
              'INSURANCE_EXPIRY',
              { vehicleId: vehicle.id }
            );
          }
        }
      }
      logger.info('Vehicle service reminder check completed');
    } catch (error) {
      logger.error('Vehicle reminder cron failed:', error);
    }
  });

  // Every day at 7:00 AM - Check overdue maintenance schedules
  cron.schedule('0 7 * * *', async () => {
    logger.info('Running: Machine maintenance schedule check');
    try {
      const overdueSchedules = await prisma.machineMaintenanceSchedule.findMany({
        where: {
          isActive: true,
          nextDueDate: { lte: new Date() },
        },
        include: {
          machine: true,
        },
      });

      if (overdueSchedules.length > 0) {
        const managers = await prisma.user.findMany({
          where: {
            role: { name: { in: ['maintenance_manager', 'company_admin'] } },
            isActive: true,
          },
        });

        for (const manager of managers) {
          await notificationService.createNotification(
            manager.id,
            `${overdueSchedules.length} Overdue Maintenance Tasks`,
            `There are ${overdueSchedules.length} overdue machine maintenance schedules that need attention.`,
            'OVERDUE_MAINTENANCE',
            { count: overdueSchedules.length }
          );
        }
      }
      logger.info(`Machine maintenance check: ${overdueSchedules.length} overdue`);
    } catch (error) {
      logger.error('Machine maintenance cron failed:', error);
    }
  });

  // Every day at 9:00 AM - Check low stock alerts
  cron.schedule('0 9 * * *', async () => {
    logger.info('Running: Low stock alert check');
    try {
      const lowStockProducts = await prisma.product.findMany({
        where: {
          deletedAt: null,
          isActive: true,
          currentStock: { lte: prisma.product.fields.reorderLevel },
        },
      });

      // Use raw query for the comparison
      const rawLowStock = await prisma.$queryRaw`
        SELECT id, name, sku, current_stock, reorder_level, branch_id
        FROM products
        WHERE deleted_at IS NULL
        AND is_active = true
        AND current_stock <= reorder_level
      `;

      if (rawLowStock.length > 0) {
        const storeManagers = await prisma.user.findMany({
          where: {
            role: { name: { in: ['store_manager', 'company_admin'] } },
            isActive: true,
          },
        });

        for (const manager of storeManagers) {
          await notificationService.createNotification(
            manager.id,
            'Low Stock Alert',
            `${rawLowStock.length} products are below reorder level and need restocking.`,
            'LOW_STOCK_ALERT',
            { count: rawLowStock.length }
          );
        }
      }
      logger.info(`Low stock check: ${rawLowStock.length} items below reorder level`);
    } catch (error) {
      logger.error('Low stock cron failed:', error);
    }
  });

  // Every hour - Check SLA breaches
  cron.schedule('0 * * * *', async () => {
    try {
      const breachedRequests = await prisma.serviceRequest.findMany({
        where: {
          status: { in: ['PENDING', 'APPROVED', 'IN_PROGRESS'] },
          slaDeadline: { lt: new Date() },
        },
        include: { requester: true },
      });

      for (const request of breachedRequests) {
        const managers = await prisma.user.findMany({
          where: {
            role: { name: 'maintenance_manager' },
            branchId: request.branchId,
            isActive: true,
          },
        });

        for (const manager of managers) {
          await notificationService.createNotification(
            manager.id,
            `SLA Breach: ${request.ticketNo}`,
            `Service request ${request.ticketNo} has breached its SLA deadline.`,
            'SLA_BREACH',
            { serviceRequestId: request.id, ticketNo: request.ticketNo }
          );
        }
      }
    } catch (error) {
      logger.error('SLA check cron failed:', error);
    }
  });

  // Every month on 1st at 6:00 AM - AMC contract expiry check
  cron.schedule('0 6 1 * *', async () => {
    logger.info('Running: AMC contract expiry check');
    try {
      const thirtyDaysFromNow = new Date();
      thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);

      const expiringContracts = await prisma.aMCContract.findMany({
        where: {
          status: 'ACTIVE',
          endDate: { lte: thirtyDaysFromNow },
        },
        include: { machine: true },
      });

      if (expiringContracts.length > 0) {
        const admins = await prisma.user.findMany({
          where: {
            role: { name: { in: ['company_admin', 'maintenance_manager'] } },
            isActive: true,
          },
        });

        for (const admin of admins) {
          await notificationService.createNotification(
            admin.id,
            `${expiringContracts.length} AMC Contracts Expiring`,
            `There are ${expiringContracts.length} AMC contracts expiring within the next 30 days.`,
            'AMC_EXPIRY',
            { count: expiringContracts.length }
          );
        }
      }
      logger.info(`AMC check: ${expiringContracts.length} contracts expiring`);
    } catch (error) {
      logger.error('AMC expiry cron failed:', error);
    }
  });

  logger.info('✅ All scheduled tasks initialized');
};

module.exports = { initScheduledTasks };
