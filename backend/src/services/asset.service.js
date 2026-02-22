// ============================================================================
// Nelna Maintenance System - Asset (Stores) Service (Business Logic)
// ============================================================================
const prisma = require('../config/database');
const { NotFoundError, ConflictError, BadRequestError } = require('../utils/errors');
const { generateReferenceNo, parsePagination, parseSort, buildSearchFilter } = require('../utils/helpers');

class AssetService {
  // ==========================================================================
  // ASSET CRUD
  // ==========================================================================

  /**
   * Get all assets with pagination, search, and filters
   */
  async getAll(query, user) {
    const { page, limit, skip } = parsePagination(query);
    const orderBy = parseSort(query, ['createdAt', 'assetCode', 'name', 'status', 'condition', 'category', 'currentValue']);
    const searchFilter = buildSearchFilter(query, ['assetCode', 'name', 'serialNumber', 'assignedTo']);

    const where = {
      deletedAt: null,
      ...searchFilter,
      ...(query.status && { status: query.status }),
      ...(query.condition && { condition: query.condition }),
      ...(query.category && { category: query.category }),
      ...(query.branchId && { branchId: parseInt(query.branchId, 10) }),
      ...(query.department && { department: query.department }),
    };

    // Branch-level filtering for non-admin users
    if (user.roleName !== 'super_admin' && user.roleName !== 'company_admin') {
      where.branchId = user.branchId;
    }

    const [assets, total] = await Promise.all([
      prisma.asset.findMany({
        where,
        include: {
          branch: { select: { id: true, name: true, code: true } },
          _count: {
            select: { repairLogs: true, transfers: true, serviceRequests: true },
          },
        },
        orderBy,
        skip,
        take: limit,
      }),
      prisma.asset.count({ where }),
    ]);

    return { assets, pagination: { page, limit, total } };
  }

  /**
   * Get single asset by ID with all related data
   */
  async getById(id) {
    const asset = await prisma.asset.findFirst({
      where: { id, deletedAt: null },
      include: {
        branch: true,
        repairLogs: {
          orderBy: { repairDate: 'desc' },
          take: 20,
        },
        transfers: {
          orderBy: { transferDate: 'desc' },
          take: 20,
        },
        serviceRequests: {
          orderBy: { createdAt: 'desc' },
          take: 10,
          select: {
            id: true,
            ticketNo: true,
            subject: true,
            status: true,
            priority: true,
            createdAt: true,
          },
        },
      },
    });

    if (!asset) throw new NotFoundError('Asset not found');
    return asset;
  }

  /**
   * Create a new asset with auto-generated assetCode
   */
  async create(data) {
    // Auto-generate asset code
    const assetCode = generateReferenceNo('AST');

    // Check for duplicate serial number if provided
    if (data.serialNumber) {
      const existing = await prisma.asset.findFirst({
        where: { serialNumber: data.serialNumber, deletedAt: null },
      });
      if (existing) {
        throw new ConflictError('Asset with this serial number already exists');
      }
    }

    return prisma.asset.create({
      data: {
        branchId: data.branchId,
        assetCode,
        name: data.name,
        category: data.category,
        location: data.location || null,
        department: data.department || null,
        serialNumber: data.serialNumber || null,
        purchaseDate: data.purchaseDate ? new Date(data.purchaseDate) : null,
        purchasePrice: data.purchasePrice || null,
        currentValue: data.currentValue || data.purchasePrice || null,
        depreciationRate: data.depreciationRate || null,
        warrantyExpiry: data.warrantyExpiry ? new Date(data.warrantyExpiry) : null,
        condition: data.condition || 'GOOD',
        status: data.status || 'IN_USE',
        assignedTo: data.assignedTo || null,
        imageUrl: data.imageUrl || null,
        notes: data.notes || null,
      },
      include: { branch: true },
    });
  }

