import '../../domain/entities/report_entity.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Monthly Data Point Model
// ═══════════════════════════════════════════════════════════════════════════

class MonthlyDataPointModel extends MonthlyDataPoint {
  const MonthlyDataPointModel({
    required super.month,
    required super.count,
    required super.cost,
  });

  factory MonthlyDataPointModel.fromJson(Map<String, dynamic> json) {
    return MonthlyDataPointModel(
      month: json['month'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'month': month,
    'count': count,
    'cost': cost,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
//  Maintenance Report Model
// ═══════════════════════════════════════════════════════════════════════════

class MaintenanceReportModel extends MaintenanceReportEntity {
  const MaintenanceReportModel({
    required super.period,
    required super.totalRequests,
    required super.completedRequests,
    required super.pendingRequests,
    required super.avgResolutionTime,
    required super.totalCost,
    required super.byType,
    required super.byPriority,
    required super.monthlyTrend,
  });

  factory MaintenanceReportModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceReportModel(
      period: json['period'] as String? ?? '',
      totalRequests: (json['totalRequests'] as num?)?.toInt() ?? 0,
      completedRequests: (json['completedRequests'] as num?)?.toInt() ?? 0,
      pendingRequests: (json['pendingRequests'] as num?)?.toInt() ?? 0,
      avgResolutionTime: (json['avgResolutionTime'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
      byType: _parseMapStringInt(json['byType']),
      byPriority: _parseMapStringInt(json['byPriority']),
      monthlyTrend:
          (json['monthlyTrend'] as List<dynamic>?)
              ?.map(
                (e) =>
                    MonthlyDataPointModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Vehicle Cost Item Model
// ═══════════════════════════════════════════════════════════════════════════

class VehicleCostItemModel extends VehicleCostItem {
  const VehicleCostItemModel({
    required super.vehicleId,
    required super.registrationNo,
    required super.fuelCost,
    required super.maintenanceCost,
    required super.totalCost,
  });

  factory VehicleCostItemModel.fromJson(Map<String, dynamic> json) {
    return VehicleCostItemModel(
      vehicleId: (json['vehicleId'] as num?)?.toInt() ?? 0,
      registrationNo: json['registrationNo'] as String? ?? '',
      fuelCost: (json['fuelCost'] as num?)?.toDouble() ?? 0.0,
      maintenanceCost: (json['maintenanceCost'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'vehicleId': vehicleId,
    'registrationNo': registrationNo,
    'fuelCost': fuelCost,
    'maintenanceCost': maintenanceCost,
    'totalCost': totalCost,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
//  Vehicle Report Model
// ═══════════════════════════════════════════════════════════════════════════

class VehicleReportModel extends VehicleReportEntity {
  const VehicleReportModel({
    required super.totalVehicles,
    required super.activeVehicles,
    required super.totalFuelCost,
    required super.avgFuelEfficiency,
    required super.totalMaintenanceCost,
    required super.vehicleCosts,
    required super.fuelTrend,
  });

  factory VehicleReportModel.fromJson(Map<String, dynamic> json) {
    return VehicleReportModel(
      totalVehicles: (json['totalVehicles'] as num?)?.toInt() ?? 0,
      activeVehicles: (json['activeVehicles'] as num?)?.toInt() ?? 0,
      totalFuelCost: (json['totalFuelCost'] as num?)?.toDouble() ?? 0.0,
      avgFuelEfficiency: (json['avgFuelEfficiency'] as num?)?.toDouble() ?? 0.0,
      totalMaintenanceCost:
          (json['totalMaintenanceCost'] as num?)?.toDouble() ?? 0.0,
      vehicleCosts:
          (json['vehicleCosts'] as List<dynamic>?)
              ?.map(
                (e) => VehicleCostItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      fuelTrend:
          (json['fuelTrend'] as List<dynamic>?)
              ?.map(
                (e) =>
                    MonthlyDataPointModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Product Movement Model
// ═══════════════════════════════════════════════════════════════════════════

class ProductMovementModel extends ProductMovement {
  const ProductMovementModel({
    required super.productId,
    required super.productName,
    required super.totalMovements,
    required super.totalQuantity,
  });

  factory ProductMovementModel.fromJson(Map<String, dynamic> json) {
    return ProductMovementModel(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productName: json['productName'] as String? ?? '',
      totalMovements: (json['totalMovements'] as num?)?.toInt() ?? 0,
      totalQuantity: (json['totalQuantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'totalMovements': totalMovements,
    'totalQuantity': totalQuantity,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
//  Inventory Report Model
// ═══════════════════════════════════════════════════════════════════════════

class InventoryReportModel extends InventoryReportEntity {
  const InventoryReportModel({
    required super.totalProducts,
    required super.lowStockProducts,
    required super.totalInventoryValue,
    required super.topMovingProducts,
    required super.stockValueByCategory,
  });

  factory InventoryReportModel.fromJson(Map<String, dynamic> json) {
    return InventoryReportModel(
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      lowStockProducts: (json['lowStockProducts'] as num?)?.toInt() ?? 0,
      totalInventoryValue:
          (json['totalInventoryValue'] as num?)?.toDouble() ?? 0.0,
      topMovingProducts:
          (json['topMovingProducts'] as List<dynamic>?)
              ?.map(
                (e) => ProductMovementModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      stockValueByCategory: _parseMapStringDouble(json['stockValueByCategory']),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Expense Item Model
// ═══════════════════════════════════════════════════════════════════════════

class ExpenseItemModel extends ExpenseItem {
  const ExpenseItemModel({
    required super.description,
    required super.category,
    required super.amount,
    required super.date,
  });

  factory ExpenseItemModel.fromJson(Map<String, dynamic> json) {
    return ExpenseItemModel(
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'description': description,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
  };
}

// ═══════════════════════════════════════════════════════════════════════════
//  Expense Report Model
// ═══════════════════════════════════════════════════════════════════════════

class ExpenseReportModel extends ExpenseReportEntity {
  const ExpenseReportModel({
    required super.totalExpenses,
    required super.byCategory,
    required super.monthlyTrend,
    required super.topExpenses,
  });

  factory ExpenseReportModel.fromJson(Map<String, dynamic> json) {
    return ExpenseReportModel(
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      byCategory: _parseMapStringDouble(json['byCategory']),
      monthlyTrend:
          (json['monthlyTrend'] as List<dynamic>?)
              ?.map(
                (e) =>
                    MonthlyDataPointModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      topExpenses:
          (json['topExpenses'] as List<dynamic>?)
              ?.map((e) => ExpenseItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Helpers
// ═══════════════════════════════════════════════════════════════════════════

Map<String, int> _parseMapStringInt(dynamic raw) {
  if (raw is Map) {
    return raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
  }
  return {};
}

Map<String, double> _parseMapStringDouble(dynamic raw) {
  if (raw is Map) {
    return raw.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
  }
  return {};
}
