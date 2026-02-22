// ============================================================================
// Nelna Maintenance System - Inventory Service (Business Logic)
// ============================================================================
const prisma = require('../config/database');
const { NotFoundError, BadRequestError, ConflictError } = require('../utils/errors');
const { generateReferenceNo, parsePagination, parseSort, buildSearchFilter } = require('../utils/helpers');

class InventoryService {
  // ==========================================================================
  // PRODUCTS
  // ==========================================================================

  /**
   * Get all products with pagination, search, and filters
   */
  async getAllProducts(query, user) {
    const { page, limit, skip } = parsePagination(query);
    const orderBy = parseSort(query, [
      'createdAt', 'name', 'sku', 'currentStock', 'unitPrice',
    ]);
    const searchFilter = buildSearchFilter(query, ['name', 'sku', 'barcode', 'description']);

    const where = {
      deletedAt: null,
      ...searchFilter,
      ...(query.categoryId && { categoryId: parseInt(query.categoryId, 10) }),
      ...(query.branchId && { branchId: parseInt(query.branchId, 10) }),
      ...(query.isActive !== undefined && { isActive: query.isActive === 'true' }),
    };

    // Filter low-stock products
    if (query.lowStock === 'true') {
      where.currentStock = { lte: prisma.$queryRaw ? undefined : undefined };
      // Use raw comparison: currentStock <= reorderLevel
      // Prisma doesn't support field-to-field comparison in where, so we handle it post-query
      // Instead, add a flag to filter after fetch, or use a raw approach
      // For Prisma, we use a workaround:
      delete where.currentStock;
    }

    // Branch-level filtering for non-admin users
    if (user.roleName !== 'super_admin' && user.roleName !== 'company_admin') {
      where.branchId = user.branchId;
    }

    let products;
    let total;

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
      total = products.length;
    } else {
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
    }

