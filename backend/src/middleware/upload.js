// ============================================================================
// Nelna Maintenance System - File Upload Middleware (Multer)
// ============================================================================
const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');
const config = require('../config');
const { BadRequestError } = require('../utils/errors');

// Ensure the upload directory exists (skip on serverless — read-only FS)
const isServerless = !!process.env.VERCEL;
const uploadDir = path.resolve(config.upload.path);

// Sub-folders for each upload category
const CATEGORIES = ['vehicles', 'machines', 'assets', 'avatars', 'general'];

if (!isServerless) {
  if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
  }
  for (const cat of CATEGORIES) {
    const dir = path.join(uploadDir, cat);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  }
}

// ── Storage ─────────────────────────────────────────────────────────────────
const storage = multer.diskStorage({
  destination: (req, _file, cb) => {
    // Callers should set req.uploadCategory to one of CATEGORIES
    const category = CATEGORIES.includes(req.uploadCategory)
      ? req.uploadCategory
      : 'general';
    cb(null, path.join(uploadDir, category));
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `${uuidv4()}${ext}`);
  },
});

// ── File filter ─────────────────────────────────────────────────────────────
const ALLOWED_MIME_TYPES = [
  // Images
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
  // Documents
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
];

const fileFilter = (_req, file, cb) => {
  if (ALLOWED_MIME_TYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new BadRequestError(`File type '${file.mimetype}' is not allowed`), false);
  }
};

// ── Multer instances ────────────────────────────────────────────────────────

/** Single file upload (field name: `file`) */
const uploadSingle = multer({
  storage,
  fileFilter,
  limits: { fileSize: config.upload.maxSize },
}).single('file');

/** Multiple files upload (field name: `files`, max 10) */
const uploadMultiple = multer({
  storage,
  fileFilter,
  limits: { fileSize: config.upload.maxSize },
}).array('files', 10);

// ── Middleware wrappers ─────────────────────────────────────────────────────

/**
 * Creates a middleware that sets the upload category before multer runs.
 * @param {'vehicles'|'machines'|'assets'|'avatars'|'general'} category
 */
const withCategory = (category) => (req, _res, next) => {
  req.uploadCategory = category;
  next();
};

module.exports = {
  uploadSingle,
  uploadMultiple,
  withCategory,
  ALLOWED_MIME_TYPES,
  CATEGORIES,
};
