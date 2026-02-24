// ============================================================================
// Nelna Maintenance System - Machine Service (Business Logic)
// ============================================================================
const prisma = require('../config/database');
const { NotFoundError, ConflictError, BadRequestError } = require('../utils/errors');
const { parsePagination, parseSort, buildSearchFilter } = require('../utils/helpers');

class MachineService {
  // ==========================================================================
  // MACHINE CRUD
  // ==========================================================================

  /**
   * Get all machines with pagination, search, and filters
   */
  async getAll(query, user) {
    const { page, limit, skip } = parsePagination(query);
    const orderBy = parseSort(query, ['createdAt', 'machineCode', 'name', 'status', 'criticality']);
    const searchFilter = buildSearchFilter(query, ['machineCode', 'name', 'manufacturer', 'serialNumber']);

    const where = {
      deletedAt: null,
      ...searchFilter,
      ...(query.status && { status: query.status }),
      ...(query.branchId && { branchId: parseInt(query.branchId, 10) }),
      ...(query.criticality && { criticality: query.criticality }),
      ...(query.category && { category: query.category }),
      ...(query.department && { department: query.department }),
    };

    // Branch-level filtering for non-admin users
    if (user.roleName !== 'super_admin' && user.roleName !== 'company_admin') {
      where.branchId = user.branchId;
    }

    const [machines, total] = await Promise.all([
      prisma.machine.findMany({
        where,
        include: {
          branch: { select: { id: true, name: true, code: true } },
        },
        orderBy,
        skip,
        take: limit,
      }),
      prisma.machine.count({ where }),
    ]);

    return { machines, pagination: { page, limit, total } };
  }

  /**
   * Get single machine by ID with all related data
   */
  async getById(id) {
    const machine = await prisma.machine.findFirst({
      where: { id, deletedAt: null },
      include: {
        branch: true,
        maintenanceSchedules: {
          where: { isActive: true },
          orderBy: { nextDueDate: 'asc' },
        },
        breakdownLogs: {
          orderBy: { reportedAt: 'desc' },
          take: 20,
        },
        amcContracts: {
          orderBy: { endDate: 'desc' },
          take: 10,
        },
        machineServiceHistory: {
          orderBy: { serviceDate: 'desc' },
          take: 20,
        },
      },
    });

    if (!machine) throw new NotFoundError('Machine not found');
    return machine;
  }

  /**
   * Create a new machine
   */
  async create(data) {
    const existing = await prisma.machine.findUnique({
      where: { machineCode: data.machineCode },
    });
    if (existing) {
      throw new ConflictError('Machine with this code already exists');
    }

    return prisma.machine.create({
      data: {
        branchId: data.branchId,
        machineCode: data.machineCode,
        name: data.name,
        category: data.category || null,
        manufacturer: data.manufacturer || null,
        modelNumber: data.modelNumber || null,
        serialNumber: data.serialNumber || null,
        purchaseDate: data.purchaseDate ? new Date(data.purchaseDate) : null,
        purchasePrice: data.purchasePrice || null,
        warrantyExpiry: data.warrantyExpiry ? new Date(data.warrantyExpiry) : null,
        location: data.location || null,
        department: data.department || null,
        status: data.status || 'OPERATIONAL',
        criticality: data.criticality || 'MEDIUM',
        operatingHours: data.operatingHours || 0,
        maintenanceInterval: data.maintenanceInterval || null,
        qrCode: data.qrCode || null,
        imageUrl: data.imageUrl || null,
        specifications: data.specifications || null,
        notes: data.notes || null,
      },
      include: { branch: true },
    });
  }

