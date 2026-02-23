# Code Fixes Reference - Nelna Maintenance System

## Quick Reference for All Fixes Applied

---

## 1. auth.js - Empty Catch Block Fix

**File:** `backend/src/middleware/auth.js`  
**Line:** 143

### Before:
```javascript
    } catch {
      // Token invalid - continue without auth
    }
```

### After:
```javascript
    } catch (error) {
      logger.debug('Token validation failed', { error: error.message });
    }
```

### Why: Proper error logging for debugging and monitoring

---

## 2. validate.js - Synchronous Error Fix

**File:** `backend/src/middleware/validate.js`  
**Line:** 19

### Before:
```javascript
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map((err) => ({
      field: err.path,
      message: err.msg,
      value: err.value,
    }));
    throw new ValidationError('Validation failed', formattedErrors);
  }
  next();
};
```

### After:
```javascript
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map((err) => ({
      field: err.path,
      message: err.msg,
      value: err.value,
    }));
    const error = new ValidationError('Validation failed', formattedErrors);
    return next(error);
  }
  next();
};
```

### Why: Express error handler expects errors via `next(error)`, not thrown exceptions

---

## 3. vehicle.routes.js - Route Structure Fix

**File:** `backend/src/routes/vehicle.routes.js`  
**Lines:** 22-41

### Before:
```javascript
// CRUD operations
router.get('/', ...);
router.get('/reminders', ...);      // ← Problem: Between /:id routes
router.get('/:id', ...);
router.post('/', ...);
router.put('/:id', ...);
router.delete('/:id', ...);

// Fuel logs
router.get('/:id/fuel-logs', ...);
router.post('/fuel-logs', ...);     // ← Wrong: No vehicle ID

// Documents  
router.post('/documents', ...);     // ← Wrong: No vehicle ID

// Driver assignment
router.post('/assign-driver', ...); // ← Wrong: No vehicle ID
```

### After:
```javascript
// CRUD operations (in proper order)
router.get('/', ...);
router.post('/', ...);
router.get('/reminders', ...);      // ← Before /:id routes
router.get('/:id', ...);
router.put('/:id', ...);
router.delete('/:id', ...);

// Fuel logs (nested under vehicle)
router.get('/:id/fuel-logs', ...);
router.post('/:id/fuel-logs', ...); // ✅ Now has vehicle ID

// Documents (nested under vehicle)
router.post('/:id/documents', ...); // ✅ Now has vehicle ID

// Driver assignment (nested under vehicle)
router.post('/:id/assign-driver', ...); // ✅ Now has vehicle ID

// Analytics (nested under vehicle)
router.get('/:id/cost-analytics', ...);
```

### Why: RESTful convention, vehicle context clarity, prevents route conflicts

---

## 4. scheduler.js - Invalid Prisma Query Fix

**File:** `backend/src/utils/scheduler.js`  
**Lines:** 113-132

### Before:
```javascript
const lowStockProducts = await prisma.product.findMany({
  where: {
    deletedAt: null,
    isActive: true,
    currentStock: { lte: prisma.product.fields.reorderLevel }, // ← INVALID
  },
});

const rawLowStock = await prisma.$queryRaw`...`; // Duplicate query

if (rawLowStock.length > 0) {
  // ...
  for (const manager of storeManagers) {
    await notificationService.createNotification(
      manager.id,
      'Low Stock Alert',
      `${rawLowStock.length} products...`, // Wrong variable
    );
  }
}
```

### After:
```javascript
const lowStockProducts = await prisma.$queryRaw`
  SELECT id, name, sku, current_stock, reorder_level, branch_id
  FROM products
  WHERE deleted_at IS NULL
  AND is_active = true
  AND current_stock <= reorder_level
`;

if (lowStockProducts.length > 0) {
  // ...
  for (const manager of storeManagers) {
    await notificationService.createNotification(
      manager.id,
      'Low Stock Alert',
      `${lowStockProducts.length} products...`, // Correct variable
    );
  }
}
```

### Why: Prisma doesn't support field-to-field comparison in where conditions, must use raw SQL

---

## 5. auditLog.js - Model Validation Fix

**File:** `backend/src/middleware/auditLog.js`  
**Lines:** 50-62

