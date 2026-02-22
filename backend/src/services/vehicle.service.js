// ============================================================================
// Nelna Maintenance System - Vehicle Service (Business Logic)
// ============================================================================
const prisma = require('../config/database');
const { NotFoundError, ConflictError, BadRequestError } = require('../utils/errors');
const { parsePagination, parseSort, buildSearchFilter, isWithinDays } = require('../utils/helpers');

class VehicleService {
  /**
   * Get all vehicles with pagination, search, and filters
   */
  async getAll(query, user) {
    const { page, limit, skip } = parsePagination(query);
    const orderBy = parseSort(query, ['createdAt', 'registrationNo', 'make', 'model', 'status']);
    const searchFilter = buildSearchFilter(query, ['registrationNo', 'make', 'model', 'chassisNo']);

    const where = {
      deletedAt: null,
      ...searchFilter,
      ...(query.status && { status: query.status }),
      ...(query.branchId && { branchId: parseInt(query.branchId, 10) }),
      ...(query.fuelType && { fuelType: query.fuelType }),
      ...(query.vehicleType && { vehicleType: query.vehicleType }),
    };

    // Branch-level filtering for non-admin users
    if (user.roleName !== 'super_admin' && user.roleName !== 'company_admin') {
      where.branchId = user.branchId;
    }

    const [vehicles, total] = await Promise.all([
      prisma.vehicle.findMany({
        where,
        include: {
          branch: { select: { id: true, name: true, code: true } },
          drivers: {
            where: { isActive: true },
            include: {
              driver: { select: { id: true, firstName: true, lastName: true } },
            },
          },
        },
        orderBy,
        skip,
        take: limit,
      }),
      prisma.vehicle.count({ where }),
    ]);

    return { vehicles, pagination: { page, limit, total } };
  }

  /**
   * Get single vehicle by ID
   */
  async getById(id) {
    const vehicle = await prisma.vehicle.findFirst({
      where: { id, deletedAt: null },
      include: {
        branch: true,
        documents: { orderBy: { expiryDate: 'desc' } },
        fuelLogs: { orderBy: { date: 'desc' }, take: 20 },
        serviceHistory: { orderBy: { serviceDate: 'desc' }, take: 20 },
        drivers: {
          include: {
            driver: { select: { id: true, firstName: true, lastName: true, phone: true } },
          },
          orderBy: { assignedDate: 'desc' },
        },
      },
    });

    if (!vehicle) throw new NotFoundError('Vehicle not found');
    return vehicle;
  }

  /**
   * Create a new vehicle
   */
  async create(data) {
    const existing = await prisma.vehicle.findUnique({
      where: { registrationNo: data.registrationNo },
    });
    if (existing) {
      throw new ConflictError('Vehicle with this registration number already exists');
    }

    return prisma.vehicle.create({
      data: {
        branchId: data.branchId,
        registrationNo: data.registrationNo,
        make: data.make,
        model: data.model,
        year: data.year || null,
        engineNo: data.engineNo || null,
        chassisNo: data.chassisNo || null,
        fuelType: data.fuelType || 'DIESEL',
        vehicleType: data.vehicleType,
        color: data.color || null,
        mileage: data.mileage || 0,
        status: data.status || 'ACTIVE',
        purchaseDate: data.purchaseDate ? new Date(data.purchaseDate) : null,
        purchasePrice: data.purchasePrice || null,
        insuranceExpiry: data.insuranceExpiry ? new Date(data.insuranceExpiry) : null,
        licenseExpiry: data.licenseExpiry ? new Date(data.licenseExpiry) : null,
        imageUrl: data.imageUrl || null,
        notes: data.notes || null,
      },
      include: { branch: true },
    });
  }

