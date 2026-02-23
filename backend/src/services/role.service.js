// ============================================================================
// Nelna Maintenance System - Role Service (Business Logic)
// ============================================================================
const prisma = require('../config/database');
const { SELF_REGISTER_ROLES } = require('../utils/roleConstants');

class RoleService {
  /**
   * Get all roles. Unauthenticated callers only see self-register roles.
   * Admins see all roles.
   */
  async getRoles(caller) {
    const isAdmin = caller && ['super_admin', 'company_admin'].includes(caller.roleName);

    const roles = await prisma.role.findMany({
      where: isAdmin ? {} : { id: { in: SELF_REGISTER_ROLES } },
      select: {
        id: true,
        name: true,
        displayName: true,
        description: true,
        isSystem: true,
      },
      orderBy: { id: 'asc' },
    });

    return roles;
  }
}

module.exports = new RoleService();
