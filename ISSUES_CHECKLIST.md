# Backend Issues Checklist

## 🔴 CRITICAL ISSUES (Fix Immediately)

### Issue #1: Scheduler - Invalid Prisma Field Reference
- **File**: `backend/src/utils/scheduler.js`
- **Line**: 121
- **Severity**: CRITICAL
- **Type**: Runtime Error

```javascript
// ❌ WRONG (Line 121)
where.currentStock = { lte: prisma.$queryRaw ? undefined : undefined };

// ✅ FIX
// Remove this line entirely - it doesn't work with Prisma
// The raw query below (lines 126-132) handles the field-to-field comparison correctly
```

**Checklist**:
- [ ] Remove lines 117-123 from scheduler.js
- [ ] Keep the raw query implementation (lines 126-132)
- [ ] Test scheduler executes without errors
- [ ] Verify low stock notifications are sent

---

### Issue #2: Route Parameter Order - Vehicle Routes
- **File**: `backend/src/routes/vehicle.routes.js`
- **Lines**: 24, 32, 35, 38
- **Severity**: CRITICAL
- **Type**: Route Conflict / REST Convention

```javascript
// ❌ WRONG
router.post('/fuel-logs', checkPermission(...), fuelLogValidator, validate, vehicleController.addFuelLog);
router.post('/documents', checkPermission(...), documentValidator, validate, vehicleController.addDocument);
router.post('/assign-driver', checkPermission(...), driverAssignValidator, validate, vehicleController.assignDriver);

// ✅ FIX
router.post('/:id/fuel-logs', checkPermission(...), fuelLogValidator, validate, vehicleController.addFuelLog);
router.post('/:id/documents', checkPermission(...), documentValidator, validate, vehicleController.addDocument);
router.post('/:id/assign-driver', checkPermission(...), driverAssignValidator, validate, vehicleController.assignDriver);
```

**Checklist**:
- [ ] Update route paths to include `/:id/`
- [ ] Update vehicle controller to use `req.params.id` instead of relying on body
- [ ] Test fuel log creation with new route
- [ ] Test document creation with new route
- [ ] Test driver assignment with new route
- [ ] Verify requests fail without vehicleId parameter

---

### Issue #3: Auth Middleware - Missing Error Handling in optionalAuth
- **File**: `backend/src/middleware/auth.js`
- **Line**: 143
- **Severity**: CRITICAL
- **Type**: Error Handling Issue

```javascript
// ❌ WRONG
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
        req.user = { /* ... */ };
      }
    }
  } catch {  // ❌ Empty catch - no parameter
    // Token invalid - continue without auth
  }
  next();
};

// ✅ FIX
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
  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      logger.debug('Optional auth: Invalid token, proceeding without authentication');
    } else {
      logger.error('Optional auth error:', { message: error.message });
    }
  }
  next();
};
```

**Checklist**:
- [ ] Add error parameter to catch block
- [ ] Log JWT errors at debug level
- [ ] Log other errors at error level
- [ ] Test with invalid token
- [ ] Test with valid token
- [ ] Test without token
- [ ] Verify database errors are logged

---

### Issue #4: Validate Middleware - Sync Error Throw
- **File**: `backend/src/middleware/validate.js`
- **Line**: 19
- **Severity**: CRITICAL
- **Type**: Error Handling Issue

```javascript
// ❌ WRONG
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map((err) => ({
      field: err.path,
      message: err.msg,
      value: err.value,
    }));
    throw new ValidationError('Validation failed', formattedErrors);  // ❌ Thrown synchronously
  }
  next();
};

// ✅ FIX
const validate = (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      const formattedErrors = errors.array().map((err) => ({
        field: err.path,
        message: err.msg,
        value: err.value,
      }));
      return next(new ValidationError('Validation failed', formattedErrors));
    }
    next();
  } catch (error) {
    next(error);
  }
};
```

**Checklist**:
- [ ] Wrap validation logic in try-catch
- [ ] Use `next(error)` instead of `throw`
- [ ] Return early after calling next(error)
- [ ] Test with invalid email format
- [ ] Test with missing required fields
- [ ] Test with valid data
- [ ] Verify error handler catches validation errors

---

## 🟠 HIGH PRIORITY ISSUES

