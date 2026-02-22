import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Monthly Data Point
// ═══════════════════════════════════════════════════════════════════════════

class MonthlyDataPoint extends Equatable {
  final String month;
  final int count;
  final double cost;

  const MonthlyDataPoint({
    required this.month,
    required this.count,
    required this.cost,
  });

  @override
  List<Object?> get props => [month, count, cost];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Maintenance Report Entity
// ═══════════════════════════════════════════════════════════════════════════

class MaintenanceReportEntity extends Equatable {
  final String period;
  final int totalRequests;
  final int completedRequests;
  final int pendingRequests;
  final double avgResolutionTime;
  final double totalCost;
  final Map<String, int> byType;
  final Map<String, int> byPriority;
  final List<MonthlyDataPoint> monthlyTrend;

  const MaintenanceReportEntity({
    required this.period,
    required this.totalRequests,
    required this.completedRequests,
    required this.pendingRequests,
    required this.avgResolutionTime,
    required this.totalCost,
    required this.byType,
    required this.byPriority,
    required this.monthlyTrend,
  });

  int get inProgressRequests =>
      totalRequests - completedRequests - pendingRequests;

  double get completionRate =>
      totalRequests > 0 ? (completedRequests / totalRequests) * 100 : 0;

  @override
  List<Object?> get props => [
    period,
    totalRequests,
    completedRequests,
    pendingRequests,
    avgResolutionTime,
    totalCost,
    byType,
    byPriority,
    monthlyTrend,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Vehicle Report Entity
// ═══════════════════════════════════════════════════════════════════════════

class VehicleCostItem extends Equatable {
  final int vehicleId;
  final String registrationNo;
  final double fuelCost;
  final double maintenanceCost;
  final double totalCost;

  const VehicleCostItem({
    required this.vehicleId,
    required this.registrationNo,
    required this.fuelCost,
    required this.maintenanceCost,
    required this.totalCost,
  });

  @override
  List<Object?> get props => [
    vehicleId,
    registrationNo,
    fuelCost,
    maintenanceCost,
    totalCost,
  ];
}

class VehicleReportEntity extends Equatable {
  final int totalVehicles;
  final int activeVehicles;
  final double totalFuelCost;
  final double avgFuelEfficiency;
  final double totalMaintenanceCost;
  final List<VehicleCostItem> vehicleCosts;
  final List<MonthlyDataPoint> fuelTrend;

  const VehicleReportEntity({
    required this.totalVehicles,
    required this.activeVehicles,
    required this.totalFuelCost,
    required this.avgFuelEfficiency,
    required this.totalMaintenanceCost,
    required this.vehicleCosts,
    required this.fuelTrend,
  });

  double get totalFleetCost => totalFuelCost + totalMaintenanceCost;

  double get utilizationRate =>
      totalVehicles > 0 ? (activeVehicles / totalVehicles) * 100 : 0;

  @override
  List<Object?> get props => [
    totalVehicles,
    activeVehicles,
    totalFuelCost,
    avgFuelEfficiency,
    totalMaintenanceCost,
    vehicleCosts,
    fuelTrend,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Inventory Report Entity
// ═══════════════════════════════════════════════════════════════════════════

class ProductMovement extends Equatable {
  final int productId;
  final String productName;
  final int totalMovements;
  final int totalQuantity;

  const ProductMovement({
    required this.productId,
    required this.productName,
    required this.totalMovements,
    required this.totalQuantity,
  });

  @override
  List<Object?> get props => [
    productId,
    productName,
    totalMovements,
    totalQuantity,
  ];
}

class InventoryReportEntity extends Equatable {
  final int totalProducts;
  final int lowStockProducts;
  final double totalInventoryValue;
  final List<ProductMovement> topMovingProducts;
  final Map<String, double> stockValueByCategory;

  const InventoryReportEntity({
    required this.totalProducts,
    required this.lowStockProducts,
    required this.totalInventoryValue,
    required this.topMovingProducts,
    required this.stockValueByCategory,
  });

  double get lowStockPercentage =>
      totalProducts > 0 ? (lowStockProducts / totalProducts) * 100 : 0;

  @override
  List<Object?> get props => [
    totalProducts,
    lowStockProducts,
    totalInventoryValue,
    topMovingProducts,
    stockValueByCategory,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Expense Report Entity
// ═══════════════════════════════════════════════════════════════════════════

class ExpenseItem extends Equatable {
  final String description;
  final String category;
  final double amount;
  final DateTime date;

  const ExpenseItem({
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
  });

  @override
  List<Object?> get props => [description, category, amount, date];
}

class ExpenseReportEntity extends Equatable {
  final double totalExpenses;
  final Map<String, double> byCategory;
  final List<MonthlyDataPoint> monthlyTrend;
  final List<ExpenseItem> topExpenses;

  const ExpenseReportEntity({
    required this.totalExpenses,
    required this.byCategory,
    required this.monthlyTrend,
    required this.topExpenses,
  });

  String get highestCategory {
    if (byCategory.isEmpty) return 'N/A';
    return byCategory.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  @override
  List<Object?> get props => [
    totalExpenses,
    byCategory,
    monthlyTrend,
    topExpenses,
  ];
}
