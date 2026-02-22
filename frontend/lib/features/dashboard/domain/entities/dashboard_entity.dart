import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Dashboard KPIs Entity
// ═══════════════════════════════════════════════════════════════════════════

/// Aggregated key performance indicators shown on the main dashboard.
class DashboardKPIs extends Equatable {
  final int activeVehicles;
  final int operationalMachines;
  final int openServiceRequests;
  final int lowStockItems;
  final int pendingPOs;
  final double expensesThisMonth;
  final int totalAssets;
  final int assetsUnderRepair;

  const DashboardKPIs({
    this.activeVehicles = 0,
    this.operationalMachines = 0,
    this.openServiceRequests = 0,
    this.lowStockItems = 0,
    this.pendingPOs = 0,
    this.expensesThisMonth = 0,
    this.totalAssets = 0,
    this.assetsUnderRepair = 0,
  });

  @override
  List<Object?> get props => [
        activeVehicles,
        operationalMachines,
        openServiceRequests,
        lowStockItems,
        pendingPOs,
        expensesThisMonth,
        totalAssets,
        assetsUnderRepair,
      ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Monthly Trend Entity
// ═══════════════════════════════════════════════════════════════════════════

/// A single month's aggregated trend data for charts.
class MonthlyTrend extends Equatable {
  final int month;
  final String monthLabel;
  final double expenseAmount;
  final int expenseCount;
  final int serviceRequestCount;
  final double serviceCost;
  final int completedRequests;

  const MonthlyTrend({
    required this.month,
    required this.monthLabel,
    this.expenseAmount = 0,
    this.expenseCount = 0,
    this.serviceRequestCount = 0,
    this.serviceCost = 0,
    this.completedRequests = 0,
  });

  /// Total costs for the month (expenses + service costs).
  double get totalCosts => expenseAmount + serviceCost;

  @override
  List<Object?> get props => [
        month,
        monthLabel,
        expenseAmount,
        expenseCount,
        serviceRequestCount,
        serviceCost,
        completedRequests,
      ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Monthly Trends Response (wraps the list + yearly totals)
// ═══════════════════════════════════════════════════════════════════════════

class MonthlyTrendsResponse extends Equatable {
  final int year;
  final List<MonthlyTrend> months;
  final YearlyTotals yearlyTotals;

  const MonthlyTrendsResponse({
    required this.year,
    required this.months,
    required this.yearlyTotals,
  });

  @override
  List<Object?> get props => [year, months, yearlyTotals];
}

class YearlyTotals extends Equatable {
  final double totalExpenses;
  final double totalServiceCost;
  final int totalServiceRequests;
  final int totalCompleted;

  const YearlyTotals({
    this.totalExpenses = 0,
    this.totalServiceCost = 0,
    this.totalServiceRequests = 0,
    this.totalCompleted = 0,
  });

  @override
  List<Object?> get props => [
        totalExpenses,
        totalServiceCost,
        totalServiceRequests,
        totalCompleted,
      ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Service Request Stats Entity
// ═══════════════════════════════════════════════════════════════════════════

/// Service request distribution statistics.
class ServiceRequestStats extends Equatable {
  final List<StatusCount> byStatus;
  final List<PriorityCount> byPriority;
  final List<CategoryCount> byCategory;
  final ServiceStatsSummary summary;

  const ServiceRequestStats({
    this.byStatus = const [],
    this.byPriority = const [],
    this.byCategory = const [],
    this.summary = const ServiceStatsSummary(),
  });

  /// Total number of service requests.
  int get totalRequests => summary.totalRequests;

  @override
  List<Object?> get props => [byStatus, byPriority, byCategory, summary];
}

class StatusCount extends Equatable {
  final String status;
  final int count;

  const StatusCount({required this.status, required this.count});

  @override
  List<Object?> get props => [status, count];
}

class PriorityCount extends Equatable {
  final String priority;
  final int count;

  const PriorityCount({required this.priority, required this.count});

  @override
  List<Object?> get props => [priority, count];
}

class CategoryCount extends Equatable {
  final String category;
  final int count;
  final double totalCost;

  const CategoryCount({
    required this.category,
    required this.count,
    this.totalCost = 0,
  });

  @override
  List<Object?> get props => [category, count, totalCost];
}

class ServiceStatsSummary extends Equatable {
  final int totalRequests;
  final double totalActualCost;
  final double totalEstimatedCost;
  final double averageCost;
  final double avgResolutionHours;
  final int completedCount;

  const ServiceStatsSummary({
    this.totalRequests = 0,
    this.totalActualCost = 0,
    this.totalEstimatedCost = 0,
    this.averageCost = 0,
    this.avgResolutionHours = 0,
    this.completedCount = 0,
  });

  @override
  List<Object?> get props => [
        totalRequests,
        totalActualCost,
        totalEstimatedCost,
        averageCost,
        avgResolutionHours,
        completedCount,
      ];
}
