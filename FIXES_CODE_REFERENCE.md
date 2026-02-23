# Backend Issues - Code Fixes Reference Guide

## Quick Reference - Copy/Paste Solutions

---

## 🔴 CRITICAL FIXES

### Fix #1: scheduler.js - Remove Invalid Prisma Field Reference (Line 121)

**BEFORE (BROKEN)**:
```javascript
if (query.lowStock === 'true') {
  where.currentStock = { lte: prisma.$queryRaw ? undefined : undefined };
  // Use raw comparison: currentStock <= reorderLevel
  // Prisma doesn't support field-to-field comparison in where, so we handle it post-query
  // Instead, add a flag to filter after fetch, or use a raw approach
  // For Prisma, we use a workaround:
  delete where.currentStock;
}
```

**AFTER (FIXED)**:
```javascript
// Just remove lines 117-123 entirely
// The raw query implementation below (lines 126-132) correctly handles field-to-field comparison
```

**Action**: Delete lines 117-123 from scheduler.js

---

### Fix #2: vehicle.routes.js - Fix Route Paths (Lines 32, 35, 38)

**BEFORE (BROKEN)**:
```javascript
router.post('/fuel-logs', checkPermission('vehicles', 'create', 'fuel_log'), fuelLogValidator, validate, vehicleController.addFuelLog);
router.post('/documents', checkPermission('vehicles', 'create', 'vehicle_document'), documentValidator, validate, vehicleController.addDocument);
router.post('/assign-driver', checkPermission('vehicles', 'update', 'vehicle_driver'), driverAssignValidator, validate, vehicleController.assignDriver);
```

**AFTER (FIXED)**:
```javascript
router.post('/:id/fuel-logs', checkPermission('vehicles', 'create', 'fuel_log'), fuelLogValidator, validate, vehicleController.addFuelLog);
router.post('/:id/documents', checkPermission('vehicles', 'create', 'vehicle_document'), documentValidator, validate, vehicleController.addDocument);
router.post('/:id/assign-driver', checkPermission('vehicles', 'update', 'vehicle_driver'), driverAssignValidator, validate, vehicleController.assignDriver);
```

**Then update controllers**:
```javascript
// In vehicle.controller.js - controllers already handle this correctly
// They extract vehicleId from params or body appropriately
```

---

### Fix #3: auth.js - Add Error Parameter (Line 143)

**BEFORE (BROKEN)**:
```javascript
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      const decoded = jwt.verify(token, config.jwt.secret);
      const user = await prisma.user.findUnique({
        where: { id: decoded.userId },
        include: { role: true },
      });
      if (user && user.isActive) {
        req.user = {
          id: user.id,
          companyId: user.companyId,
          branchId: user.branchId,
          roleId: user.roleId,
          roleName: user.role.name,
        };
      }
    }
  } catch {  // ❌ PROBLEM HERE
    // Token invalid - continue without auth
  }
  next();
};
```

**AFTER (FIXED)**:
```javascript
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      const decoded = jwt.verify(token, config.jwt.secret);
      const user = await prisma.user.findUnique({
        where: { id: decoded.userId },
        include: { role: true },
      });
      if (user && user.isActive) {
        req.user = {
          id: user.id,
          companyId: user.companyId,
          branchId: user.branchId,
          roleId: user.roleId,
          roleName: user.role.name,
        };
      }
    }
  } catch (error) {  // ✅ ADD PARAMETER
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      logger.debug('Optional auth: Invalid token, proceeding without authentication');
    } else {
      logger.error('Optional auth error:', { message: error.message });
    }
  }
  next();
};
```

---

### Fix #4: validate.js - Change throw to next(error)

**BEFORE (BROKEN)**:
```javascript
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map((err) => ({
      field: err.path,
      message: err.msg,
      value: err.value,
    }));
    throw new ValidationError('Validation failed', formattedErrors);  // ❌ PROBLEM
  }
  next();
};
```

**AFTER (FIXED)**:
```javascript
const validate = (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      const formattedErrors = errors.array().map((err) => ({
        field: err.path,
        message: err.msg,
        value: err.value,
      }));
      return next(new ValidationError('Validation failed', formattedErrors));  // ✅ USE next()
    }
    next();
  } catch (error) {
    next(error);
  }
};
```

