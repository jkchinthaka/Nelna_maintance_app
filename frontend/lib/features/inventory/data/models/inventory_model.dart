import '../../domain/entities/inventory_entity.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Product Model
// ═══════════════════════════════════════════════════════════════════════════

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    super.categoryId,
    super.branchId,
    required super.name,
    required super.code,
    super.description,
    super.unit,
    super.minStockLevel,
    super.maxStockLevel,
    super.currentStock,
    super.reorderPoint,
    super.unitPrice,
    super.location,
    super.imageUrl,
    super.barcode,
    super.isActive,
    required super.createdAt,
    super.categoryName,
    super.branchName,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      categoryId: json['categoryId'] as int?,
      branchId: json['branchId'] as int?,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String?,
      unit: json['unit'] as String? ?? 'pcs',
      minStockLevel: _toInt(json['minStockLevel']),
      maxStockLevel: _toInt(json['maxStockLevel']),
      currentStock: _toInt(json['currentStock']),
      reorderPoint: _toInt(json['reorderPoint']),
      unitPrice: _toDouble(json['unitPrice']),
      location: json['location'] as String?,
      imageUrl: json['imageUrl'] as String?,
      barcode: json['barcode'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      categoryName: json['category'] is Map
          ? json['category']['name'] as String?
          : json['categoryName'] as String?,
      branchName: json['branch'] is Map
          ? json['branch']['name'] as String?
          : json['branchName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (categoryId != null) 'categoryId': categoryId,
      if (branchId != null) 'branchId': branchId,
      'name': name,
      'code': code,
      if (description != null) 'description': description,
      'unit': unit,
      'minStockLevel': minStockLevel,
      'maxStockLevel': maxStockLevel,
      'reorderPoint': reorderPoint,
      'unitPrice': unitPrice,
      if (location != null) 'location': location,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (barcode != null) 'barcode': barcode,
      'isActive': isActive,
    };
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Category Model
// ═══════════════════════════════════════════════════════════════════════════

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    super.description,
    super.parentId,
    super.isActive,
    super.productCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      parentId: json['parentId'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      productCount:
          json['productCount'] as int? ??
          (json['_count'] is Map
              ? (json['_count']['products'] as int? ?? 0)
              : 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (parentId != null) 'parentId': parentId,
      'isActive': isActive,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Supplier Model
// ═══════════════════════════════════════════════════════════════════════════

class SupplierModel extends SupplierEntity {
  const SupplierModel({
    required super.id,
    required super.name,
    super.contactPerson,
    super.email,
    super.phone,
    super.address,
    super.taxId,
    super.bankDetails,
    super.rating,
    super.isActive,
    super.totalOrders,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      contactPerson: json['contactPerson'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      taxId: json['taxId'] as String?,
      bankDetails: json['bankDetails'] as String?,
      rating: _toDouble(json['rating']),
      isActive: json['isActive'] as bool? ?? true,
      totalOrders:
          json['totalOrders'] as int? ??
          (json['_count'] is Map
              ? (json['_count']['purchaseOrders'] as int? ?? 0)
              : 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (contactPerson != null) 'contactPerson': contactPerson,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (taxId != null) 'taxId': taxId,
      if (bankDetails != null) 'bankDetails': bankDetails,
      'isActive': isActive,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Purchase Order Model
// ═══════════════════════════════════════════════════════════════════════════

class PurchaseOrderModel extends PurchaseOrderEntity {
  const PurchaseOrderModel({
    required super.id,
    required super.orderNo,
    required super.supplierId,
    super.branchId,
    super.status,
    super.totalAmount,
    super.notes,
    super.expectedDeliveryDate,
    super.approvedById,
    super.approvedDate,
    super.createdById,
    required super.createdAt,
    super.supplierName,
    super.items,
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] is List
        ? (json['items'] as List)
              .map(
                (e) =>
                    PurchaseOrderItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList()
        : <PurchaseOrderItemEntity>[];

    return PurchaseOrderModel(
      id: json['id'] as int,
      orderNo: json['orderNo'] as String? ?? '',
      supplierId: json['supplierId'] as int? ?? 0,
      branchId: json['branchId'] as int?,
      status: json['status'] as String? ?? 'Draft',
      totalAmount: _toDouble(json['totalAmount']),
      notes: json['notes'] as String?,
      expectedDeliveryDate: _tryParseDate(json['expectedDeliveryDate']),
      approvedById: json['approvedById'] as int?,
      approvedDate: _tryParseDate(json['approvedDate']),
      createdById: json['createdById'] as int?,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      supplierName: json['supplier'] is Map
          ? json['supplier']['name'] as String?
          : json['supplierName'] as String?,
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supplierId': supplierId,
      if (branchId != null) 'branchId': branchId,
      'status': status,
      if (notes != null) 'notes': notes,
      if (expectedDeliveryDate != null)
        'expectedDeliveryDate': expectedDeliveryDate!.toIso8601String(),
      if (items.isNotEmpty)
        'items': items
            .map(
              (e) => {
                'productId': e.productId,
                'quantity': e.quantity,
                'unitPrice': e.unitPrice,
              },
            )
            .toList(),
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Purchase Order Item Model
// ═══════════════════════════════════════════════════════════════════════════

class PurchaseOrderItemModel extends PurchaseOrderItemEntity {
  const PurchaseOrderItemModel({
    required super.id,
    required super.purchaseOrderId,
    required super.productId,
    super.quantity,
    super.receivedQuantity,
    super.unitPrice,
    super.totalPrice,
    super.productName,
    super.productCode,
  });

  factory PurchaseOrderItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItemModel(
      id: json['id'] as int? ?? 0,
      purchaseOrderId: json['purchaseOrderId'] as int? ?? 0,
      productId: json['productId'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      receivedQuantity: json['receivedQuantity'] as int? ?? 0,
      unitPrice: _toDouble(json['unitPrice']),
      totalPrice: _toDouble(json['totalPrice']),
      productName: json['product'] is Map
          ? json['product']['name'] as String?
          : json['productName'] as String?,
      productCode: json['product'] is Map
          ? json['product']['code'] as String?
          : json['productCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  GRN Model
// ═══════════════════════════════════════════════════════════════════════════

class GRNModel extends GRNEntity {
  const GRNModel({
    required super.id,
    required super.grnNo,
    required super.purchaseOrderId,
    super.branchId,
    super.receivedById,
    required super.receivedDate,
    super.notes,
    super.status,
    super.items,
    super.purchaseOrderNo,
  });

  factory GRNModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] is List
        ? (json['items'] as List)
              .map((e) => GRNItemModel.fromJson(e as Map<String, dynamic>))
              .toList()
        : <GRNItemEntity>[];

    return GRNModel(
      id: json['id'] as int,
      grnNo: json['grnNo'] as String? ?? '',
      purchaseOrderId: json['purchaseOrderId'] as int? ?? 0,
      branchId: json['branchId'] as int?,
      receivedById: json['receivedById'] as int?,
      receivedDate:
          DateTime.tryParse(json['receivedDate']?.toString() ?? '') ??
          DateTime.now(),
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'Pending',
      items: itemsList,
      purchaseOrderNo: json['purchaseOrder'] is Map
          ? json['purchaseOrder']['orderNo'] as String?
          : json['purchaseOrderNo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchaseOrderId': purchaseOrderId,
      if (branchId != null) 'branchId': branchId,
      if (notes != null) 'notes': notes,
      if (items.isNotEmpty)
        'items': items
            .map(
              (e) => {
                if (e is GRNItemModel)
                  'purchaseOrderItemId': e.purchaseOrderItemId,
                'receivedQuantity': e.receivedQuantity,
                'acceptedQuantity': e.acceptedQuantity,
                'rejectedQuantity': e.rejectedQuantity,
                if (e.reason != null) 'reason': e.reason,
              },
            )
            .toList(),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  GRN Item Model
// ═══════════════════════════════════════════════════════════════════════════

class GRNItemModel extends GRNItemEntity {
  const GRNItemModel({
    required super.id,
    required super.grnId,
    super.purchaseOrderItemId,
    super.receivedQuantity,
    super.acceptedQuantity,
    super.rejectedQuantity,
    super.reason,
    super.productName,
  });

  factory GRNItemModel.fromJson(Map<String, dynamic> json) {
    return GRNItemModel(
      id: json['id'] as int? ?? 0,
      grnId: json['grnId'] as int? ?? 0,
      purchaseOrderItemId: json['purchaseOrderItemId'] as int?,
      receivedQuantity: json['receivedQuantity'] as int? ?? 0,
      acceptedQuantity: json['acceptedQuantity'] as int? ?? 0,
      rejectedQuantity: json['rejectedQuantity'] as int? ?? 0,
      reason: json['reason'] as String?,
      productName: json['product'] is Map
          ? json['product']['name'] as String?
          : json['productName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (purchaseOrderItemId != null)
        'purchaseOrderItemId': purchaseOrderItemId,
      'receivedQuantity': receivedQuantity,
      'acceptedQuantity': acceptedQuantity,
      'rejectedQuantity': rejectedQuantity,
      if (reason != null) 'reason': reason,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Stock Movement Model
// ═══════════════════════════════════════════════════════════════════════════

class StockMovementModel extends StockMovementEntity {
  const StockMovementModel({
    required super.id,
    required super.productId,
    super.branchId,
    required super.type,
    required super.quantity,
    super.referenceType,
    super.referenceId,
    super.notes,
    super.performedById,
    required super.createdAt,
    super.productName,
    super.performedByName,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(
      id: json['id'] as int,
      productId: json['productId'] as int? ?? 0,
      branchId: json['branchId'] as int?,
      type: json['type'] as String? ?? 'In',
      quantity: json['quantity'] as int? ?? 0,
      referenceType: json['referenceType'] as String?,
      referenceId: json['referenceId'] as int?,
      notes: json['notes'] as String?,
      performedById: json['performedById'] as int?,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      productName: json['product'] is Map
          ? json['product']['name'] as String?
          : json['productName'] as String?,
      performedByName: json['performedBy'] is Map
          ? json['performedBy']['name'] as String?
          : json['performedByName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      if (branchId != null) 'branchId': branchId,
      'type': type,
      'quantity': quantity,
      if (referenceType != null) 'referenceType': referenceType,
      if (referenceId != null) 'referenceId': referenceId,
      if (notes != null) 'notes': notes,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Stock Alert Model
// ═══════════════════════════════════════════════════════════════════════════

class StockAlertModel extends StockAlert {
  const StockAlertModel({
    required super.productId,
    required super.productName,
    required super.productCode,
    required super.currentStock,
    required super.minStockLevel,
    required super.reorderPoint,
    required super.deficit,
  });

  factory StockAlertModel.fromJson(Map<String, dynamic> json) {
    final currentStock = json['currentStock'] as int? ?? 0;
    final reorderPoint = json['reorderPoint'] as int? ?? 0;

    return StockAlertModel(
      productId: json['productId'] as int? ?? json['id'] as int? ?? 0,
      productName:
          json['productName'] as String? ?? json['name'] as String? ?? '',
      productCode:
          json['productCode'] as String? ?? json['code'] as String? ?? '',
      currentStock: currentStock,
      minStockLevel: json['minStockLevel'] as int? ?? 0,
      reorderPoint: reorderPoint,
      deficit: reorderPoint - currentStock,
    );
  }
}