  /**
   * Update machine
   */
  async update(id, data) {
    const machine = await prisma.machine.findFirst({ where: { id, deletedAt: null } });
    if (!machine) throw new NotFoundError('Machine not found');

    if (data.machineCode && data.machineCode !== machine.machineCode) {
      const existing = await prisma.machine.findUnique({
        where: { machineCode: data.machineCode },
      });
      if (existing) throw new ConflictError('Machine code already in use');
    }

    return prisma.machine.update({
      where: { id },
      data: {
        ...(data.name && { name: data.name }),
        ...(data.category !== undefined && { category: data.category }),
        ...(data.manufacturer !== undefined && { manufacturer: data.manufacturer }),
        ...(data.modelNumber !== undefined && { modelNumber: data.modelNumber }),
        ...(data.serialNumber !== undefined && { serialNumber: data.serialNumber }),
        ...(data.purchaseDate && { purchaseDate: new Date(data.purchaseDate) }),
        ...(data.purchasePrice !== undefined && { purchasePrice: data.purchasePrice }),
        ...(data.warrantyExpiry && { warrantyExpiry: new Date(data.warrantyExpiry) }),
        ...(data.location !== undefined && { location: data.location }),
        ...(data.department !== undefined && { department: data.department }),
        ...(data.status && { status: data.status }),
        ...(data.criticality && { criticality: data.criticality }),
        ...(data.operatingHours !== undefined && { operatingHours: data.operatingHours }),
        ...(data.maintenanceInterval !== undefined && { maintenanceInterval: data.maintenanceInterval }),
        ...(data.qrCode !== undefined && { qrCode: data.qrCode }),
        ...(data.imageUrl !== undefined && { imageUrl: data.imageUrl }),
        ...(data.specifications !== undefined && { specifications: data.specifications }),
        ...(data.notes !== undefined && { notes: data.notes }),
      },
      include: { branch: true },
    });
  }

