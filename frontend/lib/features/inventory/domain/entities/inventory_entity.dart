import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Product Entity
// ═══════════════════════════════════════════════════════════════════════════

class ProductEntity extends Equatable {
  final int id;
  final int? categoryId;
  final int? branchId;
  final String name;
  final String code;
  final String? description;
  final String unit;
  final int minStockLevel;
  final int maxStockLevel;
  final int currentStock;
  final int reorderPoint;
  final double unitPrice;
  final String? location;
  final String? imageUrl;
  final String? barcode;
  final bool isActive;
  final DateTime createdAt;

  // Resolved relation names
  final String? categoryName;
  final String? branchName;

  const ProductEntity({
    required this.id,
    this.categoryId,
    this.branchId,
    required this.name,
    required this.code,
    this.description,
    this.unit = 'pcs',
    this.minStockLevel = 0,
    this.maxStockLevel = 0,
    this.currentStock = 0,
    this.reorderPoint = 0,
    this.unitPrice = 0,
    this.location,
    this.imageUrl,
    this.barcode,
    this.isActive = true,
    required this.createdAt,
    this.categoryName,
    this.branchName,
  });

  /// Whether stock is at or below the reorder point.
  bool get isLowStock => currentStock <= reorderPoint && reorderPoint > 0;

  /// Whether stock is at or below the minimum level.
  bool get isCriticalStock =>
      currentStock <= minStockLevel && minStockLevel > 0;

  /// Stock as a percentage of max stock.
  double get stockPercentage =>
      maxStockLevel > 0 ? (currentStock / maxStockLevel).clamp(0.0, 1.0) : 0;

  String get displayName => '$name ($code)';

