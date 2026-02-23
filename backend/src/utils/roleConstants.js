// ============================================================================
// Nelna Maintenance System - Role Constants
// Stable IDs used across seed, registration, and authorization logic.
// ============================================================================

const ROLE_IDS = Object.freeze({
  SUPER_ADMIN: 1,
  COMPANY_ADMIN: 2,
  MAINTENANCE_MANAGER: 3,
  TECHNICIAN: 4,
  STORE_MANAGER: 5,
  DRIVER: 6,
  FINANCE_OFFICER: 7,
});

const ROLE_NAMES = Object.freeze({
  [ROLE_IDS.SUPER_ADMIN]: 'super_admin',
  [ROLE_IDS.COMPANY_ADMIN]: 'company_admin',
  [ROLE_IDS.MAINTENANCE_MANAGER]: 'maintenance_manager',
  [ROLE_IDS.TECHNICIAN]: 'technician',
  [ROLE_IDS.STORE_MANAGER]: 'store_manager',
  [ROLE_IDS.DRIVER]: 'driver',
  [ROLE_IDS.FINANCE_OFFICER]: 'finance_officer',
});

/** Roles that anyone can self-register as (no auth required) */
const SELF_REGISTER_ROLES = [ROLE_IDS.TECHNICIAN, ROLE_IDS.DRIVER];

/** Roles that can create users with any role */
const ADMIN_ROLES = [ROLE_IDS.SUPER_ADMIN, ROLE_IDS.COMPANY_ADMIN];

module.exports = { ROLE_IDS, ROLE_NAMES, SELF_REGISTER_ROLES, ADMIN_ROLES };