  /**
   * Update an existing asset
   */
  async update(id, data) {
    const asset = await prisma.asset.findFirst({
      where: { id, deletedAt: null },
    });
    if (!asset) throw new NotFoundError('Asset not found');

    // Check serial number uniqueness if being changed
    if (data.serialNumber && data.serialNumber !== asset.serialNumber) {
      const existing = await prisma.asset.findFirst({
        where: {
          serialNumber: data.serialNumber,
          deletedAt: null,
          NOT: { id },
        },
      });
      if (existing) {
        throw new ConflictError('Asset with this serial number already exists');
      }
    }

    return prisma.asset.update({
      where: { id },
      data: {
        ...(data.name !== undefined && { name: data.name }),
        ...(data.category !== undefined && { category: data.category }),
        ...(data.location !== undefined && { location: data.location }),
        ...(data.department !== undefined && { department: data.department }),
        ...(data.serialNumber !== undefined && { serialNumber: data.serialNumber }),
        ...(data.purchaseDate !== undefined && { purchaseDate: new Date(data.purchaseDate) }),
        ...(data.purchasePrice !== undefined && { purchasePrice: data.purchasePrice }),
        ...(data.currentValue !== undefined && { currentValue: data.currentValue }),
        ...(data.depreciationRate !== undefined && { depreciationRate: data.depreciationRate }),
        ...(data.warrantyExpiry !== undefined && { warrantyExpiry: new Date(data.warrantyExpiry) }),
        ...(data.condition !== undefined && { condition: data.condition }),
        ...(data.status !== undefined && { status: data.status }),
        ...(data.assignedTo !== undefined && { assignedTo: data.assignedTo }),
        ...(data.imageUrl !== undefined && { imageUrl: data.imageUrl }),
        ...(data.notes !== undefined && { notes: data.notes }),
      },
      include: { branch: true },
    });
  }

  /**
   * Soft delete an asset
   */
  async delete(id) {
    const asset = await prisma.asset.findFirst({
      where: { id, deletedAt: null },
    });
    if (!asset) throw new NotFoundError('Asset not found');

    return prisma.asset.update({
      where: { id },
      data: { deletedAt: new Date(), status: 'DISPOSED' },
    });
  }

  // ==========================================================================
  // REPAIR LOGS
  // ==========================================================================

  /**
   * Add a repair log for an asset
   */
  async addRepairLog(data) {
    const asset = await prisma.asset.findFirst({
      where: { id: data.assetId, deletedAt: null },
    });
    if (!asset) throw new NotFoundError('Asset not found');

    return prisma.$transaction(async (tx) => {
      const repairLog = await tx.assetRepairLog.create({
        data: {
          assetId: data.assetId,
          repairDate: new Date(data.repairDate),
          description: data.description,
          cost: data.cost,
          vendor: data.vendor || null,
          completedDate: data.completedDate ? new Date(data.completedDate) : null,
          notes: data.notes || null,
        },
        include: { asset: { select: { id: true, assetCode: true, name: true } } },
      });

      // If repair is not yet completed, set asset to UNDER_REPAIR
      if (!data.completedDate) {
        await tx.asset.update({
          where: { id: data.assetId },
          data: { status: 'UNDER_REPAIR' },
        });
      }

      return repairLog;
    });
  }

  /**
   * Get repair history for an asset with pagination
   */
  async getRepairHistory(assetId, query) {
    const { page, limit, skip } = parsePagination(query);

    const asset = await prisma.asset.findFirst({
      where: { id: assetId, deletedAt: null },
    });
    if (!asset) throw new NotFoundError('Asset not found');

    const where = { assetId };

    const [repairLogs, total] = await Promise.all([
      prisma.assetRepairLog.findMany({
        where,
        orderBy: { repairDate: 'desc' },
        skip,
        take: limit,
      }),
      prisma.assetRepairLog.count({ where }),
    ]);

    return { repairLogs, pagination: { page, limit, total } };
  }

  // ==========================================================================
  // ASSET TRANSFERS
  // ==========================================================================

  /**
   * Transfer an asset to a new location/department
   */
  async transferAsset(data) {
    const asset = await prisma.asset.findFirst({
      where: { id: data.assetId, deletedAt: null },
    });
    if (!asset) throw new NotFoundError('Asset not found');

    if (asset.status === 'DISPOSED' || asset.status === 'LOST') {
      throw new BadRequestError(`Cannot transfer an asset with status: ${asset.status}`);
    }

    return prisma.$transaction(async (tx) => {
      // Create transfer record
      const transfer = await tx.assetTransfer.create({
        data: {
          assetId: data.assetId,
          fromLocation: data.fromLocation,
          toLocation: data.toLocation,
          fromDepartment: data.fromDepartment || null,
          toDepartment: data.toDepartment || null,
          transferDate: new Date(data.transferDate),
          reason: data.reason || null,
          approvedBy: data.approvedBy || null,
        },
        include: { asset: { select: { id: true, assetCode: true, name: true } } },
      });

      // Update asset location, department, and status
      await tx.asset.update({
        where: { id: data.assetId },
        data: {
          location: data.toLocation,
          department: data.toDepartment || asset.department,
          status: 'TRANSFERRED',
        },
      });

      return transfer;
    });
  }