### Issue #5: Audit Logger - Response Hijacking
- **File**: `backend/src/middleware/auditLog.js`
- **Lines**: 15-40
- **Severity**: HIGH
- **Type**: Middleware Chain Issue

```javascript
// ❌ ISSUE
res.json = async function (body) {
  try {
    if (body.success && req.user) {
      await prisma.auditLog.create({ /* async operation */ });
    }
  } catch (error) {
    logger.error('Audit log creation failed', { error: error.message });
  }
  return originalJson(body);  // ❌ Response sent before audit completes
};

// ✅ FIX
res.json = function (body) {
  // Don't await - fire and forget
  if (body.success && req.user) {
    prisma.auditLog.create({ /* ... */ }).catch((error) => {
      logger.error('Audit log creation failed', { error: error.message });
    });
  }
  return originalJson.call(this, body);
};
```

**Checklist**:
- [ ] Change async function to regular function
- [ ] Remove await from auditLog.create
- [ ] Use .catch() for error handling
- [ ] Fix originalJson.call binding
- [ ] Test create operation
- [ ] Test update operation
- [ ] Test delete operation
- [ ] Verify audit logs are created

---

### Issue #6: Audit Logger - Invalid Model Reference
- **File**: `backend/src/middleware/auditLog.js`
- **Line**: 54
- **Severity**: HIGH
- **Type**: Runtime Error / Logic Error

```javascript
// ❌ WRONG
const captureOldValues = (model) => {
  return async (req, res, next) => {
    try {
      const id = parseInt(req.params.id, 10);
      if (id && prisma[model]) {  // ❌ Model name case wrong
        const oldRecord = await prisma[model].findUnique({ where: { id } });
        req._auditOldValues = oldRecord;
      }
    } catch (error) {
      logger.error('Capture old values failed', { error: error.message });
    }
    next();
  };
};

// ✅ FIX
const captureOldValues = (model) => {
  return async (req, res, next) => {
    try {
      const id = parseInt(req.params.id, 10);
      if (!id) {
        return next();
      }
      
      // Convert 'vehicle' -> 'vehicle', but ensure camelCase
      const modelKey = model.charAt(0).toLowerCase() + model.slice(1);
      
      // Check if model exists and has findUnique method
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

**Checklist**:
- [ ] Fix model name case conversion
- [ ] Add proper type checking for prisma model
- [ ] Test with 'vehicle' model
- [ ] Test with 'machine' model
- [ ] Test with 'serviceRequest' model
- [ ] Verify old values are captured for audits
- [ ] Verify null check works

---

### Issue #7: Inventory Service - Low Stock Pagination
- **File**: `backend/src/services/inventory.service.js`
- **Lines**: 32-69
- **Severity**: HIGH
- **Type**: Logic Error - Pagination Break

```javascript
// ❌ WRONG - Pagination broken
if (query.lowStock === 'true') {
  [products, total] = await Promise.all([
    prisma.product.findMany({ where, /* ... */ }),
    prisma.product.count({ where }),
  ]);
  
  // Post-filter invalidates pagination
  products = products.filter(
    (p) => parseFloat(p.currentStock) <= parseFloat(p.reorderLevel || 0)
  );
  total = products.length;  // ❌ Wrong! Total doesn't match actual results
}

// ✅ FIX - Use raw query for proper pagination
if (query.lowStock === 'true') {
  const results = await prisma.$queryRaw`
    SELECT * FROM Product
    WHERE deleted_at IS NULL
    AND is_active = true
    AND current_stock <= reorder_level
    ${query.branchId ? Prisma.raw`AND branch_id = ${query.branchId}`) : Prisma.empty}
    ORDER BY ${Prisma.raw(sortBy)} ${Prisma.raw(sortOrder)}
    LIMIT ${limit} OFFSET ${skip}
  `;
  
  const [{ count: total }] = await prisma.$queryRaw`
    SELECT COUNT(*) as count FROM Product
    WHERE deleted_at IS NULL
    AND is_active = true
    AND current_stock <= reorder_level
    ${query.branchId ? Prisma.raw`AND branch_id = ${query.branchId}`) : Prisma.empty}
  `;
  
  products = results;
} else {
  // existing code
}
```

**Checklist**:
- [ ] Fix pagination logic for lowStock filter
- [ ] Use raw query instead of post-filtering
- [ ] Ensure total count matches results
- [ ] Test pagination with page=1, limit=10
- [ ] Test pagination with page=2, limit=10
- [ ] Verify next/prev page indicators work
- [ ] Test with no low stock items

---

### Issue #8: Service Routes - Route Parameter Conflict
- **File**: `backend/src/routes/service.routes.js`
- **Line**: 128-135
- **Severity**: HIGH
- **Type**: Route Conflict

```javascript
// ❌ WRONG - Will be matched by /:id handler
router.put('/tasks/:taskId', checkPermission(...), updateTaskValidator, validate, auditLog(...), serviceController.updateTask);