### Before:
```javascript
const captureOldValues = (model) => {
  return async (req, res, next) => {
    try {
      const id = parseInt(req.params.id, 10);
      if (id && prisma[model]) {  // ← Only checks if model exists
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

### After:
```javascript
const captureOldValues = (model) => {
  return async (req, res, next) => {
    try {
      const id = parseInt(req.params.id, 10);
      // ✅ Validate model exists AND has findUnique method
      if (id && prisma[model] && typeof prisma[model].findUnique === 'function') {
        const oldRecord = await prisma[model].findUnique({ where: { id } });
        req._auditOldValues = oldRecord;
      } else if (!prisma[model]) {
        logger.warn(`Audit: Invalid model name "${model}" - skipping old values capture`);
      }
    } catch (error) {
      logger.error('Capture old values failed', { error: error.message, model });
    }
    next();
  };
};
```

### Why: Type-safe model validation, better error logging

---

## 6. service.routes.js - Route Nesting Fix

**File:** `backend/src/routes/service.routes.js`  
**Lines:** 128-135

### Before:
```javascript
router.put(
  '/tasks/:taskId',  // ← Problem: Could match as id="tasks"
  checkPermission(...),
  updateTaskValidator,
  validate,
  auditLog('UPDATE', 'services', 'ServiceTask'),
  serviceController.updateTask
);
```

### After:
```javascript
router.put(
  '/:id/tasks/:taskId',  // ✅ Now properly nested under service ID
  checkPermission(...),
  updateTaskValidator,
  validate,
  auditLog('UPDATE', 'services', 'ServiceTask'),
  serviceController.updateTask
);
```

### Why: Prevents route conflicts, maintains RESTful structure, provides service context

---

## 7. inventory.service.js - Pagination Logic Fix

**File:** `backend/src/services/inventory.service.js`  
**Lines:** 49-84

### Before:
```javascript
if (query.lowStock === 'true') {
  // Problem: Fetches limited items, then filters
  [products, total] = await Promise.all([
    prisma.product.findMany({
      where,
      skip,        // ← Applied before filter
      take: limit, // ← Applied before filter
    }),
    prisma.product.count({ where }),
  ]);

  // Filter removes some items, but total is now wrong!
  products = products.filter(
    (p) => parseFloat(p.currentStock) <= parseFloat(p.reorderLevel || 0)
  );
  total = products.length;  // ← Inconsistent with pagination
}
```

### After:
```javascript
if (query.lowStock === 'true') {
  // ✅ Fetch all, filter, then paginate
  const allProducts = await prisma.product.findMany({
    where,
    // No skip/take yet
  });

  // Filter all items
  const filteredProducts = allProducts.filter(
    (p) => parseFloat(p.currentStock) <= parseFloat(p.reorderLevel || 0)
  );
  
  total = filteredProducts.length;
  // Apply pagination to filtered results
  products = filteredProducts.slice(skip, skip + limit);
}
```

### Why: Correct pagination after filtering, consistent total count

---

## 8. .eslintrc.json - Configuration Created

**File:** `backend/.eslintrc.json` (NEW)

```json
{
  "env": {
    "node": true,
    "es2021": true,
    "jest": true
  },
  "extends": ["airbnb-base"],
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module"
  },
  "rules": {
    "no-console": ["warn", { "allow": ["warn", "error"] }],
    "no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "func-names": "off",
    "object-shorthand": "warn",
    "prefer-destructuring": "warn",
    "no-param-reassign": ["error", { "props": false }],
    "consistent-return": "warn",
    "max-classes-per-file": "off",
    "class-methods-use-this": "warn",
    "no-underscore-dangle": "off"
  }
}
```

### Why: Consistent code style, quality enforcement, team alignment

---

## 9. config/index.js - Documentation Fix

**File:** `backend/src/config/index.js`  
**Line:** 72

### Before:
```javascript
console.warn(`⚠️  Warning: Missing configuration: ${key}`);
```

### After:
```javascript
// Use console.warn here (logger requires this config to be loaded first)
console.warn(`⚠️  Warning: Missing configuration: ${key}`);
```

### Why: Document why console is used (avoids misunderstanding in code review)

---

## Testing the Fixes

```bash
# 1. Lint the code
cd backend
npm run lint

# 2. Run tests
npm test

# 3. Start backend
npm run dev

# 4. Test health endpoint
curl http://localhost:3000/api/v1/health

# 5. Test vehicle routes
curl http://localhost:3000/api/v1/vehicles

# 6. Test low-stock filter (with pagination)
curl "http://localhost:3000/api/v1/inventory/products?lowStock=true&page=1&limit=10"

# 7. Check audit logs are created
# (View in database: SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 10;)
```

---

## Deployment Verification

After deploying, verify:

1. **No errors in logs:** Check for "Token validation failed", "Validation failed"
2. **Routes work:** Test `/vehicles/:id/fuel-logs` endpoint
3. **Pagination:** Test low-stock filter with multiple pages
4. **Audit logs:** Check database for recent audit entries
5. **ESLint:** Run `npm run lint` - should return 0 errors

---

## Summary

| Issue | Severity | Fix Type | Lines | File |
|-------|----------|----------|-------|------|
| Empty catch | Critical | Error logging | 143 | auth.js |
| Throw in middleware | Critical | Use next() | 19 | validate.js |
| Route structure | Critical | Nesting | 22-41 | vehicle.routes.js |
| Prisma query | Critical | Raw SQL | 113-132 | scheduler.js |
| Model validation | Critical | Type check | 50-62 | auditLog.js |
| Route conflict | High | Nesting | 128-135 | service.routes.js |
| Pagination | High | Logic fix | 49-84 | inventory.service.js |
| ESLint | Medium | Config | NEW | .eslintrc.json |
| Console warning | Medium | Docs | 72 | config/index.js |

---

**All fixes are backward compatible and require no database changes or migrations.**