  /**
   * Update vehicle
   */
  async update(id, data) {
    const vehicle = await prisma.vehicle.findFirst({ where: { id, deletedAt: null } });
    if (!vehicle) throw new NotFoundError('Vehicle not found');

    if (data.registrationNo && data.registrationNo !== vehicle.registrationNo) {
      const existing = await prisma.vehicle.findUnique({
        where: { registrationNo: data.registrationNo },
      });
      if (existing) throw new ConflictError('Registration number already in use');
    }

    return prisma.vehicle.update({
      where: { id },
      data: {
        ...(data.make && { make: data.make }),
        ...(data.model && { model: data.model }),
        ...(data.year && { year: data.year }),
        ...(data.engineNo !== undefined && { engineNo: data.engineNo }),
        ...(data.chassisNo !== undefined && { chassisNo: data.chassisNo }),
        ...(data.fuelType && { fuelType: data.fuelType }),
        ...(data.vehicleType && { vehicleType: data.vehicleType }),
        ...(data.color !== undefined && { color: data.color }),
        ...(data.mileage !== undefined && { mileage: data.mileage }),
        ...(data.status && { status: data.status }),
        ...(data.insuranceExpiry && { insuranceExpiry: new Date(data.insuranceExpiry) }),
        ...(data.licenseExpiry && { licenseExpiry: new Date(data.licenseExpiry) }),
        ...(data.imageUrl !== undefined && { imageUrl: data.imageUrl }),
        ...(data.notes !== undefined && { notes: data.notes }),
      },
      include: { branch: true },
    });
  }

  /**
   * Delete vehicle (soft delete)
   */
  async delete(id) {
    const vehicle = await prisma.vehicle.findFirst({ where: { id, deletedAt: null } });
    if (!vehicle) throw new NotFoundError('Vehicle not found');
    return prisma.vehicle.delete({ where: { id } }); // Intercepted by soft-delete middleware
  }

  /**
   * Add fuel log
   */
  async addFuelLog(data) {
    const vehicle = await prisma.vehicle.findFirst({
      where: { id: data.vehicleId, deletedAt: null },
    });
    if (!vehicle) throw new NotFoundError('Vehicle not found');

    const fuelLog = await prisma.fuelLog.create({
      data: {
        vehicleId: data.vehicleId,
        date: new Date(data.date),
        fuelType: data.fuelType,
        quantity: data.quantity,
        unitPrice: data.unitPrice,
        totalCost: data.totalCost,
        mileage: data.mileage,
        station: data.station || null,
        receiptNo: data.receiptNo || null,
        notes: data.notes || null,
      },
    });

    // Update vehicle mileage
    if (parseFloat(data.mileage) > parseFloat(vehicle.mileage)) {
      await prisma.vehicle.update({
        where: { id: data.vehicleId },
        data: { mileage: data.mileage },
      });
    }

    return fuelLog;
  }

  /**
   * Get fuel logs for a vehicle
   */
  async getFuelLogs(vehicleId, query) {
    const { page, limit, skip } = parsePagination(query);

    const where = { vehicleId };
    if (query.startDate && query.endDate) {
      where.date = {
        gte: new Date(query.startDate),
        lte: new Date(query.endDate),
      };
    }

    const [logs, total] = await Promise.all([
      prisma.fuelLog.findMany({
        where,
        orderBy: { date: 'desc' },
        skip,
        take: limit,
      }),
      prisma.fuelLog.count({ where }),
    ]);

    return { logs, pagination: { page, limit, total } };
  }

  /**
   * Add vehicle document
   */
  async addDocument(data) {
    return prisma.vehicleDocument.create({
      data: {
        vehicleId: data.vehicleId,
        type: data.type,
        documentNo: data.documentNo,
        issueDate: new Date(data.issueDate),
        expiryDate: new Date(data.expiryDate),
        provider: data.provider || null,
        amount: data.amount || null,
        fileUrl: data.fileUrl || null,
        notes: data.notes || null,
      },
    });
  }

  /**
   * Assign driver to vehicle
   */
  async assignDriver(data) {
    // Release any currently active driver assignment for this vehicle
    await prisma.vehicleDriver.updateMany({
      where: { vehicleId: data.vehicleId, isActive: true },
      data: { isActive: false, releasedDate: new Date() },
    });

    return prisma.vehicleDriver.create({
      data: {
        vehicleId: data.vehicleId,
        driverId: data.driverId,
        assignedDate: new Date(data.assignedDate),
        notes: data.notes || null,
      },
      include: {
        driver: { select: { id: true, firstName: true, lastName: true } },
      },
    });
  }

