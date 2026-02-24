// ============================================================================
// Nelna Maintenance System - Service Request Service (Business Logic)
// ============================================================================
const prisma = require('../config/database');
const { NotFoundError, BadRequestError } = require('../utils/errors');
const { generateReferenceNo, parsePagination, parseSort, buildSearchFilter } = require('../utils/helpers');

// SLA deadline offsets in hours based on priority
const SLA_HOURS = {
  CRITICAL: 4,
  URGENT: 8,
  HIGH: 24,
  MEDIUM: 48,
  LOW: 72,
};

class ServiceService {
  // ==========================================================================
  // SERVICE REQUEST CRUD
  // ==========================================================================

  /**
   * Get all service requests with pagination, search, and filters
   */
  async getAll(query, user) {
    const { page, limit, skip } = parsePagination(query);
    const orderBy = parseSort(query, [
      'createdAt', 'ticketNo', 'priority', 'status', 'slaDeadline', 'category',
    ]);
    const searchFilter = buildSearchFilter(query, ['ticketNo', 'subject', 'description']);

    const where = {
      deletedAt: null,
      ...searchFilter,
      ...(query.status && { status: query.status }),
      ...(query.priority && { priority: query.priority }),
      ...(query.category && { category: query.category }),
      ...(query.branchId && { branchId: parseInt(query.branchId, 10) }),
    };

    // Branch-level filtering for non-admin users
    if (user.roleName !== 'super_admin' && user.roleName !== 'company_admin') {
      where.branchId = user.branchId;
    }

    const [serviceRequests, total] = await Promise.all([
      prisma.serviceRequest.findMany({
        where,
        include: {
          branch: { select: { id: true, name: true, code: true } },
          requester: { select: { id: true, firstName: true, lastName: true, email: true } },
          approver: { select: { id: true, firstName: true, lastName: true, email: true } },
          vehicle: { select: { id: true, registrationNo: true, make: true, model: true } },
          machine: { select: { id: true, machineCode: true, name: true } },
          asset: { select: { id: true, assetCode: true, name: true } },
          _count: { select: { tasks: true, spareParts: true } },
        },
        orderBy,
        skip,
        take: limit,
      }),
      prisma.serviceRequest.count({ where }),
    ]);

    return { serviceRequests, pagination: { page, limit, total } };
  }