  // ==========================================================================
  // ASSET LIFECYCLE & ANALYTICS
  // ==========================================================================

  /**
   * Get asset lifecycle data: aggregate repair costs, depreciation info
   */
  async getAssetLifecycle(id) {
    const asset = await prisma.asset.findFirst({
      where: { id, deletedAt: null },
      include: {
        repairLogs: true,
        transfers: { orderBy: { transferDate: 'desc' } },
      },
    });
    if (!asset) throw new NotFoundError('Asset not found');

    // Aggregate repair costs
    const repairCostAggregate = await prisma.assetRepairLog.aggregate({
      where: { assetId: id },
      _sum: { cost: true },
      _count: { id: true },
      _avg: { cost: true },
      _max: { cost: true },
    });

    // Calculate depreciation
    const purchasePrice = asset.purchasePrice ? parseFloat(asset.purchasePrice) : 0;
    const depreciationRate = asset.depreciationRate ? parseFloat(asset.depreciationRate) : 0;
    const purchaseDate = asset.purchaseDate ? new Date(asset.purchaseDate) : null;
    let depreciatedValue = purchasePrice;
    let yearsOwned = 0;
    let totalDepreciation = 0;

    if (purchaseDate && purchasePrice > 0 && depreciationRate > 0) {
      const now = new Date();
      yearsOwned = (now.getTime() - purchaseDate.getTime()) / (365.25 * 24 * 60 * 60 * 1000);
      totalDepreciation = purchasePrice * (depreciationRate / 100) * yearsOwned;
      depreciatedValue = Math.max(0, purchasePrice - totalDepreciation);
    }

    // Warranty status
    const warrantyActive = asset.warrantyExpiry
      ? new Date(asset.warrantyExpiry) > new Date()
      : false;
    const warrantyDaysRemaining = asset.warrantyExpiry
      ? Math.max(0, Math.ceil((new Date(asset.warrantyExpiry).getTime() - Date.now()) / (24 * 60 * 60 * 1000)))
      : 0;

    return {
      asset,
      lifecycle: {
        purchasePrice,
        currentValue: asset.currentValue ? parseFloat(asset.currentValue) : depreciatedValue,
        depreciatedValue: Math.round(depreciatedValue * 100) / 100,
        totalDepreciation: Math.round(totalDepreciation * 100) / 100,
        depreciationRate,
        yearsOwned: Math.round(yearsOwned * 100) / 100,
        totalRepairCost: repairCostAggregate._sum.cost ? parseFloat(repairCostAggregate._sum.cost) : 0,
        repairCount: repairCostAggregate._count.id,
        averageRepairCost: repairCostAggregate._avg.cost ? parseFloat(repairCostAggregate._avg.cost) : 0,
        maxRepairCost: repairCostAggregate._max.cost ? parseFloat(repairCostAggregate._max.cost) : 0,
        totalCostOfOwnership: purchasePrice + (repairCostAggregate._sum.cost ? parseFloat(repairCostAggregate._sum.cost) : 0),
        warrantyActive,
        warrantyDaysRemaining,
        transferCount: asset.transfers.length,
      },
    };
  }

  /**
   * Get assets grouped by condition
   */
  async getAssetsByCondition(query, user) {
    const where = { deletedAt: null };

    if (query.branchId) {
      where.branchId = parseInt(query.branchId, 10);
    } else if (user.roleName !== 'super_admin' && user.roleName !== 'company_admin') {
      where.branchId = user.branchId;
    }

    const conditionGroups = await prisma.asset.groupBy({
      by: ['condition'],
      where,
      _count: { id: true },
      _sum: { currentValue: true },
    });

    const statusGroups = await prisma.asset.groupBy({
      by: ['status'],
      where,
      _count: { id: true },
    });

    const categoryGroups = await prisma.asset.groupBy({
      by: ['category'],
      where,
      _count: { id: true },
      _sum: { currentValue: true },
    });

    return {
      byCondition: conditionGroups.map((g) => ({
        condition: g.condition,
        count: g._count.id,
        totalValue: g._sum.currentValue ? parseFloat(g._sum.currentValue) : 0,
      })),
      byStatus: statusGroups.map((g) => ({
        status: g.status,
        count: g._count.id,
      })),
      byCategory: categoryGroups.map((g) => ({
        category: g.category,
        count: g._count.id,
        totalValue: g._sum.currentValue ? parseFloat(g._sum.currentValue) : 0,
      })),
    };
  }
}

module.exports = new AssetService();
