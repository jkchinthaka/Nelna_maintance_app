// ============================================================================
// Nelna Maintenance System - Vehicle Service Unit Tests
// ============================================================================
const { NotFoundError, ConflictError } = require('../../../src/utils/errors');

// ── Mock Prisma ─────────────────────────────────────────────────────────────
const mockPrisma = {
  vehicle: {
    findMany: jest.fn(),
    findFirst: jest.fn(),
    findUnique: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    count: jest.fn(),
  },
  fuelLog: {
    create: jest.fn(),
    findMany: jest.fn(),
    count: jest.fn(),
    aggregate: jest.fn(),
  },
  vehicleDocument: { create: jest.fn() },
  vehicleDriver: { create: jest.fn(), updateMany: jest.fn() },
  vehicleServiceHistory: { aggregate: jest.fn() },
};

jest.mock('../../../src/config/database', () => mockPrisma);

// Import AFTER mocking
const VehicleService = require('../../../src/services/vehicle.service');

// ── Helpers ─────────────────────────────────────────────────────────────────

const sampleVehicle = {
  id: 1,
  branchId: 1,
  registrationNo: 'ABC-1234',
  make: 'Toyota',
  model: 'Hilux',
  year: 2022,
  fuelType: 'DIESEL',
  vehicleType: 'TRUCK',
  status: 'ACTIVE',
  mileage: 50000,
  deletedAt: null,
};

const adminUser = {
  roleName: 'super_admin',
  branchId: 1,
};

const normalUser = {
  roleName: 'technician',
  branchId: 2,
};

beforeEach(() => {
  jest.clearAllMocks();
});

