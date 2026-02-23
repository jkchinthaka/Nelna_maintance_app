// ============================================================================
// Nelna Maintenance System - Upload Routes
// ============================================================================
const express = require('express');
const path = require('path');
const fs = require('fs');
const { authenticate } = require('../middleware/auth');
const { uploadSingle, uploadMultiple, withCategory, CATEGORIES } = require('../middleware/upload');
const { success } = require('../utils/apiResponse');
const { BadRequestError, NotFoundError } = require('../utils/errors');
const asyncHandler = require('../utils/asyncHandler');
const config = require('../config');

const router = express.Router();

// All upload routes require authentication
router.use(authenticate);

// ── POST /uploads/:category ── Single file upload ─────────────────────────
router.post(
  '/:category',
  (req, res, next) => {
    const { category } = req.params;
    if (!CATEGORIES.includes(category)) {
      return next(new BadRequestError(`Invalid upload category '${category}'. Allowed: ${CATEGORIES.join(', ')}`));
    }
    next();
  },
  (req, _res, next) => {
    req.uploadCategory = req.params.category;
    next();
  },
  uploadSingle,
  asyncHandler(async (req, res) => {
    if (!req.file) {
      throw new BadRequestError('No file uploaded');
    }

    const fileUrl = `/uploads/${req.params.category}/${req.file.filename}`;

    res.status(201).json(
      success({
        originalName: req.file.originalname,
        fileName: req.file.filename,
        mimeType: req.file.mimetype,
        size: req.file.size,
        url: fileUrl,
        category: req.params.category,
      }, 'File uploaded successfully', 201)
    );
  })
);

// ── POST /uploads/:category/multiple ── Multiple files upload ─────────────
router.post(
  '/:category/multiple',
  (req, res, next) => {
    const { category } = req.params;
    if (!CATEGORIES.includes(category)) {
      return next(new BadRequestError(`Invalid upload category '${category}'.`));
    }
    next();
  },
  (req, _res, next) => {
    req.uploadCategory = req.params.category;
    next();
  },
  uploadMultiple,
  asyncHandler(async (req, res) => {
    if (!req.files || req.files.length === 0) {
      throw new BadRequestError('No files uploaded');
    }

    const files = req.files.map((file) => ({
      originalName: file.originalname,
      fileName: file.filename,
      mimeType: file.mimetype,
      size: file.size,
      url: `/uploads/${req.params.category}/${file.filename}`,
      category: req.params.category,
    }));

    res.status(201).json(
      success(files, `${files.length} file(s) uploaded successfully`, 201)
    );
  })
);

// ── DELETE /uploads/:category/:fileName ── Remove a file ──────────────────
router.delete(
  '/:category/:fileName',
  asyncHandler(async (req, res) => {
    const { category, fileName } = req.params;
    if (!CATEGORIES.includes(category)) {
      throw new BadRequestError(`Invalid category '${category}'.`);
    }

    // Prevent path traversal
    const safeFileName = path.basename(fileName);
    const filePath = path.join(path.resolve(config.upload.path), category, safeFileName);

    if (!fs.existsSync(filePath)) {
      throw new NotFoundError('File not found');
    }

    fs.unlinkSync(filePath);

    res.json(success(null, 'File deleted successfully'));
  })
);

module.exports = router;