  /**
   * Get vehicles needing service (reminder system)
   */
  async getServiceReminders(branchId = null) {
    const where = {
      deletedAt: null,
      status: { not: 'DISPOSED' },
      ...(branchId && { branchId }),
    };

    const vehicles = await prisma.vehicle.findMany({
      where,
      select: {
        id: true,
        registrationNo: true,
        make: true,
        model: true,
        mileage: true,
        nextServiceDate: true,
        nextServiceMileage: true,
        insuranceExpiry: true,
        licenseExpiry: true,
      },
    });

    const reminders = [];
    const now = new Date();

    for (const v of vehicles) {
      if (v.nextServiceDate && isWithinDays(v.nextServiceDate, 30)) {
        reminders.push({
          vehicleId: v.id,
          registrationNo: v.registrationNo,
          type: 'SERVICE_DUE',
          message: `Service due on ${v.nextServiceDate.toISOString().split('T')[0]}`,
          dueDate: v.nextServiceDate,
        });
      }
      if (v.nextServiceMileage && parseFloat(v.mileage) >= parseFloat(v.nextServiceMileage) * 0.95) {
        reminders.push({
          vehicleId: v.id,
          registrationNo: v.registrationNo,
          type: 'MILEAGE_SERVICE_DUE',
          message: `Mileage service due (Current: ${v.mileage}, Due: ${v.nextServiceMileage})`,
        });
      }
      if (v.insuranceExpiry && isWithinDays(v.insuranceExpiry, 30)) {
        reminders.push({
          vehicleId: v.id,
          registrationNo: v.registrationNo,
          type: 'INSURANCE_EXPIRY',
          message: `Insurance expires on ${v.insuranceExpiry.toISOString().split('T')[0]}`,
          dueDate: v.insuranceExpiry,
        });
      }
      if (v.licenseExpiry && isWithinDays(v.licenseExpiry, 30)) {
        reminders.push({
          vehicleId: v.id,
          registrationNo: v.registrationNo,
          type: 'LICENSE_EXPIRY',
          message: `License expires on ${v.licenseExpiry.toISOString().split('T')[0]}`,
          dueDate: v.licenseExpiry,
        });
      }
    }

    return reminders;
  }

  /**
   * Get vehicle cost analytics
   */
  async getCostAnalytics(vehicleId, startDate, endDate) {
    const vehicle = await prisma.vehicle.findFirst({
      where: { id: vehicleId, deletedAt: null },
    });
    if (!vehicle) throw new NotFoundError('Vehicle not found');

    const dateFilter = {};
    if (startDate) dateFilter.gte = new Date(startDate);
    if (endDate) dateFilter.lte = new Date(endDate);

    const [fuelCosts, serviceCosts] = await Promise.all([
      prisma.fuelLog.aggregate({
        where: {
          vehicleId,
          ...(Object.keys(dateFilter).length > 0 && { date: dateFilter }),
        },
        _sum: { totalCost: true },
        _count: true,
        _avg: { unitPrice: true },
      }),
      prisma.vehicleServiceHistory.aggregate({
        where: {
          vehicleId,
          ...(Object.keys(dateFilter).length > 0 && { serviceDate: dateFilter }),
        },
        _sum: { cost: true },
        _count: true,
      }),
    ]);

    return {
      vehicle: {
        id: vehicle.id,
        registrationNo: vehicle.registrationNo,
        make: vehicle.make,
        model: vehicle.model,
      },
      fuelCosts: {
        totalCost: fuelCosts._sum.totalCost || 0,
        entries: fuelCosts._count,
        avgUnitPrice: fuelCosts._avg.unitPrice || 0,
      },
      serviceCosts: {
        totalCost: serviceCosts._sum.cost || 0,
        entries: serviceCosts._count,
      },
      totalCost:
        (parseFloat(fuelCosts._sum.totalCost) || 0) +
        (parseFloat(serviceCosts._sum.cost) || 0),
    };
  }
}

module.exports = new VehicleService();
