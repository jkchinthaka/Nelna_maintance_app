// ============================================================================
// Nelna Maintenance System - Report & Analytics Service (Business Logic)
// ============================================================================
const prisma = require('../config/database');
const { BadRequestError } = require('../utils/errors');

class ReportService {
  // ==========================================================================
  // DASHBOARD KPIs
  // ==========================================================================

  /**
   * Get dashboard KPI counts for a branch (or all branches for admins)
   */
  async getDashboardKPIs(branchId) {
    const branchFilter = branchId ? { branchId: parseInt(branchId, 10) } : {};

    const [
      activeVehicles,
      operationalMachines,
      openServiceRequests,
      lowStockItems,
      pendingPOs,
      expensesThisMonth,
      totalAssets,
      assetsUnderRepair,
    ] = await Promise.all([
      // Active vehicles
      prisma.vehicle.count({
        where: { ...branchFilter, status: 'ACTIVE', deletedAt: null },
      }),
      // Operational machines
      prisma.machine.count({
        where: { ...branchFilter, status: 'OPERATIONAL', deletedAt: null },
      }),
      // Open service requests (PENDING, APPROVED, IN_PROGRESS)
      prisma.serviceRequest.count({
        where: {
          ...branchFilter,
          status: { in: ['PENDING', 'APPROVED', 'IN_PROGRESS'] },
          deletedAt: null,
        },
      }),
      // Low stock items (current stock <= reorder level)
      // Prisma doesn't support comparing two columns, so use a raw query
      prisma.$queryRawUnsafe(
        `SELECT COUNT(*) as count FROM products WHERE ${branchId ? `branch_id = ${parseInt(branchId, 10)} AND` : ''} is_active = true AND deleted_at IS NULL AND current_stock <= reorder_level`
      ).then((r) => Number(r[0]?.count || 0)),
      // Pending purchase orders
      prisma.purchaseOrder.count({
        where: {
          ...branchFilter,
          status: { in: ['DRAFT', 'SUBMITTED', 'APPROVED'] },
        },
      }),
      // Expenses this month
      (() => {
        const now = new Date();
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
        return prisma.expense.aggregate({
          where: {
            ...branchFilter,
            date: { gte: startOfMonth, lte: endOfMonth },
            status: { in: ['APPROVED', 'PAID'] },
          },
          _sum: { amount: true },
        });
      })(),
      // Total assets
      prisma.asset.count({
        where: { ...branchFilter, deletedAt: null },
      }),
      // Assets under repair
      prisma.asset.count({
        where: { ...branchFilter, status: 'UNDER_REPAIR', deletedAt: null },
      }),
    ]);

    return {
      activeVehicles,
      operationalMachines,
      openServiceRequests,
      lowStockItems: typeof lowStockItems === 'number' ? lowStockItems : 0,
      pendingPOs,
      expensesThisMonth: expensesThisMonth._sum.amount
        ? parseFloat(expensesThisMonth._sum.amount)
        : 0,
      totalAssets,
      assetsUnderRepair,
    };
  }

  // ==========================================================================
  // VEHICLE MAINTENANCE COST REPORT
  // ==========================================================================

  /**
   * Per-vehicle cost breakdown within a date range
   */
  async getVehicleMaintenanceCostReport(branchId, startDate, endDate) {
    this._validateDateRange(startDate, endDate);

    const start = new Date(startDate);
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);

    const branchFilter = branchId ? { branchId: parseInt(branchId, 10) } : {};

    // Get vehicles with service history in range
    const vehicles = await prisma.vehicle.findMany({
      where: { ...branchFilter, deletedAt: null },
      select: {
        id: true,
        registrationNo: true,
        make: true,
        model: true,
        vehicleType: true,
        serviceHistory: {
          where: {
            serviceDate: { gte: start, lte: end },
          },
          select: {
            id: true,
            serviceDate: true,
            serviceType: true,
            cost: true,
            description: true,
          },
        },
        fuelLogs: {
          where: {
            date: { gte: start, lte: end },
          },
          select: {
            totalCost: true,
          },
        },
      },
    });

    const report = vehicles.map((v) => {
      const maintenanceCost = v.serviceHistory.reduce(
        (sum, sh) => sum + parseFloat(sh.cost || 0),
        0
      );
      const fuelCost = v.fuelLogs.reduce(
        (sum, fl) => sum + parseFloat(fl.totalCost || 0),
        0
      );

      return {
        vehicleId: v.id,
        registrationNo: v.registrationNo,
        make: v.make,
        model: v.model,
        vehicleType: v.vehicleType,
        serviceCount: v.serviceHistory.length,
        maintenanceCost: Math.round(maintenanceCost * 100) / 100,
        fuelCost: Math.round(fuelCost * 100) / 100,
        totalCost: Math.round((maintenanceCost + fuelCost) * 100) / 100,
        services: v.serviceHistory,
      };
    });