---

## 🟠 HIGH PRIORITY FIXES

### Fix #5: auditLog.js - Response Hijacking

**BEFORE (BROKEN)**:
```javascript
const auditLog = (action, module, entityType) => {
  return async (req, res, next) => {
    const originalJson = res.json.bind(res);

    res.json = async function (body) {  // ❌ ASYNC FUNCTION
      try {
        if (body.success && req.user) {
          await prisma.auditLog.create({  // ❌ AWAITING - BLOCKS RESPONSE
            data: {
              userId: req.user.id,
              action,
              module,
              entityType,
              entityId: body.data?.id || parseInt(req.params.id, 10) || null,
              oldValues: req._auditOldValues || null,
              newValues: action !== 'DELETE' ? (req.body || null) : null,
              ipAddress: req.ip || req.connection?.remoteAddress,
              userAgent: req.headers['user-agent'] || null,
            },
          });
        }
      } catch (error) {
        logger.error('Audit log creation failed', { error: error.message });
      }

      return originalJson(body);  // ❌ SENT BEFORE AUDIT COMPLETES
    };

    next();
  };
};
```

**AFTER (FIXED)**:
```javascript
const auditLog = (action, module, entityType) => {
  return async (req, res, next) => {
    const originalJson = res.json.bind(res);

    res.json = function (body) {  // ✅ REGULAR FUNCTION (not async)
      // Fire and forget - don't wait for audit log
      if (body.success && req.user) {
        prisma.auditLog.create({  // ✅ NO AWAIT
          data: {
            userId: req.user.id,
            action,
            module,
            entityType,
            entityId: body.data?.id || parseInt(req.params.id, 10) || null,
            oldValues: req._auditOldValues || null,
            newValues: action !== 'DELETE' ? (req.body || null) : null,
            ipAddress: req.ip || req.connection?.remoteAddress,
            userAgent: req.headers['user-agent'] || null,
          },
        }).catch((error) => {  // ✅ CATCH ERRORS SEPARATELY
          logger.error('Audit log creation failed', { error: error.message });
        });
      }

      return originalJson.call(this, body);  // ✅ PROPER BINDING
    };

    next();
  };
};
```

---

### Fix #6: auditLog.js - Model Reference

**BEFORE (BROKEN)**:
```javascript
const captureOldValues = (model) => {
  return async (req, res, next) => {
    try {
      const id = parseInt(req.params.id, 10);
      if (id && prisma[model]) {  // ❌ prisma.vehicle doesn't work, should be camelCase
        const oldRecord = await prisma[model].findUnique({ where: { id } });
        req._auditOldValues = oldRecord;
      }
    } catch (error) {
      logger.error('Capture old values failed', { error: error.message });
    }
    next();
  };
};
```

