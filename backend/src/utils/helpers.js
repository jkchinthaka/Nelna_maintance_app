// ============================================================================
// Nelna Maintenance System - Utility Helpers
// ============================================================================
const { v4: uuidv4 } = require('uuid');
const crypto = require('crypto');

/**
 * Generate a unique ticket/reference number.
 * Uses crypto.randomBytes for better entropy to reduce collision risk.
 * @param {string} prefix - Prefix for the number (e.g., 'SR', 'PO', 'GRN')
 * @returns {string} Formatted reference number
 */
const generateReferenceNo = (prefix = 'REF') => {
  const date = new Date();
  const year = date.getFullYear().toString().slice(-2);
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const random = crypto.randomBytes(4).toString('hex').toUpperCase().slice(0, 6);
  return `${prefix}-${year}${month}-${random}`;
};

/**
 * Build pagination parameters from query
 */
const parsePagination = (query) => {
  const page = Math.max(1, parseInt(query.page, 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit, 10) || 20));
  const skip = (page - 1) * limit;
  return { page, limit, skip };
};

/**
 * Build sort parameters from query
 */
const parseSort = (query, allowedFields = ['createdAt']) => {
  const sortBy = allowedFields.includes(query.sortBy) ? query.sortBy : 'createdAt';
  const sortOrder = query.sortOrder === 'asc' ? 'asc' : 'desc';
  return { [sortBy]: sortOrder };
};

/**
 * Build search/filter where clause
 */
const buildSearchFilter = (query, searchFields = []) => {
  const where = {};

  if (query.search && searchFields.length > 0) {
    where.OR = searchFields.map((field) => ({
      [field]: { contains: query.search, mode: 'insensitive' },
    }));
  }

  return where;
};

/**
 * Calculate date difference in days
 */
const daysBetween = (date1, date2) => {
  const oneDay = 24 * 60 * 60 * 1000;
  return Math.round(Math.abs((date1 - date2) / oneDay));
};

/**
 * Check if a date is within N days from now
 */
const isWithinDays = (date, days) => {
  const now = new Date();
  const target = new Date(date);
  const diff = daysBetween(now, target);
  return diff <= days && target >= now;
};

/**
 * Generate unique ID
 */
const generateUUID = () => uuidv4();

/**
 * Sanitize object - remove undefined/null fields
 */
const sanitizeObject = (obj) => {
  return Object.fromEntries(
    Object.entries(obj).filter(([_, v]) => v !== undefined && v !== null && v !== '')
  );
};

/**
 * Format currency
 */
const formatCurrency = (amount, currency = 'LKR') => {
  return new Intl.NumberFormat('en-LK', {
    style: 'currency',
    currency,
  }).format(amount);
};

module.exports = {
  generateReferenceNo,
  parsePagination,
  parseSort,
  buildSearchFilter,
  daysBetween,
  isWithinDays,
  generateUUID,
  sanitizeObject,
  formatCurrency,
};