    // Sort by total cost descending
    report.sort((a, b) => b.totalCost - a.totalCost);

    const totals = report.reduce(
      (acc, v) => ({
        totalMaintenanceCost: acc.totalMaintenanceCost + v.maintenanceCost,
        totalFuelCost: acc.totalFuelCost + v.fuelCost,
        totalCost: acc.totalCost + v.totalCost,
        totalServiceCount: acc.totalServiceCount + v.serviceCount,
      }),
      { totalMaintenanceCost: 0, totalFuelCost: 0, totalCost: 0, totalServiceCount: 0 }
    );

    return {
      period: { startDate: start, endDate: end },
      vehicles: report,
      summary: {
        vehicleCount: report.length,
        ...totals,
      },
    };
  }

  // ==========================================================================
  // MACHINE DOWNTIME REPORT
  // ==========================================================================

  /**
   * Per-machine downtime analysis within a date range
   */
  async getMachineDowntimeReport(branchId, startDate, endDate) {
    this._validateDateRange(startDate, endDate);

    const start = new Date(startDate);
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);

    const branchFilter = branchId ? { branchId: parseInt(branchId, 10) } : {};

    const machines = await prisma.machine.findMany({
      where: { ...branchFilter, deletedAt: null },
      select: {
        id: true,
        machineCode: true,
        name: true,
        category: true,
        criticality: true,
        status: true,
        breakdownLogs: {
          where: {
            reportedAt: { gte: start, lte: end },
          },
          select: {
            id: true,
            reportedAt: true,
            resolvedAt: true,
            severity: true,
            downtimeMinutes: true,
            costOfRepair: true,
            description: true,
          },
        },
      },
    });

    const report = machines.map((m) => {
      const totalDowntimeMinutes = m.breakdownLogs.reduce(
        (sum, bl) => sum + (bl.downtimeMinutes || 0),
        0
      );
      const totalRepairCost = m.breakdownLogs.reduce(
        (sum, bl) => sum + (bl.costOfRepair ? parseFloat(bl.costOfRepair) : 0),
        0
      );
      const unresolvedCount = m.breakdownLogs.filter((bl) => !bl.resolvedAt).length;

      return {
        machineId: m.id,
        machineCode: m.machineCode,
        name: m.name,
        category: m.category,
        criticality: m.criticality,
        currentStatus: m.status,
        breakdownCount: m.breakdownLogs.length,
        unresolvedCount,
        totalDowntimeMinutes,
        totalDowntimeHours: Math.round((totalDowntimeMinutes / 60) * 100) / 100,
        totalRepairCost: Math.round(totalRepairCost * 100) / 100,
        breakdowns: m.breakdownLogs,
      };
    });

    // Sort by total downtime descending
    report.sort((a, b) => b.totalDowntimeMinutes - a.totalDowntimeMinutes);

    const totals = report.reduce(
      (acc, m) => ({
        totalBreakdowns: acc.totalBreakdowns + m.breakdownCount,
        totalDowntimeMinutes: acc.totalDowntimeMinutes + m.totalDowntimeMinutes,
        totalRepairCost: acc.totalRepairCost + m.totalRepairCost,
      }),
      { totalBreakdowns: 0, totalDowntimeMinutes: 0, totalRepairCost: 0 }
    );

    return {
      period: { startDate: start, endDate: end },
      machines: report,
      summary: {
        machineCount: report.length,
        ...totals,
        totalDowntimeHours: Math.round((totals.totalDowntimeMinutes / 60) * 100) / 100,
      },
    };
  }

  // ==========================================================================
  // INVENTORY USAGE REPORT
  // ==========================================================================

  /**
   * Stock movement summary within a date range
   */
  async getInventoryUsageReport(branchId, startDate, endDate) {
    this._validateDateRange(startDate, endDate);

    const start = new Date(startDate);
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);

    const branchFilter = branchId ? { branchId: parseInt(branchId, 10) } : {};

    // Stock movements grouped by type
    const movementsByType = await prisma.stockMovement.groupBy({
      by: ['type'],
      where: {
        ...branchFilter,
        createdAt: { gte: start, lte: end },
      },
      _count: { id: true },
      _sum: { quantity: true },
    });

    // Top consumed products (STOCK_OUT)
    const topConsumedProducts = await prisma.stockMovement.groupBy({
      by: ['productId'],
      where: {
        ...branchFilter,
        type: 'STOCK_OUT',
        createdAt: { gte: start, lte: end },
      },
      _sum: { quantity: true },
      _count: { id: true },
      orderBy: { _sum: { quantity: 'desc' } },
      take: 20,
    });

    // Get product names for top consumed
    const productIds = topConsumedProducts.map((p) => p.productId);
    const products = await prisma.product.findMany({
      where: { id: { in: productIds } },
      select: { id: true, sku: true, name: true, unit: true, currentStock: true },
    });
    const productMap = Object.fromEntries(products.map((p) => [p.id, p]));

    // Low stock products
    const lowStockProducts = await prisma.product.findMany({
      where: {
        ...branchFilter,
        isActive: true,
        deletedAt: null,
      },
      select: {
        id: true,
        sku: true,
        name: true,
        unit: true,
        currentStock: true,
        reorderLevel: true,
        minimumStock: true,
      },
    });
    const actualLowStock = lowStockProducts.filter(
      (p) => parseFloat(p.currentStock) <= parseFloat(p.reorderLevel)
    );

    return {
      period: { startDate: start, endDate: end },
      movementsByType: movementsByType.map((m) => ({
        type: m.type,
        transactionCount: m._count.id,
        totalQuantity: m._sum.quantity ? parseFloat(m._sum.quantity) : 0,
      })),
      topConsumedProducts: topConsumedProducts.map((p) => ({
        product: productMap[p.productId] || { id: p.productId },
        totalConsumed: p._sum.quantity ? parseFloat(p._sum.quantity) : 0,
        transactionCount: p._count.id,
      })),
      lowStockProducts: actualLowStock,
      summary: {
        totalMovements: movementsByType.reduce((sum, m) => sum + m._count.id, 0),
        lowStockCount: actualLowStock.length,
      },
    };
  }

  // ==========================================================================
  // EXPENSE REPORT
  // ==========================================================================

  /**
   * Grouped expense analysis within a date range
   */
  async getExpenseReport(branchId, startDate, endDate, groupBy = 'category') {
    this._validateDateRange(startDate, endDate);

    const start = new Date(startDate);
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);

    const branchFilter = branchId ? { branchId: parseInt(branchId, 10) } : {};
    const where = {
      ...branchFilter,
      date: { gte: start, lte: end },
      status: { in: ['APPROVED', 'PAID'] },
    };

    const allowedGroupBy = ['category', 'status', 'vendor'];
    const groupField = allowedGroupBy.includes(groupBy) ? groupBy : 'category';

    // Group by specified field
    const grouped = await prisma.expense.groupBy({
      by: [groupField],
      where,
      _sum: { amount: true },
      _count: { id: true },
      _avg: { amount: true },
      _max: { amount: true },
      orderBy: { _sum: { amount: 'desc' } },
    });

    // Total aggregates
    const totals = await prisma.expense.aggregate({
      where,
      _sum: { amount: true },
      _count: { id: true },
      _avg: { amount: true },
    });

    return {
      period: { startDate: start, endDate: end },
      groupedBy: groupField,
      data: grouped.map((g) => ({
        [groupField]: g[groupField],
        totalAmount: g._sum.amount ? parseFloat(g._sum.amount) : 0,
        count: g._count.id,
        averageAmount: g._avg.amount ? parseFloat(g._avg.amount) : 0,
        maxAmount: g._max.amount ? parseFloat(g._max.amount) : 0,
      })),
      summary: {
        totalExpenses: totals._sum.amount ? parseFloat(totals._sum.amount) : 0,
        transactionCount: totals._count.id,
        averageExpense: totals._avg.amount ? parseFloat(totals._avg.amount) : 0,
      },
    };
  }

  // ==========================================================================
  // MONTHLY TREND DATA
  // ==========================================================================

  /**
   * Monthly costs/requests trends for chart data
   */
  async getMonthlyTrendData(branchId, year) {
    const targetYear = parseInt(year, 10) || new Date().getFullYear();
    const branchFilter = branchId ? { branchId: parseInt(branchId, 10) } : {};

    const startOfYear = new Date(targetYear, 0, 1);
    const endOfYear = new Date(targetYear, 11, 31, 23, 59, 59, 999);

    // Monthly expenses
    const expenses = await prisma.expense.findMany({
      where: {
        ...branchFilter,
        date: { gte: startOfYear, lte: endOfYear },
        status: { in: ['APPROVED', 'PAID'] },
      },
      select: { date: true, amount: true, category: true },
    });

    // Monthly service requests
    const serviceRequests = await prisma.serviceRequest.findMany({
      where: {
        ...branchFilter,
        createdAt: { gte: startOfYear, lte: endOfYear },
        deletedAt: null,
      },
      select: { createdAt: true, status: true, actualCost: true },
    });

    // Build monthly data
    const months = Array.from({ length: 12 }, (_, i) => {
      const month = i + 1;
      const monthLabel = new Date(targetYear, i, 1).toLocaleString('default', { month: 'short' });

      const monthExpenses = expenses.filter((e) => new Date(e.date).getMonth() === i);
      const monthRequests = serviceRequests.filter((sr) => new Date(sr.createdAt).getMonth() === i);

      const totalExpenseAmount = monthExpenses.reduce(
        (sum, e) => sum + parseFloat(e.amount || 0),
        0
      );
      const totalServiceCost = monthRequests.reduce(
        (sum, sr) => sum + parseFloat(sr.actualCost || 0),
        0
      );

      return {
        month,
        monthLabel,
        expenseAmount: Math.round(totalExpenseAmount * 100) / 100,
        expenseCount: monthExpenses.length,
        serviceRequestCount: monthRequests.length,
        serviceCost: Math.round(totalServiceCost * 100) / 100,
        completedRequests: monthRequests.filter((sr) => sr.status === 'COMPLETED' || sr.status === 'CLOSED').length,
      };
    });

    return {
      year: targetYear,
      months,
      yearlyTotals: {
        totalExpenses: months.reduce((sum, m) => sum + m.expenseAmount, 0),
        totalServiceCost: months.reduce((sum, m) => sum + m.serviceCost, 0),
        totalServiceRequests: months.reduce((sum, m) => sum + m.serviceRequestCount, 0),
        totalCompleted: months.reduce((sum, m) => sum + m.completedRequests, 0),
      },
    };
  }

  // ==========================================================================
  // SERVICE REQUEST STATISTICS
  // ==========================================================================

  /**
   * Service request breakdown by status, priority, and category
   */
  async getServiceRequestStats(branchId) {
    const branchFilter = branchId ? { branchId: parseInt(branchId, 10) } : {};
    const where = { ...branchFilter, deletedAt: null };

    const [byStatus, byPriority, byCategory, overallAgg] = await Promise.all([
      prisma.serviceRequest.groupBy({
        by: ['status'],
        where,
        _count: { id: true },
      }),
      prisma.serviceRequest.groupBy({
        by: ['priority'],
        where,
        _count: { id: true },
      }),
      prisma.serviceRequest.groupBy({
        by: ['category'],
        where,
        _count: { id: true },
        _sum: { actualCost: true },
      }),
      prisma.serviceRequest.aggregate({
        where,
        _count: { id: true },
        _sum: { actualCost: true, estimatedCost: true },
        _avg: { actualCost: true },
      }),
    ]);

    // Average resolution time for completed requests
    const completedRequests = await prisma.serviceRequest.findMany({
      where: {
        ...where,
        status: { in: ['COMPLETED', 'CLOSED'] },
        completedAt: { not: null },
      },
      select: { createdAt: true, completedAt: true },
    });

    let avgResolutionHours = 0;
    if (completedRequests.length > 0) {
      const totalHours = completedRequests.reduce((sum, sr) => {
        const diffMs = new Date(sr.completedAt).getTime() - new Date(sr.createdAt).getTime();
        return sum + diffMs / (1000 * 60 * 60);
      }, 0);
      avgResolutionHours = Math.round((totalHours / completedRequests.length) * 100) / 100;
    }

    return {
      byStatus: byStatus.map((s) => ({
        status: s.status,
        count: s._count.id,
      })),
      byPriority: byPriority.map((p) => ({
        priority: p.priority,
        count: p._count.id,
      })),
      byCategory: byCategory.map((c) => ({
        category: c.category,
        count: c._count.id,
        totalCost: c._sum.actualCost ? parseFloat(c._sum.actualCost) : 0,
      })),
      summary: {
        totalRequests: overallAgg._count.id,
        totalActualCost: overallAgg._sum.actualCost ? parseFloat(overallAgg._sum.actualCost) : 0,
        totalEstimatedCost: overallAgg._sum.estimatedCost ? parseFloat(overallAgg._sum.estimatedCost) : 0,
        averageCost: overallAgg._avg.actualCost ? parseFloat(overallAgg._avg.actualCost) : 0,
        avgResolutionHours,
        completedCount: completedRequests.length,
      },
    };
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  /**
   * Validate date range inputs
   */
  _validateDateRange(startDate, endDate) {
    if (!startDate || !endDate) {
      throw new BadRequestError('Start date and end date are required');
    }
    const start = new Date(startDate);
    const end = new Date(endDate);
    if (isNaN(start.getTime()) || isNaN(end.getTime())) {
      throw new BadRequestError('Invalid date format. Use ISO 8601 (YYYY-MM-DD)');
    }
    if (start > end) {
      throw new BadRequestError('Start date must be before or equal to end date');
    }
  }
}

module.exports = new ReportService();