    return { products, pagination: { page, limit, total } };
  }

  /**
   * Get single product by ID with related data
   */
  async getProductById(id) {
    const product = await prisma.product.findFirst({
      where: { id, deletedAt: null },
      include: {
        branch: { select: { id: true, name: true, code: true } },
        category: { select: { id: true, name: true } },
        stockMovements: {
          orderBy: { createdAt: 'desc' },
          take: 20,
          include: {
            performer: { select: { id: true, firstName: true, lastName: true } },
          },
        },
      },
    });

    if (!product) throw new NotFoundError('Product not found');
    return product;
  }

  /**
   * Create a new product
   */
  async createProduct(data, user) {
    // Check for duplicate SKU within the same branch
    const existing = await prisma.product.findFirst({
      where: {
        sku: data.sku,
        branchId: data.branchId,
        deletedAt: null,
      },
    });
    if (existing) throw new ConflictError('A product with this SKU already exists in this branch');

    // Validate category if provided
    if (data.categoryId) {
      const category = await prisma.productCategory.findUnique({
        where: { id: data.categoryId },
      });
      if (!category) throw new NotFoundError('Product category not found');
    }

    const product = await prisma.product.create({
      data: {
        branchId: data.branchId,
        categoryId: data.categoryId || null,
        sku: data.sku,
        barcode: data.barcode || null,
        name: data.name,
        description: data.description || null,
        unit: data.unit,
        unitPrice: parseFloat(data.unitPrice),
        costPrice: data.costPrice ? parseFloat(data.costPrice) : null,
        currentStock: data.currentStock ? parseFloat(data.currentStock) : 0,
        minimumStock: data.minimumStock ? parseFloat(data.minimumStock) : 0,
        maximumStock: data.maximumStock ? parseFloat(data.maximumStock) : null,
        reorderLevel: data.reorderLevel ? parseFloat(data.reorderLevel) : 0,
        reorderQuantity: data.reorderQuantity ? parseFloat(data.reorderQuantity) : 0,
        location: data.location || null,
        isActive: true,
        createdBy: user.id,
      },
      include: {
        branch: { select: { id: true, name: true, code: true } },
        category: { select: { id: true, name: true } },
      },
    });

    return product;
  }

  /**
   * Update an existing product
   */
  async updateProduct(id, data) {
    const product = await prisma.product.findFirst({
      where: { id, deletedAt: null },
    });
    if (!product) throw new NotFoundError('Product not found');

    // Check duplicate SKU if changing
    if (data.sku && data.sku !== product.sku) {
      const existing = await prisma.product.findFirst({
        where: {
          sku: data.sku,
          branchId: product.branchId,
          deletedAt: null,
          NOT: { id },
        },
      });
      if (existing) throw new ConflictError('A product with this SKU already exists in this branch');
    }

    // Validate category if provided
    if (data.categoryId) {
      const category = await prisma.productCategory.findUnique({
        where: { id: data.categoryId },
      });
      if (!category) throw new NotFoundError('Product category not found');
    }

    const updateData = {};
    const allowedFields = [
      'categoryId', 'sku', 'barcode', 'name', 'description', 'unit',
      'unitPrice', 'costPrice', 'minimumStock', 'maximumStock',
      'reorderLevel', 'reorderQuantity', 'location', 'isActive',
    ];

    for (const field of allowedFields) {
      if (data[field] !== undefined) {
        const numericFields = ['unitPrice', 'costPrice', 'minimumStock', 'maximumStock', 'reorderLevel', 'reorderQuantity'];
        updateData[field] = numericFields.includes(field) ? parseFloat(data[field]) : data[field];
      }
    }

    const updated = await prisma.product.update({
      where: { id },
      data: updateData,
      include: {
        branch: { select: { id: true, name: true, code: true } },
        category: { select: { id: true, name: true } },
      },
    });

    return updated;
  }

  /**
   * Soft-delete a product
   */
  async deleteProduct(id) {
    const product = await prisma.product.findFirst({
      where: { id, deletedAt: null },
    });
    if (!product) throw new NotFoundError('Product not found');

    await prisma.product.update({
      where: { id },
      data: { deletedAt: new Date(), isActive: false },
    });

    return { id };
  }

  // ==========================================================================
  // CATEGORIES
  // ==========================================================================

  /**
   * Get all product categories (tree-like with parent)
   */
  async getAllCategories() {
    const categories = await prisma.productCategory.findMany({
      include: {
        parent: { select: { id: true, name: true } },
        children: { select: { id: true, name: true } },
        _count: { select: { products: true } },
      },
      orderBy: { name: 'asc' },
    });

    return categories;
  }

  /**
   * Create a product category
   */
  async createCategory(data) {
    // Validate parent if provided
    if (data.parentId) {
      const parent = await prisma.productCategory.findUnique({
        where: { id: data.parentId },
      });
      if (!parent) throw new NotFoundError('Parent category not found');
    }

    // Check duplicate name under same parent
    const existing = await prisma.productCategory.findFirst({
      where: {
        name: data.name,
        parentId: data.parentId || null,
      },
    });
    if (existing) throw new ConflictError('A category with this name already exists under the same parent');

    const category = await prisma.productCategory.create({
      data: {
        name: data.name,
        description: data.description || null,
        parentId: data.parentId || null,
      },
      include: {
        parent: { select: { id: true, name: true } },
      },
    });

    return category;
  }

  /**
   * Update a product category
   */
  async updateCategory(id, data) {
    const category = await prisma.productCategory.findUnique({
      where: { id },
    });
    if (!category) throw new NotFoundError('Category not found');

    // Prevent self-referencing
    if (data.parentId && data.parentId === id) {
      throw new BadRequestError('A category cannot be its own parent');
    }

    const updateData = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.parentId !== undefined) updateData.parentId = data.parentId;

    const updated = await prisma.productCategory.update({
      where: { id },
      data: updateData,
      include: {
        parent: { select: { id: true, name: true } },
        children: { select: { id: true, name: true } },
      },
    });

    return updated;
  }

  // ==========================================================================
  // STOCK MOVEMENTS
  // ==========================================================================

  /**
   * Stock In — add stock to product and record movement
   */
  async stockIn(data, user) {
    const product = await prisma.product.findFirst({
      where: { id: data.productId, deletedAt: null },
    });
    if (!product) throw new NotFoundError('Product not found');

    const quantity = parseFloat(data.quantity);
    const previousStock = parseFloat(product.currentStock);
    const newStock = previousStock + quantity;

    // Check maximum stock
    if (product.maximumStock && newStock > parseFloat(product.maximumStock)) {
      throw new BadRequestError(
        `Stock in would exceed maximum stock level (${product.maximumStock}). Current: ${previousStock}, Incoming: ${quantity}`
      );
    }

    const result = await prisma.$transaction(async (tx) => {
      // Update product stock
      const updatedProduct = await tx.product.update({
        where: { id: data.productId },
        data: { currentStock: newStock },
      });

      // Record stock movement
      const movement = await tx.stockMovement.create({
        data: {
          branchId: product.branchId,
          productId: data.productId,
          type: 'STOCK_IN',
          quantity,
          unitCost: data.unitCost ? parseFloat(data.unitCost) : null,
          referenceType: data.referenceType || null,
          referenceId: data.referenceId || null,
          reason: data.reason || null,
          previousStock,
          newStock,
          performedBy: user.id,
        },
      });

      return { product: updatedProduct, movement };
    });

    return result;
  }

  /**
   * Stock Out — remove stock from product and record movement
   */
  async stockOut(data, user) {
    const product = await prisma.product.findFirst({
      where: { id: data.productId, deletedAt: null },
    });
    if (!product) throw new NotFoundError('Product not found');

    const quantity = parseFloat(data.quantity);
    const previousStock = parseFloat(product.currentStock);

    if (quantity > previousStock) {
      throw new BadRequestError(
        `Insufficient stock. Available: ${previousStock}, Requested: ${quantity}`
      );
    }

    const newStock = previousStock - quantity;

    const result = await prisma.$transaction(async (tx) => {
      const updatedProduct = await tx.product.update({
        where: { id: data.productId },
        data: { currentStock: newStock },
      });

      const movement = await tx.stockMovement.create({
        data: {
          branchId: product.branchId,
          productId: data.productId,
          type: 'STOCK_OUT',
          quantity,
          unitCost: null,
          referenceType: data.referenceType || null,
          referenceId: data.referenceId || null,
          reason: data.reason || null,
          previousStock,
          newStock,
          performedBy: user.id,
        },
      });

      return { product: updatedProduct, movement };
    });

    return result;
  }

  /**
   * Adjust stock (correction)
   */
  async adjustStock(data, user) {
    const product = await prisma.product.findFirst({
      where: { id: data.productId, deletedAt: null },
    });
    if (!product) throw new NotFoundError('Product not found');

    const newStock = parseFloat(data.quantity);
    const previousStock = parseFloat(product.currentStock);

    if (newStock < 0) {
      throw new BadRequestError('Adjusted stock cannot be negative');
    }

    const result = await prisma.$transaction(async (tx) => {
      const updatedProduct = await tx.product.update({
        where: { id: data.productId },
        data: { currentStock: newStock },
      });

      const movement = await tx.stockMovement.create({
        data: {
          branchId: product.branchId,
          productId: data.productId,
          type: 'ADJUSTMENT',
          quantity: Math.abs(newStock - previousStock),
          unitCost: null,
          referenceType: data.referenceType || 'MANUAL_ADJUSTMENT',
          referenceId: data.referenceId || null,
          reason: data.reason || 'Stock adjustment',
          previousStock,
          newStock,
          performedBy: user.id,
        },
      });

      return { product: updatedProduct, movement };
    });

    return result;
  }

  /**
   * Get stock movements for a product
   */
  async getStockMovements(productId, query) {
    const { page, limit, skip } = parsePagination(query);

    const where = { productId };
    if (query.type) where.type = query.type;

    const [movements, total] = await Promise.all([
      prisma.stockMovement.findMany({
        where,
        include: {
          product: { select: { id: true, sku: true, name: true, unit: true } },
          performer: { select: { id: true, firstName: true, lastName: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.stockMovement.count({ where }),
    ]);

    return { movements, pagination: { page, limit, total } };
  }

  /**
   * Get low stock alerts — products where currentStock <= reorderLevel
   */
  async getLowStockAlerts(query, user) {
    const { page, limit, skip } = parsePagination(query);

    const where = {
      deletedAt: null,
      isActive: true,
      reorderLevel: { gt: 0 },
    };

    // Branch-level filtering for non-admin users
    if (user.roleName !== 'super_admin' && user.roleName !== 'company_admin') {
      where.branchId = user.branchId;
    }
    if (query.branchId) {
      where.branchId = parseInt(query.branchId, 10);
    }

    // Fetch all matching products and filter post-query for field-to-field comparison
    const allProducts = await prisma.product.findMany({
      where,
      include: {
        branch: { select: { id: true, name: true, code: true } },
        category: { select: { id: true, name: true } },
      },
      orderBy: { currentStock: 'asc' },
    });

    const lowStockProducts = allProducts.filter(
      (p) => parseFloat(p.currentStock) <= parseFloat(p.reorderLevel)
    );

    const total = lowStockProducts.length;
    const paginatedProducts = lowStockProducts.slice(skip, skip + limit);

    return { products: paginatedProducts, pagination: { page, limit, total } };
  }

  // ==========================================================================
  // SUPPLIERS
  // ==========================================================================

  /**
   * Get all suppliers with pagination and search
   */
  async getAllSuppliers(query) {
    const { page, limit, skip } = parsePagination(query);
    const orderBy = parseSort(query, ['createdAt', 'name', 'code', 'rating']);
    const searchFilter = buildSearchFilter(query, ['name', 'code', 'contactPerson', 'email']);

    const where = {
      deletedAt: null,
      ...searchFilter,
    };

    const [suppliers, total] = await Promise.all([
      prisma.supplier.findMany({
        where,
        include: {
          _count: { select: { purchaseOrders: true } },
        },
        orderBy,
        skip,
        take: limit,
      }),
      prisma.supplier.count({ where }),
    ]);

    return { suppliers, pagination: { page, limit, total } };
  }

  /**
   * Get single supplier by ID
   */
  async getSupplierById(id) {
    const supplier = await prisma.supplier.findFirst({
      where: { id, deletedAt: null },
      include: {
        purchaseOrders: {
          orderBy: { createdAt: 'desc' },
          take: 10,
          select: {
            id: true,
            poNumber: true,
            status: true,
            totalAmount: true,
            orderDate: true,
          },
        },
        _count: { select: { purchaseOrders: true } },
      },
    });

    if (!supplier) throw new NotFoundError('Supplier not found');
    return supplier;
  }

  /**
   * Create a new supplier
   */
  async createSupplier(data, user) {
    // Check duplicate code
    const existing = await prisma.supplier.findFirst({
      where: { code: data.code, deletedAt: null },
    });
    if (existing) throw new ConflictError('A supplier with this code already exists');

    const supplier = await prisma.supplier.create({
      data: {
        name: data.name,
        code: data.code,
        contactPerson: data.contactPerson || null,
        email: data.email || null,
        phone: data.phone || null,
        address: data.address || null,
        taxId: data.taxId || null,
        bankDetails: data.bankDetails || null,
        paymentTerms: data.paymentTerms || null,
        rating: data.rating ? parseFloat(data.rating) : null,
        createdBy: user.id,
      },
    });

    return supplier;
  }

  /**
   * Update a supplier
   */
  async updateSupplier(id, data) {
    const supplier = await prisma.supplier.findFirst({
      where: { id, deletedAt: null },
    });
    if (!supplier) throw new NotFoundError('Supplier not found');

    // Check duplicate code if changing
    if (data.code && data.code !== supplier.code) {
      const existing = await prisma.supplier.findFirst({
        where: { code: data.code, deletedAt: null, NOT: { id } },
      });
      if (existing) throw new ConflictError('A supplier with this code already exists');
    }

    const updateData = {};
    const allowedFields = [
      'name', 'code', 'contactPerson', 'email', 'phone',
      'address', 'taxId', 'bankDetails', 'paymentTerms', 'rating',
    ];

    for (const field of allowedFields) {
      if (data[field] !== undefined) {
        updateData[field] = field === 'rating' ? parseFloat(data[field]) : data[field];
      }
    }

    const updated = await prisma.supplier.update({
      where: { id },
      data: updateData,
    });

    return updated;
  }

  /**
   * Soft-delete a supplier
   */
  async deleteSupplier(id) {
    const supplier = await prisma.supplier.findFirst({
      where: { id, deletedAt: null },
    });
    if (!supplier) throw new NotFoundError('Supplier not found');

    // Check for active POs
    const activePOs = await prisma.purchaseOrder.count({
      where: {
        supplierId: id,
        status: { in: ['DRAFT', 'SUBMITTED', 'APPROVED', 'PARTIALLY_RECEIVED'] },
      },
    });
    if (activePOs > 0) {
      throw new BadRequestError('Cannot delete supplier with active purchase orders');
    }

    await prisma.supplier.update({
      where: { id },
      data: { deletedAt: new Date() },
    });

    return { id };
  }

  // ==========================================================================
  // PURCHASE ORDERS
  // ==========================================================================

  /**
   * Get all purchase orders with pagination
   */
  async getAllPurchaseOrders(query, user) {
    const { page, limit, skip } = parsePagination(query);
    const orderBy = parseSort(query, [
      'createdAt', 'poNumber', 'orderDate', 'status', 'totalAmount',
    ]);

    const where = {
      deletedAt: null,
      ...(query.status && { status: query.status }),
      ...(query.supplierId && { supplierId: parseInt(query.supplierId, 10) }),
      ...(query.branchId && { branchId: parseInt(query.branchId, 10) }),
    };

    if (user.roleName !== 'super_admin' && user.roleName !== 'company_admin') {
      where.branchId = user.branchId;
    }

    const [purchaseOrders, total] = await Promise.all([
      prisma.purchaseOrder.findMany({
        where,
        include: {
          branch: { select: { id: true, name: true, code: true } },
          supplier: { select: { id: true, name: true, code: true } },
          _count: { select: { items: true } },
        },
        orderBy,
        skip,
        take: limit,
      }),
      prisma.purchaseOrder.count({ where }),
    ]);

    return { purchaseOrders, pagination: { page, limit, total } };
  }

  /**
   * Get single purchase order by ID with items
   */
  async getPurchaseOrderById(id) {
    const po = await prisma.purchaseOrder.findFirst({
      where: { id, deletedAt: null },
      include: {
        branch: { select: { id: true, name: true, code: true } },
        supplier: true,
        items: {
          include: {
            product: { select: { id: true, sku: true, name: true, unit: true } },
          },
        },
        grns: {
          select: {
            id: true,
            grnNumber: true,
            receivedDate: true,
            status: true,
          },
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!po) throw new NotFoundError('Purchase order not found');
    return po;
  }

  /**
   * Create a new purchase order with items
   */
  async createPurchaseOrder(data, user) {
    // Validate supplier
    const supplier = await prisma.supplier.findFirst({
      where: { id: data.supplierId, deletedAt: null },
    });
    if (!supplier) throw new NotFoundError('Supplier not found');

    // Validate all products
    const productIds = data.items.map((item) => item.productId);
    const products = await prisma.product.findMany({
      where: { id: { in: productIds }, deletedAt: null },
    });
    if (products.length !== productIds.length) {
      throw new BadRequestError('One or more products not found');
    }

    // Calculate totals
    const items = data.items.map((item) => {
      const qty = parseFloat(item.quantity);
      const price = parseFloat(item.unitPrice);
      return {
        productId: item.productId,
        quantity: qty,
        unitPrice: price,
        totalPrice: qty * price,
        receivedQty: 0,
      };
    });

    const subtotal = items.reduce((sum, item) => sum + item.totalPrice, 0);
    const taxAmount = data.taxAmount ? parseFloat(data.taxAmount) : 0;
    const discountAmount = data.discountAmount ? parseFloat(data.discountAmount) : 0;
    const totalAmount = subtotal + taxAmount - discountAmount;

    const poNumber = generateReferenceNo('PO');

    const purchaseOrder = await prisma.$transaction(async (tx) => {
      const po = await tx.purchaseOrder.create({
        data: {
          branchId: data.branchId,
          supplierId: data.supplierId,
          poNumber,
          orderDate: data.orderDate ? new Date(data.orderDate) : new Date(),
          expectedDate: data.expectedDate ? new Date(data.expectedDate) : null,
          status: 'DRAFT',
          subtotal,
          taxAmount,
          discountAmount,
          totalAmount,
          createdBy: user.id,
          items: {
            create: items,
          },
        },
        include: {
          branch: { select: { id: true, name: true, code: true } },
          supplier: { select: { id: true, name: true, code: true } },
          items: {
            include: {
              product: { select: { id: true, sku: true, name: true, unit: true } },
            },
          },
        },
      });

      return po;
    });

    return purchaseOrder;
  }

  /**
   * Update purchase order status
   */
  async updatePOStatus(id, status) {
    const po = await prisma.purchaseOrder.findFirst({
      where: { id, deletedAt: null },
    });
    if (!po) throw new NotFoundError('Purchase order not found');

    // Validate status transitions
    const validTransitions = {
      DRAFT: ['SUBMITTED', 'CANCELLED'],
      SUBMITTED: ['APPROVED', 'CANCELLED'],
      APPROVED: ['PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED'],
      PARTIALLY_RECEIVED: ['RECEIVED', 'CLOSED'],
      RECEIVED: ['CLOSED'],
      CANCELLED: [],
      CLOSED: [],
    };

    const allowed = validTransitions[po.status] || [];
    if (!allowed.includes(status)) {
      throw new BadRequestError(
        `Cannot transition from ${po.status} to ${status}. Allowed: ${allowed.join(', ') || 'none'}`
      );
    }

    const updated = await prisma.purchaseOrder.update({
      where: { id },
      data: { status },
    });

    return updated;
  }

  /**
   * Approve a purchase order
   */
  async approvePO(id, userId) {
    const po = await prisma.purchaseOrder.findFirst({
      where: { id, deletedAt: null },
    });
    if (!po) throw new NotFoundError('Purchase order not found');

    if (po.status !== 'SUBMITTED') {
      throw new BadRequestError('Only submitted purchase orders can be approved');
    }

    const updated = await prisma.purchaseOrder.update({
      where: { id },
      data: {
        status: 'APPROVED',
        approvedBy: userId,
        approvedAt: new Date(),
      },
    });

    return updated;
  }

  // ==========================================================================
  // GOODS RECEIVED NOTES (GRN)
  // ==========================================================================

  /**
   * Create a GRN — update PO received quantities and product stock
   */
  async createGRN(data, user) {
    // Validate Purchase Order
    const po = await prisma.purchaseOrder.findFirst({
      where: { id: data.purchaseOrderId, deletedAt: null },
      include: { items: true },
    });
    if (!po) throw new NotFoundError('Purchase order not found');

    if (!['APPROVED', 'PARTIALLY_RECEIVED'].includes(po.status)) {
      throw new BadRequestError('GRN can only be created for approved or partially received purchase orders');
    }

    // Validate supplier
    const supplier = await prisma.supplier.findFirst({
      where: { id: data.supplierId, deletedAt: null },
    });
    if (!supplier) throw new NotFoundError('Supplier not found');

    const grnNumber = generateReferenceNo('GRN');

    const result = await prisma.$transaction(async (tx) => {
      // Create GRN
      const grn = await tx.gRN.create({
        data: {
          purchaseOrderId: data.purchaseOrderId,
          supplierId: data.supplierId,
          grnNumber,
          receivedDate: data.receivedDate ? new Date(data.receivedDate) : new Date(),
          invoiceNo: data.invoiceNo || null,
          status: 'PENDING',
          createdBy: user.id,
          items: {
            create: data.items.map((item) => ({
              productId: item.productId,
              orderedQty: parseFloat(item.orderedQty),
              receivedQty: parseFloat(item.receivedQty),
              acceptedQty: parseFloat(item.acceptedQty),
              rejectedQty: item.rejectedQty ? parseFloat(item.rejectedQty) : 0,
              rejectReason: item.rejectReason || null,
              unitCost: parseFloat(item.unitCost),
            })),
          },
        },
        include: {
          items: {
            include: {
              product: { select: { id: true, sku: true, name: true, unit: true } },
            },
          },
          supplier: { select: { id: true, name: true, code: true } },
          purchaseOrder: { select: { id: true, poNumber: true, status: true } },
        },
      });

      // Update PO item received quantities and product stock
      for (const grnItem of data.items) {
        const acceptedQty = parseFloat(grnItem.acceptedQty);

        // Update PO item receivedQty
        const poItem = po.items.find((i) => i.productId === grnItem.productId);
        if (poItem) {
          await tx.purchaseOrderItem.update({
            where: { id: poItem.id },
            data: {
              receivedQty: parseFloat(poItem.receivedQty) + parseFloat(grnItem.receivedQty),
            },
          });
        }

        // Update product stock (only acceptedQty)
        if (acceptedQty > 0) {
          const product = await tx.product.findUnique({
            where: { id: grnItem.productId },
          });

          if (product) {
            const previousStock = parseFloat(product.currentStock);
            const newStock = previousStock + acceptedQty;

            await tx.product.update({
              where: { id: grnItem.productId },
              data: { currentStock: newStock },
            });

            // Record stock movement
            await tx.stockMovement.create({
              data: {
                branchId: product.branchId,
                productId: grnItem.productId,
                type: 'STOCK_IN',
                quantity: acceptedQty,
                unitCost: parseFloat(grnItem.unitCost),
                referenceType: 'GRN',
                referenceId: grn.id,
                reason: `GRN ${grnNumber} - PO ${po.poNumber}`,
                previousStock,
                newStock,
                performedBy: user.id,
              },
            });
          }
        }
      }

      // Determine PO status based on received quantities
      const updatedPOItems = await tx.purchaseOrderItem.findMany({
        where: { purchaseOrderId: po.id },
      });

      const allFullyReceived = updatedPOItems.every(
        (item) => parseFloat(item.receivedQty) >= parseFloat(item.quantity)
      );
      const anyReceived = updatedPOItems.some(
        (item) => parseFloat(item.receivedQty) > 0
      );

      let newPOStatus = po.status;
      if (allFullyReceived) {
        newPOStatus = 'RECEIVED';
      } else if (anyReceived) {
        newPOStatus = 'PARTIALLY_RECEIVED';
      }

      if (newPOStatus !== po.status) {
        await tx.purchaseOrder.update({
          where: { id: po.id },
          data: { status: newPOStatus },
        });
      }

      return grn;
    });

    return result;
  }

  /**
   * Get GRNs by purchase order
   */
  async getGRNsByPO(purchaseOrderId) {
    const po = await prisma.purchaseOrder.findFirst({
      where: { id: purchaseOrderId, deletedAt: null },
    });
    if (!po) throw new NotFoundError('Purchase order not found');

    const grns = await prisma.gRN.findMany({
      where: { purchaseOrderId },
      include: {
        items: {
          include: {
            product: { select: { id: true, sku: true, name: true, unit: true } },
          },
        },
        supplier: { select: { id: true, name: true, code: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return grns;
  }
}

module.exports = new InventoryService();