// ✅ FIX - Option 1: More specific pattern with service request ID
router.put('/:id/tasks/:taskId', checkPermission(...), updateTaskValidator, validate, auditLog(...), serviceController.updateTask);

// ✅ FIX - Option 2: Use sub-router
const taskRouter = Router();
taskRouter.put('/:taskId', checkPermission(...), updateTaskValidator, validate, auditLog(...), serviceController.updateTask);
router.use('/tasks', taskRouter);

// ✅ FIX - Option 3: Query routes before /:id
router.get('/my-requests', /* ... */);  // Already done (good!)
router.get('/my-tasks', /* ... */);     // Already done (good!)
router.put('/tasks/:taskId', /* ... */);  // Need to move here, before /:id
```

**Checklist**:
- [ ] Decide on routing pattern
- [ ] Update route definition
- [ ] Update controller to use correct parameter
- [ ] Test task update endpoint
- [ ] Test with valid task ID
- [ ] Test with invalid task ID
- [ ] Verify service request ID is not needed for tasks

---

### Issue #9: Firebase Configuration - Caching
- **File**: `backend/src/config/firebase.js`
- **Lines**: 14-42
- **Severity**: HIGH
- **Type**: Configuration / Error Handling

```javascript
// ❌ ISSUE - If init fails, it's cached as null forever
function getFirebaseApp() {
  if (firebaseApp) return firebaseApp;
  
  // ... initialization code ...
  
  try {
    firebaseApp = admin.initializeApp({ /* ... */ });
    return firebaseApp;
  } catch (error) {
    logger.error('Failed to initialise Firebase Admin SDK:', error);
    return null;  // ❌ Next time, firebaseApp is undefined (not falsy), so it won't retry
  }
}

// ✅ FIX - Clear cache on failure
function getFirebaseApp() {
  if (firebaseApp !== undefined) return firebaseApp;  // Check for undefined, not falsy
  
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
    firebaseApp = undefined;  // Clear cache to allow retry
    return null;
  }
}
```

**Checklist**:
- [ ] Change `if (firebaseApp)` to `if (firebaseApp !== undefined)`
- [ ] Set `firebaseApp = undefined` on error (not null)
- [ ] Test Firebase initialization failure recovery
- [ ] Test with valid credentials
- [ ] Test with invalid credentials
- [ ] Verify error is logged
- [ ] Test retry behavior

---

### Issue #10: Scheduler - Model Name Case
- **File**: `backend/src/utils/scheduler.js`
- **Line**: 200
- **Severity**: HIGH
- **Type**: Prisma Model Error

```javascript
// ❌ WRONG - Case sensitive, should be camelCase
const expiringContracts = await prisma.aMCContract.findMany({
  where: { status: 'ACTIVE', endDate: { lte: thirtyDaysFromNow } },
  include: { machine: true },
});

// ✅ FIX - Use correct camelCase
const expiringContracts = await prisma.amcContract.findMany({
  where: { status: 'ACTIVE', endDate: { lte: thirtyDaysFromNow } },
  include: { machine: true },
});
```

**Checklist**:
- [ ] Change `aMCContract` to `amcContract`
- [ ] Test scheduler runs without errors
- [ ] Verify contract expiry notifications are sent
- [ ] Search codebase for other `aMCContract` references
- [ ] Test with expiring contracts
- [ ] Test with non-expiring contracts

---

## 🟡 MEDIUM PRIORITY ISSUES

### Issue #11: Config - Missing JWT Secret Validation
- **File**: `backend/src/config/index.js`
- **Lines**: 60-74
- **Severity**: MEDIUM
- **Type**: Configuration/Security

```javascript
// ❌ ISSUE - Only required in production, optional in dev
const requiredConfigs = ['jwt.secret', 'jwt.refreshSecret', 'db.url'];
for (const key of requiredConfigs) {
  // ... check code ...
  if (!value) {
    if (config.app.env === 'production') {
      throw new Error(`Missing required configuration: ${key}`);
    }
    console.warn(`⚠️  Warning: Missing configuration: ${key}`);
  }
}

