// ============================================================================
// Nelna Maintenance System - Role Service Unit Tests
// ============================================================================

// ── Mock Prisma ─────────────────────────────────────────────────────────────
const mockPrisma = {
  role: {
    findMany: jest.fn(),
  },
};

jest.mock('../../../src/config/database', () => mockPrisma);

const RoleService = require('../../../src/services/role.service');

// ── Helpers ─────────────────────────────────────────────────────────────────
const allRoles = [
  { id: 1, name: 'super_admin', displayName: 'Super Admin', description: 'Full access', isSystem: true },
  { id: 2, name: 'company_admin', displayName: 'Company Admin', description: 'Company admin', isSystem: true },
  { id: 3, name: 'maintenance_manager', displayName: 'Maintenance Manager', description: 'Maintenance', isSystem: true },
  { id: 4, name: 'technician', displayName: 'Technician', description: 'Tech', isSystem: true },
  { id: 5, name: 'store_manager', displayName: 'Store Manager', description: 'Store', isSystem: true },
  { id: 6, name: 'driver', displayName: 'Driver', description: 'Driver', isSystem: true },
  { id: 7, name: 'finance_officer', displayName: 'Finance Officer', description: 'Finance', isSystem: true },
];

const selfRegisterRoles = allRoles.filter((r) => [4, 6].includes(r.id));

beforeEach(() => {
  jest.clearAllMocks();
});

// ═════════════════════════════════════════════════════════════════════════════
describe('RoleService.getRoles', () => {
  it('should return only self-register roles for unauthenticated caller', async () => {
    mockPrisma.role.findMany.mockResolvedValue(selfRegisterRoles);

    const result = await RoleService.getRoles(null);

    expect(result).toHaveLength(2);
    expect(result.map((r) => r.name)).toEqual(['technician', 'driver']);
    // Verify the where clause filtered by ID
    const whereArg = mockPrisma.role.findMany.mock.calls[0][0].where;
    expect(whereArg.id.in).toEqual([4, 6]);
  });

  it('should return only self-register roles for non-admin caller', async () => {
    mockPrisma.role.findMany.mockResolvedValue(selfRegisterRoles);

    const techCaller = { roleName: 'technician' };
    const result = await RoleService.getRoles(techCaller);

    expect(result).toHaveLength(2);
  });

  it('should return all roles for super_admin caller', async () => {
    mockPrisma.role.findMany.mockResolvedValue(allRoles);

    const result = await RoleService.getRoles({ roleName: 'super_admin' });

    expect(result).toHaveLength(7);
    // Verify no ID filter applied
    const whereArg = mockPrisma.role.findMany.mock.calls[0][0].where;
    expect(whereArg).toEqual({});
  });

  it('should return all roles for company_admin caller', async () => {
    mockPrisma.role.findMany.mockResolvedValue(allRoles);

    const result = await RoleService.getRoles({ roleName: 'company_admin' });

    expect(result).toHaveLength(7);
  });
});