// ═════════════════════════════════════════════════════════════════════════════
// getAll
// ═════════════════════════════════════════════════════════════════════════════
describe('VehicleService.getAll', () => {
  it('should return paginated vehicles for admin', async () => {
    mockPrisma.vehicle.findMany.mockResolvedValue([sampleVehicle]);
    mockPrisma.vehicle.count.mockResolvedValue(1);

    const result = await VehicleService.getAll({}, adminUser);

    expect(result.vehicles).toHaveLength(1);
    expect(result.pagination.total).toBe(1);
    expect(mockPrisma.vehicle.findMany).toHaveBeenCalledTimes(1);
  });

  it('should apply branchId filter for non-admin users', async () => {
    mockPrisma.vehicle.findMany.mockResolvedValue([]);
    mockPrisma.vehicle.count.mockResolvedValue(0);

    await VehicleService.getAll({}, normalUser);

    const call = mockPrisma.vehicle.findMany.mock.calls[0][0];
    expect(call.where.branchId).toBe(normalUser.branchId);
  });

  it('should apply status filter when provided', async () => {
    mockPrisma.vehicle.findMany.mockResolvedValue([]);
    mockPrisma.vehicle.count.mockResolvedValue(0);

    await VehicleService.getAll({ status: 'ACTIVE' }, adminUser);

    const call = mockPrisma.vehicle.findMany.mock.calls[0][0];
    expect(call.where.status).toBe('ACTIVE');
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// getById
// ═════════════════════════════════════════════════════════════════════════════
describe('VehicleService.getById', () => {
  it('should return vehicle when found', async () => {
    mockPrisma.vehicle.findFirst.mockResolvedValue(sampleVehicle);

    const result = await VehicleService.getById(1);

    expect(result).toEqual(sampleVehicle);
    expect(mockPrisma.vehicle.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 1, deletedAt: null } })
    );
  });

  it('should throw NotFoundError when vehicle does not exist', async () => {
    mockPrisma.vehicle.findFirst.mockResolvedValue(null);

    await expect(VehicleService.getById(999)).rejects.toThrow(NotFoundError);
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// create
// ═════════════════════════════════════════════════════════════════════════════
describe('VehicleService.create', () => {
  it('should create and return a new vehicle', async () => {
    mockPrisma.vehicle.findUnique.mockResolvedValue(null);
    mockPrisma.vehicle.create.mockResolvedValue({ ...sampleVehicle, id: 2 });

    const result = await VehicleService.create({
      branchId: 1,
      registrationNo: 'XYZ-9999',
      make: 'Toyota',
      model: 'Hilux',
      vehicleType: 'TRUCK',
    });

    expect(result.id).toBe(2);
    expect(mockPrisma.vehicle.create).toHaveBeenCalledTimes(1);
  });

  it('should throw ConflictError for duplicate registration number', async () => {
    mockPrisma.vehicle.findUnique.mockResolvedValue(sampleVehicle);

    await expect(
      VehicleService.create({ registrationNo: 'ABC-1234', make: 'Toyota', model: 'Hilux', vehicleType: 'TRUCK' })
    ).rejects.toThrow(ConflictError);
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// update
// ═════════════════════════════════════════════════════════════════════════════
describe('VehicleService.update', () => {
  it('should update an existing vehicle', async () => {
    mockPrisma.vehicle.findFirst.mockResolvedValue(sampleVehicle);
    mockPrisma.vehicle.update.mockResolvedValue({ ...sampleVehicle, make: 'Nissan' });

    const result = await VehicleService.update(1, { make: 'Nissan' });

    expect(result.make).toBe('Nissan');
    expect(mockPrisma.vehicle.update).toHaveBeenCalledTimes(1);
  });

  it('should throw NotFoundError for non-existent vehicle', async () => {
    mockPrisma.vehicle.findFirst.mockResolvedValue(null);

    await expect(VehicleService.update(999, { make: 'Nissan' })).rejects.toThrow(NotFoundError);
  });

  it('should throw ConflictError when changing to an existing registration number', async () => {
    mockPrisma.vehicle.findFirst.mockResolvedValue(sampleVehicle);
    mockPrisma.vehicle.findUnique.mockResolvedValue({ id: 3, registrationNo: 'DUP-0001' });

    await expect(
      VehicleService.update(1, { registrationNo: 'DUP-0001' })
    ).rejects.toThrow(ConflictError);
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// delete
// ═════════════════════════════════════════════════════════════════════════════
describe('VehicleService.delete', () => {
  it('should soft-delete an existing vehicle', async () => {
    mockPrisma.vehicle.findFirst.mockResolvedValue(sampleVehicle);
    mockPrisma.vehicle.update.mockResolvedValue({ ...sampleVehicle, deletedAt: new Date() });

    const result = await VehicleService.delete(1);

    expect(result).toBeDefined();
    expect(mockPrisma.vehicle.update).toHaveBeenCalledWith({
      where: { id: 1 },
      data: { deletedAt: expect.any(Date) },
    });
  });

  it('should throw NotFoundError for non-existent vehicle', async () => {
    mockPrisma.vehicle.findFirst.mockResolvedValue(null);

    await expect(VehicleService.delete(999)).rejects.toThrow(NotFoundError);
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// addFuelLog
// ═════════════════════════════════════════════════════════════════════════════
describe('VehicleService.addFuelLog', () => {
  it('should create a fuel log and update mileage when higher', async () => {
    mockPrisma.vehicle.findFirst.mockResolvedValue(sampleVehicle);
    mockPrisma.fuelLog.create.mockResolvedValue({ id: 1 });
    mockPrisma.vehicle.update.mockResolvedValue({});

    await VehicleService.addFuelLog({
      vehicleId: 1,
      date: '2024-01-01',
      fuelType: 'DIESEL',
      quantity: 50,
      unitPrice: 350,
      totalCost: 17500,
      mileage: 55000,
    });

    expect(mockPrisma.fuelLog.create).toHaveBeenCalledTimes(1);
    expect(mockPrisma.vehicle.update).toHaveBeenCalledTimes(1);
  });

  it('should not update mileage when lower', async () => {
    mockPrisma.vehicle.findFirst.mockResolvedValue(sampleVehicle);
    mockPrisma.fuelLog.create.mockResolvedValue({ id: 2 });

    await VehicleService.addFuelLog({
      vehicleId: 1,
      date: '2024-01-01',
      fuelType: 'DIESEL',
      quantity: 20,
      unitPrice: 350,
      totalCost: 7000,
      mileage: 40000,
    });

    expect(mockPrisma.vehicle.update).not.toHaveBeenCalled();
  });

  it('should throw NotFoundError for non-existent vehicle', async () => {
    mockPrisma.vehicle.findFirst.mockResolvedValue(null);

    await expect(
      VehicleService.addFuelLog({ vehicleId: 999, date: '2024-01-01', fuelType: 'DIESEL', quantity: 10, unitPrice: 350, totalCost: 3500, mileage: 1000 })
    ).rejects.toThrow(NotFoundError);
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// getFuelLogs
// ═════════════════════════════════════════════════════════════════════════════
describe('VehicleService.getFuelLogs', () => {
  it('should return paginated fuel logs', async () => {
    mockPrisma.fuelLog.findMany.mockResolvedValue([{ id: 1 }]);
    mockPrisma.fuelLog.count.mockResolvedValue(1);

    const result = await VehicleService.getFuelLogs(1, {});

    expect(result.logs).toHaveLength(1);
    expect(result.pagination.total).toBe(1);
  });

  it('should apply date range filter', async () => {
    mockPrisma.fuelLog.findMany.mockResolvedValue([]);
    mockPrisma.fuelLog.count.mockResolvedValue(0);

    await VehicleService.getFuelLogs(1, {
      startDate: '2024-01-01',
      endDate: '2024-06-30',
    });

    const call = mockPrisma.fuelLog.findMany.mock.calls[0][0];
    expect(call.where.date).toBeDefined();
    expect(call.where.date.gte).toBeInstanceOf(Date);
    expect(call.where.date.lte).toBeInstanceOf(Date);
  });
});