  /**
   * Get single service request by ID with all related data
   */
  async getById(id) {
    const serviceRequest = await prisma.serviceRequest.findFirst({
      where: { id, deletedAt: null },
      include: {
        branch: true,
        requester: { select: { id: true, firstName: true, lastName: true, email: true, phone: true } },
        approver: { select: { id: true, firstName: true, lastName: true, email: true } },
        vehicle: { select: { id: true, registrationNo: true, make: true, model: true, vehicleType: true } },
        machine: { select: { id: true, machineCode: true, name: true, category: true, location: true } },
        asset: { select: { id: true, assetCode: true, name: true, category: true } },
        tasks: {
          include: {
            technician: { select: { id: true, firstName: true, lastName: true, email: true } },
          },
          orderBy: { createdAt: 'desc' },
        },
        spareParts: {
          include: {
            product: { select: { id: true, sku: true, name: true, unit: true } },
          },
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!serviceRequest) throw new NotFoundError('Service request not found');
    return serviceRequest;
  }

  /**
   * Create a new service request
   */
  async create(data, user) {
    const ticketNo = generateReferenceNo('SR');
    const priority = data.priority || 'MEDIUM';

    // Calculate SLA deadline based on priority
    const slaHours = SLA_HOURS[priority] || SLA_HOURS.MEDIUM;
    const slaDeadline = new Date();
    slaDeadline.setHours(slaDeadline.getHours() + slaHours);

    // Validate related entities if provided
    if (data.vehicleId) {
      const vehicle = await prisma.vehicle.findFirst({ where: { id: data.vehicleId, deletedAt: null } });
      if (!vehicle) throw new NotFoundError('Vehicle not found');
    }
    if (data.machineId) {
      const machine = await prisma.machine.findFirst({ where: { id: data.machineId, deletedAt: null } });
      if (!machine) throw new NotFoundError('Machine not found');
    }
    if (data.assetId) {
      const asset = await prisma.asset.findFirst({ where: { id: data.assetId, deletedAt: null } });
      if (!asset) throw new NotFoundError('Asset not found');
    }

    const serviceRequest = await prisma.serviceRequest.create({
      data: {
        branchId: data.branchId,
        ticketNo,
        requesterId: user.id,
        category: data.category,
        priority,
        subject: data.subject,
        description: data.description,
        vehicleId: data.vehicleId || null,
        machineId: data.machineId || null,
        assetId: data.assetId || null,
        estimatedCost: data.estimatedCost || null,
        slaDeadline,
        status: 'PENDING',
      },
      include: {
        branch: { select: { id: true, name: true, code: true } },
        requester: { select: { id: true, firstName: true, lastName: true, email: true } },
      },
    });

    return serviceRequest;
  }

  /**
   * Update a service request
   */
  async update(id, data) {
    const serviceRequest = await prisma.serviceRequest.findFirst({
      where: { id, deletedAt: null },
    });
    if (!serviceRequest) throw new NotFoundError('Service request not found');

    if (['COMPLETED', 'CLOSED', 'CANCELLED'].includes(serviceRequest.status)) {
      throw new BadRequestError('Cannot update a completed, closed, or cancelled service request');
    }

    // Recalculate SLA if priority changed
    const updateData = {};
    if (data.priority && data.priority !== serviceRequest.priority) {
      const slaHours = SLA_HOURS[data.priority] || SLA_HOURS.MEDIUM;
      const slaDeadline = new Date(serviceRequest.createdAt);
      slaDeadline.setHours(slaDeadline.getHours() + slaHours);
      updateData.slaDeadline = slaDeadline;
    }

    return prisma.serviceRequest.update({
      where: { id },
      data: {
        ...(data.category && { category: data.category }),
        ...(data.priority && { priority: data.priority }),
        ...(data.subject && { subject: data.subject }),
        ...(data.description && { description: data.description }),
        ...(data.vehicleId !== undefined && { vehicleId: data.vehicleId || null }),
        ...(data.machineId !== undefined && { machineId: data.machineId || null }),
        ...(data.assetId !== undefined && { assetId: data.assetId || null }),
        ...(data.estimatedCost !== undefined && { estimatedCost: data.estimatedCost }),
        ...(data.status && { status: data.status }),
        ...updateData,
      },
      include: {
        branch: { select: { id: true, name: true, code: true } },
        requester: { select: { id: true, firstName: true, lastName: true, email: true } },
      },
    });
  }

  /**
   * Approve a service request
   */
  async approve(id, approverId) {
    const serviceRequest = await prisma.serviceRequest.findFirst({
      where: { id, deletedAt: null },
    });
    if (!serviceRequest) throw new NotFoundError('Service request not found');

    if (serviceRequest.status !== 'PENDING') {
      throw new BadRequestError('Only pending service requests can be approved');
    }

    return prisma.serviceRequest.update({
      where: { id },
      data: {
        status: 'APPROVED',
        approverId,
        approvedAt: new Date(),
      },
      include: {
        branch: { select: { id: true, name: true, code: true } },
        requester: { select: { id: true, firstName: true, lastName: true, email: true } },
        approver: { select: { id: true, firstName: true, lastName: true, email: true } },
      },
    });
  }

  /**
   * Reject a service request
   */
  async reject(id, approverId, rejectedReason) {
    const serviceRequest = await prisma.serviceRequest.findFirst({
      where: { id, deletedAt: null },
    });
    if (!serviceRequest) throw new NotFoundError('Service request not found');

    if (serviceRequest.status !== 'PENDING') {
      throw new BadRequestError('Only pending service requests can be rejected');
    }

    return prisma.serviceRequest.update({
      where: { id },
      data: {
        status: 'REJECTED',
        approverId,
        rejectedReason,
      },
      include: {
        branch: { select: { id: true, name: true, code: true } },
        requester: { select: { id: true, firstName: true, lastName: true, email: true } },
        approver: { select: { id: true, firstName: true, lastName: true, email: true } },
      },
    });
  }

  // ==========================================================================
  // TASK MANAGEMENT
  // ==========================================================================

  /**
   * Assign a task to a technician
   */
  async assignTask(serviceRequestId, data) {
    const serviceRequest = await prisma.serviceRequest.findFirst({
      where: { id: serviceRequestId, deletedAt: null },
    });
    if (!serviceRequest) throw new NotFoundError('Service request not found');

    if (!['APPROVED', 'IN_PROGRESS'].includes(serviceRequest.status)) {
      throw new BadRequestError('Tasks can only be assigned to approved or in-progress service requests');
    }

    // Validate technician exists
    const technician = await prisma.user.findFirst({
      where: { id: data.technicianId, isActive: true, deletedAt: null },
    });
    if (!technician) throw new NotFoundError('Technician not found');

    // Create the task and set request to IN_PROGRESS if currently APPROVED
    const [task] = await prisma.$transaction([
      prisma.serviceTask.create({
        data: {
          serviceRequestId,
          technicianId: data.technicianId,
          taskDescription: data.taskDescription,
          laborCost: data.laborCost || null,
          notes: data.notes || null,
          status: 'ASSIGNED',
        },
        include: {
          technician: { select: { id: true, firstName: true, lastName: true, email: true } },
          serviceRequest: { select: { id: true, ticketNo: true } },
        },
      }),
      ...(serviceRequest.status === 'APPROVED'
        ? [prisma.serviceRequest.update({ where: { id: serviceRequestId }, data: { status: 'IN_PROGRESS' } })]
        : []),
    ]);

    return task;
  }

  /**
   * Update task status
   */
  async updateTaskStatus(taskId, data) {
    const task = await prisma.serviceTask.findUnique({ where: { id: taskId } });
    if (!task) throw new NotFoundError('Task not found');

    if (task.status === 'COMPLETED' || task.status === 'CANCELLED') {
      throw new BadRequestError('Cannot update a completed or cancelled task');
    }

    const updateData = {};

    if (data.status) {
      updateData.status = data.status;

      if (data.status === 'IN_PROGRESS' && !task.startedAt) {
        updateData.startedAt = new Date();
      }
      if (data.status === 'COMPLETED') {
        updateData.completedAt = new Date();
      }
    }
    if (data.timeSpentMinutes !== undefined) {
      updateData.timeSpentMinutes = data.timeSpentMinutes;
    }
    if (data.laborCost !== undefined) {
      updateData.laborCost = data.laborCost;
    }
    if (data.notes !== undefined) {
      updateData.notes = data.notes;
    }

    const updatedTask = await prisma.serviceTask.update({
      where: { id: taskId },
      data: updateData,
      include: {
        technician: { select: { id: true, firstName: true, lastName: true, email: true } },
        serviceRequest: { select: { id: true, ticketNo: true, status: true } },
      },
    });

    // If all tasks on the request are completed, auto-complete the request
    if (data.status === 'COMPLETED') {
      const pendingTasks = await prisma.serviceTask.count({
        where: {
          serviceRequestId: task.serviceRequestId,
          status: { notIn: ['COMPLETED', 'CANCELLED'] },
        },
      });

      if (pendingTasks === 0) {
        await this.calculateCost(task.serviceRequestId);
        await prisma.serviceRequest.update({
          where: { id: task.serviceRequestId },
          data: { status: 'COMPLETED', completedAt: new Date() },
        });
      }
    }

    return updatedTask;
  }

  // ==========================================================================
  // SPARE PARTS
  // ==========================================================================

  /**
   * Add spare part to a service request and update product stock
   */
  async addSparePart(serviceRequestId, data) {
    const serviceRequest = await prisma.serviceRequest.findFirst({
      where: { id: serviceRequestId, deletedAt: null },
    });
    if (!serviceRequest) throw new NotFoundError('Service request not found');

    if (['COMPLETED', 'CLOSED', 'CANCELLED'].includes(serviceRequest.status)) {
      throw new BadRequestError('Cannot add spare parts to a completed, closed, or cancelled request');
    }

    // Validate product exists and has sufficient stock
    const product = await prisma.product.findFirst({
      where: { id: data.productId, isActive: true, deletedAt: null },
    });
    if (!product) throw new NotFoundError('Product not found');

    const quantity = parseFloat(data.quantity);
    const unitCost = parseFloat(data.unitCost);
    const totalCost = quantity * unitCost;

    // Use interactive transaction with isolation to prevent race-condition stock over-decrement
    const sparePart = await prisma.$transaction(async (tx) => {
      // Re-read stock inside the transaction for consistency
      const freshProduct = await tx.product.findUnique({
        where: { id: data.productId },
        select: { currentStock: true, name: true },
      });

      if (parseFloat(freshProduct.currentStock) < quantity) {
        throw new BadRequestError(
          `Insufficient stock for ${freshProduct.name}. Available: ${freshProduct.currentStock}, Requested: ${quantity}`
        );
      }

      const created = await tx.serviceSparePart.create({
        data: {
          serviceRequestId,
          productId: data.productId,
          quantity,
          unitCost,
          totalCost,
        },
        include: {
          product: { select: { id: true, sku: true, name: true, unit: true } },
        },
      });

      await tx.product.update({
        where: { id: data.productId },
        data: { currentStock: { decrement: quantity } },
      });

      return created;
    });

    // Recalculate actual cost
    await this.calculateCost(serviceRequestId);

    return sparePart;
  }

  // ==========================================================================
  // COST MANAGEMENT
  // ==========================================================================

  /**
   * Calculate and update actual cost (labor + spare parts)
   */
  async calculateCost(serviceRequestId) {
    const [laborResult, partsResult] = await Promise.all([
      prisma.serviceTask.aggregate({
        where: { serviceRequestId },
        _sum: { laborCost: true },
      }),
      prisma.serviceSparePart.aggregate({
        where: { serviceRequestId },
        _sum: { totalCost: true },
      }),
    ]);

    const laborCost = parseFloat(laborResult._sum.laborCost || 0);
    const partsCost = parseFloat(partsResult._sum.totalCost || 0);
    const actualCost = laborCost + partsCost;

    await prisma.serviceRequest.update({
      where: { id: serviceRequestId },
      data: { actualCost },
    });

    return { laborCost, partsCost, actualCost };
  }

  // ==========================================================================
  // TICKET LIFECYCLE
  // ==========================================================================

  /**
   * Close a service ticket
   */
  async closeTicket(id, data) {
    const serviceRequest = await prisma.serviceRequest.findFirst({
      where: { id, deletedAt: null },
    });
    if (!serviceRequest) throw new NotFoundError('Service request not found');

    if (!['COMPLETED', 'CANCELLED'].includes(serviceRequest.status)) {
      throw new BadRequestError('Only completed or cancelled service requests can be closed');
    }

    return prisma.serviceRequest.update({
      where: { id },
      data: {
        status: 'CLOSED',
        closedAt: new Date(),
        closedReason: data.closedReason || null,
      },
      include: {
        branch: { select: { id: true, name: true, code: true } },
        requester: { select: { id: true, firstName: true, lastName: true, email: true } },
      },
    });
  }

  /**
   * Soft-delete a service request
   */
  async delete(id) {
    const serviceRequest = await prisma.serviceRequest.findFirst({
      where: { id, deletedAt: null },
    });
    if (!serviceRequest) throw new NotFoundError('Service request not found');

    return prisma.serviceRequest.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  // ==========================================================================
  // QUERIES
  // ==========================================================================

  /**
   * Get service requests created by a specific user
   */
  async getMyRequests(requesterId, query) {
    const { page, limit, skip } = parsePagination(query);
    const orderBy = parseSort(query, ['createdAt', 'ticketNo', 'priority', 'status', 'slaDeadline']);

    const where = {
      requesterId,
      deletedAt: null,
      ...(query.status && { status: query.status }),
      ...(query.priority && { priority: query.priority }),
    };

    const [serviceRequests, total] = await Promise.all([
      prisma.serviceRequest.findMany({
        where,
        include: {
          branch: { select: { id: true, name: true, code: true } },
          vehicle: { select: { id: true, registrationNo: true } },
          machine: { select: { id: true, machineCode: true, name: true } },
          asset: { select: { id: true, assetCode: true, name: true } },
          _count: { select: { tasks: true, spareParts: true } },
        },
        orderBy,
        skip,
        take: limit,
      }),
      prisma.serviceRequest.count({ where }),
    ]);

    return { serviceRequests, pagination: { page, limit, total } };
  }

  /**
   * Get tasks assigned to a specific technician
   */
  async getAssignedTasks(technicianId, query) {
    const { page, limit, skip } = parsePagination(query);
    const orderBy = parseSort(query, ['createdAt', 'status']);

    const where = {
      technicianId,
      ...(query.status && { status: query.status }),
    };

    const [tasks, total] = await Promise.all([
      prisma.serviceTask.findMany({
        where,
        include: {
          serviceRequest: {
            select: {
              id: true,
              ticketNo: true,
              subject: true,
              priority: true,
              status: true,
              category: true,
              slaDeadline: true,
              branch: { select: { id: true, name: true, code: true } },
            },
          },
        },
        orderBy,
        skip,
        take: limit,
      }),
      prisma.serviceTask.count({ where }),
    ]);

    return { tasks, pagination: { page, limit, total } };
  }

  /**
   * Get SLA breaches - requests past deadline that are not completed/closed
   */
  async getSLABreaches(query, user) {
    const { page, limit, skip } = parsePagination(query);

    const where = {
      deletedAt: null,
      slaDeadline: { lt: new Date() },
      status: { notIn: ['COMPLETED', 'CLOSED', 'CANCELLED'] },
    };

    // Branch-level filtering for non-admin users
    if (user.roleName !== 'super_admin' && user.roleName !== 'company_admin') {
      where.branchId = user.branchId;
    }
    if (query.branchId) {
      where.branchId = parseInt(query.branchId, 10);
    }

    const [serviceRequests, total] = await Promise.all([
      prisma.serviceRequest.findMany({
        where,
        include: {
          branch: { select: { id: true, name: true, code: true } },
          requester: { select: { id: true, firstName: true, lastName: true, email: true } },
          vehicle: { select: { id: true, registrationNo: true } },
          machine: { select: { id: true, machineCode: true, name: true } },
          asset: { select: { id: true, assetCode: true, name: true } },
        },
        orderBy: { slaDeadline: 'asc' },
        skip,
        take: limit,
      }),
      prisma.serviceRequest.count({ where }),
    ]);

    return { serviceRequests, pagination: { page, limit, total } };
  }
}

module.exports = new ServiceService();