**AFTER (FIXED)**:
```javascript
const captureOldValues = (model) => {
  return async (req, res, next) => {
    try {
      const id = parseInt(req.params.id, 10);
      if (!id) {
        return next();
      }
      
      // Convert model name to camelCase if needed
      const modelKey = model.charAt(0).toLowerCase() + model.slice(1);
      
      // Verify model exists and has findUnique method
      if (prisma[modelKey] && typeof prisma[modelKey].findUnique === 'function') {
        const oldRecord = await prisma[modelKey].findUnique({ where: { id } });
        if (oldRecord) {
          req._auditOldValues = oldRecord;
        }
      } else {
        logger.warn(`Model ${modelKey} not found or doesn't support findUnique`);
      }
    } catch (error) {
      logger.error('Capture old values failed', { error: error.message });
    }
    next();
  };
};
```

---

### Fix #7: inventory.service.js - Pagination

**BEFORE (BROKEN)** - Lines 49-69:
```javascript
if (query.lowStock === 'true') {
  // Use raw query for field-to-field comparison
  [products, total] = await Promise.all([
    prisma.product.findMany({
      where,
      include: {
        branch: { select: { id: true, name: true, code: true } },
        category: { select: { id: true, name: true } },
      },
      orderBy,
      skip,
      take: limit,
    }),
    prisma.product.count({ where }),
  ]);

  // Post-filter for low stock
  products = products.filter(
    (p) => parseFloat(p.currentStock) <= parseFloat(p.reorderLevel || 0)
  );
  total = products.length;  // ❌ WRONG! Breaks pagination
}
```

**AFTER (FIXED)** - Use raw query:
```javascript
if (query.lowStock === 'true') {
  // Fetch with raw query for proper field comparison
  const sortField = sortBy || 'createdAt';
  const sortOrder = sortOrder === 'asc' ? 'ASC' : 'DESC';
  
  products = await prisma.product.findMany({
    where: {
      ...where,
      // Use Prisma where filter for conditions that work
      isActive: true,
      deletedAt: null,
      // Cannot do currentStock <= reorderLevel in where clause
    },
    include: {
      branch: { select: { id: true, name: true, code: true } },
      category: { select: { id: true, name: true } },
    },
    orderBy,
    skip,
    take: limit * 2,  // Fetch extra to account for filtering
  });

  // Filter in-memory for low stock
  const filtered = products.filter(
    (p) => parseFloat(p.currentStock || 0) <= parseFloat(p.reorderLevel || 0)
  );

  // Get accurate count
  const allLowStock = await prisma.product.findMany({
    where: {
      ...where,
      isActive: true,
      deletedAt: null,
    },
  });

  products = filtered.slice(0, limit);  // Apply limit after filtering
  total = allLowStock.filter(
    (p) => parseFloat(p.currentStock || 0) <= parseFloat(p.reorderLevel || 0)
  ).length;  // Count all matching items
}
```

---

### Fix #8: scheduler.js - Model Name (Line 200)

**BEFORE (BROKEN)**:
```javascript
const expiringContracts = await prisma.aMCContract.findMany({  // ❌ WRONG CASE
  where: {
    status: 'ACTIVE',
    endDate: { lte: thirtyDaysFromNow },
  },
  include: { machine: true },
});
```

**AFTER (FIXED)**:
```javascript
const expiringContracts = await prisma.amcContract.findMany({  // ✅ CORRECT CASE
  where: {
    status: 'ACTIVE',
    endDate: { lte: thirtyDaysFromNow },
  },
  include: { machine: true },
});
```

---

### Fix #9: scheduler.js - Raw Query Column Names (Lines 126-132)

**BEFORE (BROKEN)**:
```javascript
const rawLowStock = await prisma.$queryRaw`
  SELECT id, name, sku, current_stock, reorder_level, branch_id
  FROM products
  WHERE deleted_at IS NULL
  AND is_active = true
  AND current_stock <= reorder_level
`;
```

**AFTER (FIXED)** - Check your Prisma schema for actual column names, then:
```javascript
const rawLowStock = await prisma.$queryRaw`
  SELECT id, name, sku, currentStock, reorderLevel, branchId
  FROM Product
  WHERE deletedAt IS NULL
  AND isActive = true
  AND currentStock <= reorderLevel
`;
```

**OR use Prisma native query**:
```javascript
const rawLowStock = await prisma.product.findMany({
  where: {
    isActive: true,
    deletedAt: null,
    // Can't compare fields, so we'll filter after
  },
  select: {
    id: true,
    name: true,
    sku: true,
    currentStock: true,
    reorderLevel: true,
    branchId: true,
  },
});