// ✅ FIX - JWT secrets should ALWAYS be required
const criticalConfigs = {
  'jwt.secret': true,
  'jwt.refreshSecret': true,
  'db.url': true,
};

const optionalConfigs = {
  'sentry.dsn': false,
  'firebase.projectId': false,
};

for (const [key, required] of Object.entries(criticalConfigs)) {
  const keys = key.split('.');
  let value = config;
  for (const k of keys) {
    value = value?.[k];
  }
  if (!value) {
    const message = `Missing required configuration: ${key}`;
    if (required || config.app.env === 'production') {
      throw new Error(message);
    }
    logger.warn(`⚠️  ${message}`);
  }
}
```

**Checklist**:
- [ ] Update config validation to require JWT secrets always
- [ ] Use logger instead of console.warn
- [ ] Test with missing jwt.secret in dev
- [ ] Test with missing jwt.secret in prod
- [ ] Test with valid secrets
- [ ] Verify error is thrown for missing critical configs

---

### Issue #12: Vehicle Routes - REST Convention
- **File**: `backend/src/routes/vehicle.routes.js`
- **Severity**: MEDIUM
- **Type**: REST Convention Issue

See Issue #2 above - already included there.

**Checklist**:
- [ ] Part of Issue #2 fix

---

### Issue #13: Validators - Decimal Format Consistency
- **File**: `backend/src/validators/*.js`
- **Severity**: MEDIUM
- **Type**: Validation Consistency

```javascript
// ❌ INCONSISTENT
body('quantity').isDecimal({ decimal_digits: '0,2' })  // vehicle.validator.js line 33
body('totalCost').isDecimal({ decimal_digits: '0,2' })  // service.validator.js

// ✅ FIX - Use consistent format
// Should be: min-max format like '1,2' or '0,3'
body('quantity').isDecimal({ decimal_digits: '0,2' })  // 0 or 1-2 decimals
body('unitPrice').isDecimal({ decimal_digits: '1,2' })  // 1-2 decimals (not optional)
body('totalCost').isDecimal({ decimal_digits: '0,2' })  // 0-2 decimals
```

**Checklist**:
- [ ] Audit all validators for decimal validation
- [ ] Standardize format: use `'0,2'` for optional, `'1,2'` for required
- [ ] Review all price fields
- [ ] Review all quantity fields
- [ ] Test with 0 decimals (e.g., 100)
- [ ] Test with 1 decimal (e.g., 100.5)
- [ ] Test with 2 decimals (e.g., 100.50)
- [ ] Test with invalid formats

---

### Issue #14: Scheduler - Prisma Raw Query Syntax
- **File**: `backend/src/utils/scheduler.js`
- **Lines**: 126-132
- **Severity**: MEDIUM
- **Type**: SQL/Prisma Issue

```javascript
// ❌ WRONG - snake_case columns but schema likely uses camelCase
const rawLowStock = await prisma.$queryRaw`
  SELECT id, name, sku, current_stock, reorder_level, branch_id
  FROM products
  WHERE deleted_at IS NULL
  AND is_active = true
  AND current_stock <= reorder_level
`;

// ✅ FIX - Use correct column names from schema
const rawLowStock = await prisma.$queryRaw`
  SELECT id, name, sku, currentStock, reorderLevel, branchId
  FROM Product
  WHERE deletedAt IS NULL
  AND isActive = true
  AND currentStock <= reorderLevel
`;
```

**Checklist**:
- [ ] Check Prisma schema for actual column names
- [ ] Update query to use camelCase
- [ ] Update table name (products -> Product in some ORMs)
- [ ] Test low stock check runs
- [ ] Verify results are returned
- [ ] Test notification sending

---

### Issue #15: Error Handler - Sentry Order
- **File**: `backend/src/app.js`
- **Lines**: 157-161
- **Severity**: MEDIUM
- **Type**: Error Handling / Monitoring

```javascript
// Current order - Sentry first, then custom error handler
if (config.sentry.dsn) {
  Sentry.setupExpressErrorHandler(app);
}
app.use(errorHandler);

// Consider this order instead
app.use(errorHandler);
if (config.sentry.dsn) {
  Sentry.setupExpressErrorHandler(app);  // Capture formatted errors
}
```

**Checklist**:
- [ ] Review Sentry documentation for proper ordering
- [ ] Test error handling with Sentry enabled
- [ ] Verify error format in Sentry dashboard
- [ ] Verify custom error format is preserved
- [ ] Test with both Sentry enabled and disabled

---

## 🔵 LOW PRIORITY ISSUES

### Issue #16: Logger - Directory Creation
- **File**: `backend/src/config/logger.js`
- **Severity**: LOW
- **Type**: Robustness Issue

```javascript
// ❌ Might fail if logDir doesn't exist
const logDir = config.logging.dir;
const logger = winston.createLogger({ /* ... */ });