  @override
  List<Object?> get props => [
    id,
    categoryId,
    branchId,
    name,
    code,
    description,
    unit,
    minStockLevel,
    maxStockLevel,
    currentStock,
    reorderPoint,
    unitPrice,
    location,
    imageUrl,
    barcode,
    isActive,
    createdAt,
    categoryName,
    branchName,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Category Entity
// ═══════════════════════════════════════════════════════════════════════════

class CategoryEntity extends Equatable {
  final int id;
  final String name;
  final String? description;
  final int? parentId;
  final bool isActive;
  final int productCount;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.isActive = true,
    this.productCount = 0,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    parentId,
    isActive,
    productCount,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Supplier Entity
// ═══════════════════════════════════════════════════════════════════════════

class SupplierEntity extends Equatable {
  final int id;
  final String name;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final String? taxId;
  final String? bankDetails;
  final double rating;
  final bool isActive;
  final int totalOrders;

  const SupplierEntity({
    required this.id,
    required this.name,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    this.taxId,
    this.bankDetails,
    this.rating = 0,
    this.isActive = true,
    this.totalOrders = 0,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    contactPerson,
    email,
    phone,
    address,
    taxId,
    bankDetails,
    rating,
    isActive,
    totalOrders,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Purchase Order Entity
// ═══════════════════════════════════════════════════════════════════════════

class PurchaseOrderEntity extends Equatable {
  final int id;
  final String orderNo;
  final int supplierId;
  final int? branchId;
  final String
  status; // Draft, Submitted, Approved, Ordered, PartiallyReceived, Received, Cancelled
  final double totalAmount;
  final String? notes;
  final DateTime? expectedDeliveryDate;
  final int? approvedById;
  final DateTime? approvedDate;
  final int? createdById;
  final DateTime createdAt;

  // Resolved relation names
  final String? supplierName;
  final List<PurchaseOrderItemEntity> items;

  const PurchaseOrderEntity({
    required this.id,
    required this.orderNo,
    required this.supplierId,
    this.branchId,
    this.status = 'Draft',
    this.totalAmount = 0,
    this.notes,
    this.expectedDeliveryDate,
    this.approvedById,
    this.approvedDate,
    this.createdById,
    required this.createdAt,
    this.supplierName,
    this.items = const [],
  });

  bool get isDraft => status == 'Draft';
  bool get isApproved => status == 'Approved';
  bool get canApprove => status == 'Submitted';
  bool get canCreateGRN => status == 'Ordered' || status == 'PartiallyReceived';

  @override
  List<Object?> get props => [
    id,
    orderNo,
    supplierId,
    branchId,
    status,
    totalAmount,
    notes,
    expectedDeliveryDate,
    approvedById,
    approvedDate,
    createdById,
    createdAt,
    supplierName,
    items,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Purchase Order Item Entity
// ═══════════════════════════════════════════════════════════════════════════

class PurchaseOrderItemEntity extends Equatable {
  final int id;
  final int purchaseOrderId;
  final int productId;
  final int quantity;
  final int receivedQuantity;
  final double unitPrice;
  final double totalPrice;

  // Resolved relation names
  final String? productName;
  final String? productCode;

  const PurchaseOrderItemEntity({
    required this.id,
    required this.purchaseOrderId,
    required this.productId,
    this.quantity = 0,
    this.receivedQuantity = 0,
    this.unitPrice = 0,
    this.totalPrice = 0,
    this.productName,
    this.productCode,
  });

  int get pendingQuantity => quantity - receivedQuantity;

  @override
  List<Object?> get props => [
    id,
    purchaseOrderId,
    productId,
    quantity,
    receivedQuantity,
    unitPrice,
    totalPrice,
    productName,
    productCode,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  GRN (Goods Received Note) Entity
// ═══════════════════════════════════════════════════════════════════════════

class GRNEntity extends Equatable {
  final int id;
  final String grnNo;
  final int purchaseOrderId;
  final int? branchId;
  final int? receivedById;
  final DateTime receivedDate;
  final String? notes;
  final String status; // Pending, Inspected, Accepted, Rejected
  final List<GRNItemEntity> items;

  // Resolved relation names
  final String? purchaseOrderNo;

  const GRNEntity({
    required this.id,
    required this.grnNo,
    required this.purchaseOrderId,
    this.branchId,
    this.receivedById,
    required this.receivedDate,
    this.notes,
    this.status = 'Pending',
    this.items = const [],
    this.purchaseOrderNo,
  });

  @override
  List<Object?> get props => [
    id,
    grnNo,
    purchaseOrderId,
    branchId,
    receivedById,
    receivedDate,
    notes,
    status,
    items,
    purchaseOrderNo,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  GRN Item Entity
// ═══════════════════════════════════════════════════════════════════════════

class GRNItemEntity extends Equatable {
  final int id;
  final int grnId;
  final int? purchaseOrderItemId;
  final int receivedQuantity;
  final int acceptedQuantity;
  final int rejectedQuantity;
  final String? reason;

  // Resolved relation names
  final String? productName;

  const GRNItemEntity({
    required this.id,
    required this.grnId,
    this.purchaseOrderItemId,
    this.receivedQuantity = 0,
    this.acceptedQuantity = 0,
    this.rejectedQuantity = 0,
    this.reason,
    this.productName,
  });

  @override
  List<Object?> get props => [
    id,
    grnId,
    purchaseOrderItemId,
    receivedQuantity,
    acceptedQuantity,
    rejectedQuantity,
    reason,
    productName,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Stock Movement Entity
// ═══════════════════════════════════════════════════════════════════════════

class StockMovementEntity extends Equatable {
  final int id;
  final int productId;
  final int? branchId;
  final String type; // In, Out, Transfer, Adjustment
  final int quantity;
  final String? referenceType;
  final int? referenceId;
  final String? notes;
  final int? performedById;
  final DateTime createdAt;

  // Resolved relation names
  final String? productName;
  final String? performedByName;

  const StockMovementEntity({
    required this.id,
    required this.productId,
    this.branchId,
    required this.type,
    required this.quantity,
    this.referenceType,
    this.referenceId,
    this.notes,
    this.performedById,
    required this.createdAt,
    this.productName,
    this.performedByName,
  });

  bool get isStockIn => type == 'In';
  bool get isStockOut => type == 'Out';

  @override
  List<Object?> get props => [
    id,
    productId,
    branchId,
    type,
    quantity,
    referenceType,
    referenceId,
    notes,
    performedById,
    createdAt,
    productName,
    performedByName,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Stock Alert
// ═══════════════════════════════════════════════════════════════════════════

class StockAlert extends Equatable {
  final int productId;
  final String productName;
  final String productCode;
  final int currentStock;
  final int minStockLevel;
  final int reorderPoint;
  final int deficit;

  const StockAlert({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.currentStock,
    required this.minStockLevel,
    required this.reorderPoint,
    required this.deficit,
  });

  /// Severity: 0.0 (okay) → 1.0 (critical).
  double get severity {
    if (reorderPoint <= 0) return 0;
    final ratio = currentStock / reorderPoint;
    return (1.0 - ratio).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
    productId,
    productName,
    productCode,
    currentStock,
    minStockLevel,
    reorderPoint,
    deficit,
  ];
}