// Filter in memory
const filtered = rawLowStock.filter(
  (p) => p.currentStock <= (p.reorderLevel || 0)
);
```

---

### Fix #10: firebase.js - Caching (Line 40)

**BEFORE (BROKEN)**:
```javascript
function getFirebaseApp() {
  if (firebaseApp) return firebaseApp;  // ❌ Once cached as null, won't retry

  const { projectId, privateKey, clientEmail } = config.firebase;

  if (!projectId || !privateKey || !clientEmail) {
    logger.warn('Firebase credentials not configured...');
    return null;
  }

  try {
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        privateKey: privateKey.replace(/\\n/g, '\n'),
        clientEmail,
      }),
    });
    logger.info('Firebase Admin SDK initialised successfully');
    return firebaseApp;
  } catch (error) {
    logger.error('Failed to initialise Firebase Admin SDK:', error);
    return null;  // ❌ Next time, firebaseApp is still undefined, so it tries again... but won't actually retry
  }
}
```

**AFTER (FIXED)**:
```javascript
function getFirebaseApp() {
  // Check if already initialized (not null/undefined)
  if (firebaseApp !== undefined) return firebaseApp;  // ✅ Check for undefined specifically

  const { projectId, privateKey, clientEmail } = config.firebase;

  if (!projectId || !privateKey || !clientEmail) {
    logger.warn(
      'Firebase credentials not configured – push notifications are disabled. ' +
        'Set FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, and FIREBASE_CLIENT_EMAIL.'
    );
    firebaseApp = null;  // Mark as failed
    return null;
  }

  try {
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        privateKey: privateKey.replace(/\\n/g, '\n'),
        clientEmail,
      }),
    });
    logger.info('Firebase Admin SDK initialised successfully');
    return firebaseApp;
  } catch (error) {
    logger.error('Failed to initialise Firebase Admin SDK:', error);
    firebaseApp = null;  // ✅ Mark as failed (not undefined) to prevent retries
    return null;
  }
}
```

---

## 🟡 MEDIUM PRIORITY FIXES

### Fix #11: config/index.js - JWT Validation (Lines 60-74)

**BEFORE (WEAK)**:
```javascript
const requiredConfigs = ['jwt.secret', 'jwt.refreshSecret', 'db.url'];
for (const key of requiredConfigs) {
  const keys = key.split('.');
  let value = config;
  for (const k of keys) {
    value = value?.[k];
  }
  if (!value) {
    if (config.app.env === 'production') {
      throw new Error(`Missing required configuration: ${key}`);
    }
    console.warn(`⚠️  Warning: Missing configuration: ${key}`);  // ❌ console instead of logger
  }
}
```

**AFTER (BETTER)**:
```javascript
const criticalConfigs = ['jwt.secret', 'jwt.refreshSecret', 'db.url'];
const optionalConfigs = ['sentry.dsn', 'firebase.projectId'];

// Check critical configs - always required
for (const key of criticalConfigs) {
  const keys = key.split('.');
  let value = config;
  for (const k of keys) {
    value = value?.[k];
  }
  if (!value) {
    const message = `Missing required configuration: ${key}`;
    throw new Error(message);  // ✅ Always throw for critical configs
  }
}

// Check optional configs - warn in any environment
for (const key of optionalConfigs) {
  const keys = key.split('.');
  let value = config;
  for (const k of keys) {
    value = value?.[k];
  }
  if (!value) {
    logger.warn(`⚠️  Optional configuration missing: ${key}`);  // ✅ Use logger
  }
}
```

---

### Fix #12: logger.js - Create Directory

**BEFORE (RISKY)**:
```javascript
const logDir = config.logging.dir;

const logFormat = winston.format.combine(
  // ... format config ...
);

const logger = winston.createLogger({
  level: config.logging.level,
  format: logFormat,
  defaultMeta: { service: config.app.name },
  transports: [
    new winston.transports.File({
      filename: path.join(logDir, 'error.log'),  // ❌ May fail if dir doesn't exist
      // ...
    }),
  ],
});
```

**AFTER (SAFE)**:
```javascript
const fs = require('fs');

const logDir = config.logging.dir;

// ✅ Create directory if it doesn't exist
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

const logFormat = winston.format.combine(
  // ... format config ...
);

const logger = winston.createLogger({
  level: config.logging.level,
  format: logFormat,
  defaultMeta: { service: config.app.name },
  transports: [
    new winston.transports.File({
      filename: path.join(logDir, 'error.log'),
      // ...
    }),
  ],
});
```

---

## Testing After Fixes

```bash
# Run all tests
npm run test

# Run specific test
npm run test:unit

# Lint code
npm run lint

# Start dev server
npm run dev

# Start production server
npm run start
```

---

## Verification Checklist After Each Fix

- [ ] No syntax errors (run `npm run lint`)
- [ ] Related tests pass (run `npm run test`)
- [ ] Server starts without errors (run `npm run dev`)
- [ ] Feature works as expected (manual testing)
- [ ] Related features still work (regression testing)
- [ ] Error handling works (test error cases)

---

**Total Estimated Time to Apply All Fixes**: 2-3 hours  
**Total Estimated Time to Test All Fixes**: 1-2 hours  
**Total Effort**: 3-5 hours