  /**
   * Delete machine (soft delete)
   */
  async delete(id) {
    const machine = await prisma.machine.findFirst({ where: { id, deletedAt: null } });
    if (!machine) throw new NotFoundError('Machine not found');
    // Explicit soft-delete — consistent with other services
    return prisma.machine.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  // ==========================================================================
  // MAINTENANCE SCHEDULES
  // ==========================================================================

  /**
   * Add a maintenance schedule for a machine
   */
  async addMaintenanceSchedule(data) {
    const machine = await prisma.machine.findFirst({
      where: { id: data.machineId, deletedAt: null },
    });
    if (!machine) throw new NotFoundError('Machine not found');

    return prisma.machineMaintenanceSchedule.create({
      data: {
        machineId: data.machineId,
        maintenanceType: data.maintenanceType,
        description: data.description,
        frequencyDays: data.frequencyDays,
        frequencyHours: data.frequencyHours || null,
        lastPerformedDate: data.lastPerformedDate ? new Date(data.lastPerformedDate) : null,
        nextDueDate: new Date(data.nextDueDate),
        assignedTeam: data.assignedTeam || null,
        estimatedDuration: data.estimatedDuration || null,
        estimatedCost: data.estimatedCost || null,
      },
      include: { machine: { select: { id: true, machineCode: true, name: true } } },
    });
  }

  /**
   * Get maintenance schedules for a machine
   */
  async getMaintenanceSchedules(machineId, query) {
    const { page, limit, skip } = parsePagination(query);

    const where = { machineId };
    if (query.isActive !== undefined) {
      where.isActive = query.isActive === 'true';
    }

    const [schedules, total] = await Promise.all([
      prisma.machineMaintenanceSchedule.findMany({
        where,
        orderBy: { nextDueDate: 'asc' },
        skip,
        take: limit,
      }),
      prisma.machineMaintenanceSchedule.count({ where }),
    ]);

    return { schedules, pagination: { page, limit, total } };
  }

  // ==========================================================================
  // BREAKDOWN LOGS
  // ==========================================================================

  /**
   * Log a new breakdown
   */
  async logBreakdown(data) {
    const machine = await prisma.machine.findFirst({
      where: { id: data.machineId, deletedAt: null },
    });
    if (!machine) throw new NotFoundError('Machine not found');

    const breakdown = await prisma.breakdownLog.create({
      data: {
        machineId: data.machineId,
        reportedAt: new Date(data.reportedAt),
        severity: data.severity,
        description: data.description,
        rootCause: data.rootCause || null,
        reportedBy: data.reportedBy || null,
      },
      include: { machine: { select: { id: true, machineCode: true, name: true } } },
    });

    // Update machine status to BREAKDOWN
    await prisma.machine.update({
      where: { id: data.machineId },
      data: { status: 'BREAKDOWN' },
    });

    return breakdown;
  }

  /**
   * Get breakdowns for a machine
   */
  async getBreakdowns(machineId, query) {
    const { page, limit, skip } = parsePagination(query);

    const where = { machineId };
    if (query.severity) {
      where.severity = query.severity;
    }
    if (query.resolved === 'true') {
      where.resolvedAt = { not: null };
    } else if (query.resolved === 'false') {
      where.resolvedAt = null;
    }

    const [breakdowns, total] = await Promise.all([
      prisma.breakdownLog.findMany({
        where,
        include: { machine: { select: { id: true, machineCode: true, name: true } } },
        orderBy: { reportedAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.breakdownLog.count({ where }),
    ]);

    return { breakdowns, pagination: { page, limit, total } };
  }

  /**
   * Resolve a breakdown
   */
  async resolveBreakdown(id, data) {
    const breakdown = await prisma.breakdownLog.findUnique({ where: { id } });
    if (!breakdown) throw new NotFoundError('Breakdown log not found');

    if (breakdown.resolvedAt) {
      throw new ConflictError('Breakdown is already resolved');
    }

    const resolvedAt = new Date(data.resolvedAt);
    const reportedAt = new Date(breakdown.reportedAt);

    // Validate resolvedAt is after reportedAt to prevent negative downtime
    if (resolvedAt <= reportedAt) {
      throw new BadRequestError('Resolution time must be after the reported time');
    }

    const downtimeMinutes = Math.round((resolvedAt - reportedAt) / (1000 * 60));

    const resolved = await prisma.breakdownLog.update({
      where: { id },
      data: {
        resolvedAt,
        resolution: data.resolution,
        rootCause: data.rootCause || breakdown.rootCause,
        costOfRepair: data.costOfRepair || null,
        resolvedBy: data.resolvedBy || null,
        downtimeMinutes,
      },
      include: { machine: { select: { id: true, machineCode: true, name: true } } },
    });

    // Check if there are other unresolved breakdowns for this machine
    const unresolvedCount = await prisma.breakdownLog.count({
      where: { machineId: breakdown.machineId, resolvedAt: null },
    });

    // Restore machine status to OPERATIONAL if no more unresolved breakdowns
    if (unresolvedCount === 0) {
      await prisma.machine.update({
        where: { id: breakdown.machineId },
        data: { status: 'OPERATIONAL' },
      });
    }

    return resolved;
  }

  // ==========================================================================
  // DOWNTIME CALCULATION
  // ==========================================================================

  /**
   * Calculate total downtime for a machine in a date range
   */
  async calculateDowntime(machineId, startDate, endDate) {
    const machine = await prisma.machine.findFirst({
      where: { id: machineId, deletedAt: null },
    });
    if (!machine) throw new NotFoundError('Machine not found');

    const start = new Date(startDate);
    const end = new Date(endDate);

    if (start >= end) {
      throw new BadRequestError('Start date must be before end date');
    }

    const breakdowns = await prisma.breakdownLog.findMany({
      where: {
        machineId,
        reportedAt: { gte: start, lte: end },
      },
      orderBy: { reportedAt: 'asc' },
    });

    let totalDowntimeMinutes = 0;
    let resolvedCount = 0;
    let unresolvedCount = 0;

    for (const b of breakdowns) {
      if (b.downtimeMinutes) {
        totalDowntimeMinutes += b.downtimeMinutes;
        resolvedCount++;
      } else if (b.resolvedAt) {
        const diff = Math.round((new Date(b.resolvedAt) - new Date(b.reportedAt)) / (1000 * 60));
        totalDowntimeMinutes += diff;
        resolvedCount++;
      } else {
        // Ongoing breakdown — count from reported to end of range
        const diff = Math.round((end - new Date(b.reportedAt)) / (1000 * 60));
        totalDowntimeMinutes += diff;
        unresolvedCount++;
      }
    }

    const totalRangeMinutes = Math.round((end - start) / (1000 * 60));
    const uptimePercentage = totalRangeMinutes > 0
      ? (((totalRangeMinutes - totalDowntimeMinutes) / totalRangeMinutes) * 100).toFixed(2)
      : '100.00';

    return {
      machine: {
        id: machine.id,
        machineCode: machine.machineCode,
        name: machine.name,
      },
      period: { startDate: start, endDate: end },
      totalBreakdowns: breakdowns.length,
      resolvedBreakdowns: resolvedCount,
      unresolvedBreakdowns: unresolvedCount,
      totalDowntimeMinutes,
      totalDowntimeHours: parseFloat((totalDowntimeMinutes / 60).toFixed(2)),
      uptimePercentage: parseFloat(uptimePercentage),
    };
  }

  // ==========================================================================
  // AMC CONTRACTS
  // ==========================================================================

  /**
   * Add an AMC contract for a machine
   */
  async addAMCContract(data) {
    const machine = await prisma.machine.findFirst({
      where: { id: data.machineId, deletedAt: null },
    });
    if (!machine) throw new NotFoundError('Machine not found');

    const existingContract = await prisma.aMCContract.findUnique({
      where: { contractNo: data.contractNo },
    });
    if (existingContract) {
      throw new ConflictError('Contract number already exists');
    }

    return prisma.aMCContract.create({
      data: {
        machineId: data.machineId,
        contractNo: data.contractNo,
        vendor: data.vendor,
        startDate: new Date(data.startDate),
        endDate: new Date(data.endDate),
        annualCost: data.annualCost,
        coverageDetails: data.coverageDetails || null,
        contactPerson: data.contactPerson || null,
        contactPhone: data.contactPhone || null,
        documentUrl: data.documentUrl || null,
        status: data.status || 'ACTIVE',
      },
      include: { machine: { select: { id: true, machineCode: true, name: true } } },
    });
  }

  /**
   * Get AMC contracts for a machine
   */
  async getAMCContracts(machineId, query) {
    const { page, limit, skip } = parsePagination(query);

    const where = { machineId };
    if (query.status) {
      where.status = query.status;
    }

    const [contracts, total] = await Promise.all([
      prisma.aMCContract.findMany({
        where,
        include: { machine: { select: { id: true, machineCode: true, name: true } } },
        orderBy: { endDate: 'desc' },
        skip,
        take: limit,
      }),
      prisma.aMCContract.count({ where }),
    ]);

    return { contracts, pagination: { page, limit, total } };
  }

  // ==========================================================================
  // SERVICE HISTORY
  // ==========================================================================

  /**
   * Add a service history record
   */
  async addServiceHistory(data) {
    const machine = await prisma.machine.findFirst({
      where: { id: data.machineId, deletedAt: null },
    });
    if (!machine) throw new NotFoundError('Machine not found');

    const record = await prisma.machineServiceHistory.create({
      data: {
        machineId: data.machineId,
        serviceDate: new Date(data.serviceDate),
        serviceType: data.serviceType,
        description: data.description,
        hoursAtService: data.hoursAtService || null,
        cost: data.cost,
        performedBy: data.performedBy || null,
        notes: data.notes || null,
      },
      include: { machine: { select: { id: true, machineCode: true, name: true } } },
    });

    // Update machine last maintenance date
    await prisma.machine.update({
      where: { id: data.machineId },
      data: {
        lastMaintenanceDate: new Date(data.serviceDate),
        ...(data.hoursAtService && { operatingHours: data.hoursAtService }),
        ...(machine.maintenanceInterval && {
          nextMaintenanceDate: new Date(
            new Date(data.serviceDate).getTime() + machine.maintenanceInterval * 24 * 60 * 60 * 1000
          ),
        }),
      },
    });

    return record;
  }

  // ==========================================================================
  // OVERDUE MAINTENANCES
  // ==========================================================================

  /**
   * Get all overdue maintenance schedules across machines
   */
  async getOverdueMaintenances(query, user) {
    const now = new Date();

    const where = {
      isActive: true,
      nextDueDate: { lt: now },
      machine: { deletedAt: null },
    };

    // Branch-level filtering for non-admin users
    if (user.roleName !== 'super_admin' && user.roleName !== 'company_admin') {
      where.machine.branchId = user.branchId;
    } else if (query.branchId) {
      where.machine.branchId = parseInt(query.branchId, 10);
    }

    const { page, limit, skip } = parsePagination(query);

    const [schedules, total] = await Promise.all([
      prisma.machineMaintenanceSchedule.findMany({
        where,
        include: {
          machine: {
            select: {
              id: true,
              machineCode: true,
              name: true,
              criticality: true,
              location: true,
              branch: { select: { id: true, name: true, code: true } },
            },
          },
        },
        orderBy: { nextDueDate: 'asc' },
        skip,
        take: limit,
      }),
      prisma.machineMaintenanceSchedule.count({ where }),
    ]);

    // Enrich with overdue days
    const enriched = schedules.map((s) => ({
      ...s,
      overdueDays: Math.floor((now - new Date(s.nextDueDate)) / (1000 * 60 * 60 * 24)),
    }));

    return { schedules: enriched, pagination: { page, limit, total } };
  }
}

module.exports = new MachineService();