// ✅ FIX - Create directory if missing
const fs = require('fs');

const logDir = config.logging.dir;
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

const logger = winston.createLogger({ /* ... */ });
```

**Checklist**:
- [ ] Add fs import
- [ ] Add directory creation check
- [ ] Test with missing logs directory
- [ ] Verify directory is created
- [ ] Verify logs are written

---

### Issue #17: Upload Middleware - Error Type
- **File**: `backend/src/middleware/upload.js`
- **Line**: 61
- **Severity**: LOW
- **Type**: Error Handling

```javascript
// ❌ BadRequestError might not format correctly for multer
const fileFilter = (_req, file, cb) => {
  if (ALLOWED_MIME_TYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new BadRequestError(`File type '${file.mimetype}' is not allowed`), false);
  }
};

// ✅ BETTER - Use native Error for multer
const fileFilter = (_req, file, cb) => {
  if (ALLOWED_MIME_TYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    const error = new Error(`File type '${file.mimetype}' is not allowed`);
    error.status = 400;
    error.errorCode = 'INVALID_FILE_TYPE';
    cb(error, false);
  }
};
```

**Checklist**:
- [ ] Test file upload with valid file type
- [ ] Test file upload with invalid file type
- [ ] Verify error response format
- [ ] Verify error message is clear

---

### Issue #18: Auth Service - Login Throttling
- **File**: `backend/src/services/auth.service.js`
- **Severity**: LOW
- **Type**: Security Enhancement

**Note**: Rate limiting is already handled at app.js middleware level for `/auth/login` endpoint. This is just for defense-in-depth.

```javascript
// Consider adding service-level validation
async login(email, password) {
  // Rate limit check could go here (optional, app.js handles it)
  const user = await prisma.user.findUnique({ /* ... */ });
  // ...
}
```

**Checklist**:
- [ ] Verify app.js has auth rate limiter (Lines 68-78) ✅
- [ ] No action needed - already protected at middleware layer
- [ ] Document in security section

---

## Summary

### Critical Issues: 4
- [ ] Issue #1: Scheduler Prisma field reference
- [ ] Issue #2: Vehicle route parameters
- [ ] Issue #3: Auth middleware empty catch
- [ ] Issue #4: Validate middleware sync throw

### High Priority Issues: 6
- [ ] Issue #5: Audit log response hijacking
- [ ] Issue #6: Audit log model reference
- [ ] Issue #7: Inventory pagination break
- [ ] Issue #8: Service routes conflict
- [ ] Issue #9: Firebase caching
- [ ] Issue #10: Scheduler model name case

### Medium Priority Issues: 5
- [ ] Issue #11: Config JWT validation
- [ ] Issue #12: REST conventions
- [ ] Issue #13: Decimal validation consistency
- [ ] Issue #14: Raw query column names
- [ ] Issue #15: Sentry error handler order

### Low Priority Issues: 3
- [ ] Issue #16: Logger directory creation
- [ ] Issue #17: Upload error type
- [ ] Issue #18: Login throttling (already handled)

---

**Total Items to Fix**: 18
**Expected Fix Time**: 4-6 hours
**Testing Time**: 2-3 hours
**Total Effort**: 6-9 hours
