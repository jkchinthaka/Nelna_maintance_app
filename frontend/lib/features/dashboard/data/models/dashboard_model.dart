import '../../domain/entities/dashboard_entity.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Dashboard KPIs Model
// ═══════════════════════════════════════════════════════════════════════════

class DashboardKPIsModel extends DashboardKPIs {
  const DashboardKPIsModel({
    super.activeVehicles,
    super.operationalMachines,
    super.openServiceRequests,
    super.lowStockItems,
    super.pendingPOs,
    super.expensesThisMonth,
    super.totalAssets,
    super.assetsUnderRepair,
  });

  factory DashboardKPIsModel.fromJson(Map<String, dynamic> json) {
    return DashboardKPIsModel(
      activeVehicles: (json['activeVehicles'] as num?)?.toInt() ?? 0,
      operationalMachines: (json['operationalMachines'] as num?)?.toInt() ?? 0,
      openServiceRequests: (json['openServiceRequests'] as num?)?.toInt() ?? 0,
      lowStockItems: (json['lowStockItems'] as num?)?.toInt() ?? 0,
      pendingPOs: (json['pendingPOs'] as num?)?.toInt() ?? 0,
      expensesThisMonth: (json['expensesThisMonth'] as num?)?.toDouble() ?? 0,
      totalAssets: (json['totalAssets'] as num?)?.toInt() ?? 0,
      assetsUnderRepair: (json['assetsUnderRepair'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'activeVehicles': activeVehicles,
    'operationalMachines': operationalMachines,
    'openServiceRequests': openServiceRequests,
    'lowStockItems': lowStockItems,
    'pendingPOs': pendingPOs,
    'expensesThisMonth': expensesThisMonth,
    'totalAssets': totalAssets,
    'assetsUnderRepair': assetsUnderRepair,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
//  Monthly Trend Model
// ═══════════════════════════════════════════════════════════════════════════

class MonthlyTrendModel extends MonthlyTrend {
  const MonthlyTrendModel({
    required super.month,
    required super.monthLabel,
    super.expenseAmount,
    super.expenseCount,
    super.serviceRequestCount,
    super.serviceCost,
    super.completedRequests,
  });

  factory MonthlyTrendModel.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendModel(
      month: (json['month'] as num?)?.toInt() ?? 0,
      monthLabel: json['monthLabel'] as String? ?? '',
      expenseAmount: (json['expenseAmount'] as num?)?.toDouble() ?? 0,
      expenseCount: (json['expenseCount'] as num?)?.toInt() ?? 0,
      serviceRequestCount: (json['serviceRequestCount'] as num?)?.toInt() ?? 0,
      serviceCost: (json['serviceCost'] as num?)?.toDouble() ?? 0,
      completedRequests: (json['completedRequests'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'month': month,
    'monthLabel': monthLabel,
    'expenseAmount': expenseAmount,
    'expenseCount': expenseCount,
    'serviceRequestCount': serviceRequestCount,
    'serviceCost': serviceCost,
    'completedRequests': completedRequests,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
//  Monthly Trends Response Model
// ═══════════════════════════════════════════════════════════════════════════

class MonthlyTrendsResponseModel extends MonthlyTrendsResponse {
  const MonthlyTrendsResponseModel({
    required super.year,
    required super.months,
    required super.yearlyTotals,
  });

  factory MonthlyTrendsResponseModel.fromJson(Map<String, dynamic> json) {
    final monthsList =
        (json['months'] as List<dynamic>?)
            ?.map((m) => MonthlyTrendModel.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];

    final totalsJson = json['yearlyTotals'] as Map<String, dynamic>? ?? {};

    return MonthlyTrendsResponseModel(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      months: monthsList,
      yearlyTotals: YearlyTotalsModel.fromJson(totalsJson),
    );
  }
}

class YearlyTotalsModel extends YearlyTotals {
  const YearlyTotalsModel({
    super.totalExpenses,
    super.totalServiceCost,
    super.totalServiceRequests,
    super.totalCompleted,
  });

  factory YearlyTotalsModel.fromJson(Map<String, dynamic> json) {
    return YearlyTotalsModel(
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0,
      totalServiceCost: (json['totalServiceCost'] as num?)?.toDouble() ?? 0,
      totalServiceRequests:
          (json['totalServiceRequests'] as num?)?.toInt() ?? 0,
      totalCompleted: (json['totalCompleted'] as num?)?.toInt() ?? 0,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Service Request Stats Model
// ═══════════════════════════════════════════════════════════════════════════

class ServiceRequestStatsModel extends ServiceRequestStats {
  const ServiceRequestStatsModel({
    super.byStatus,
    super.byPriority,
    super.byCategory,
    super.summary,
  });

  factory ServiceRequestStatsModel.fromJson(Map<String, dynamic> json) {
    final statusList =
        (json['byStatus'] as List<dynamic>?)
            ?.map((s) => StatusCountModel.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    final priorityList =
        (json['byPriority'] as List<dynamic>?)
            ?.map((p) => PriorityCountModel.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    final categoryList =
        (json['byCategory'] as List<dynamic>?)
            ?.map((c) => CategoryCountModel.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];

    final summaryJson = json['summary'] as Map<String, dynamic>? ?? {};

    return ServiceRequestStatsModel(
      byStatus: statusList,
      byPriority: priorityList,
      byCategory: categoryList,
      summary: ServiceStatsSummaryModel.fromJson(summaryJson),
    );
  }
}

class StatusCountModel extends StatusCount {
  const StatusCountModel({required super.status, required super.count});

  factory StatusCountModel.fromJson(Map<String, dynamic> json) {
    return StatusCountModel(
      status: json['status'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class PriorityCountModel extends PriorityCount {
  const PriorityCountModel({required super.priority, required super.count});

  factory PriorityCountModel.fromJson(Map<String, dynamic> json) {
    return PriorityCountModel(
      priority: json['priority'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CategoryCountModel extends CategoryCount {
  const CategoryCountModel({
    required super.category,
    required super.count,
    super.totalCost,
  });

  factory CategoryCountModel.fromJson(Map<String, dynamic> json) {
    return CategoryCountModel(
      category: json['category'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ServiceStatsSummaryModel extends ServiceStatsSummary {
  const ServiceStatsSummaryModel({
    super.totalRequests,
    super.totalActualCost,
    super.totalEstimatedCost,
    super.averageCost,
    super.avgResolutionHours,
    super.completedCount,
  });

  factory ServiceStatsSummaryModel.fromJson(Map<String, dynamic> json) {
    return ServiceStatsSummaryModel(
      totalRequests: (json['totalRequests'] as num?)?.toInt() ?? 0,
      totalActualCost: (json['totalActualCost'] as num?)?.toDouble() ?? 0,
      totalEstimatedCost: (json['totalEstimatedCost'] as num?)?.toDouble() ?? 0,
      averageCost: (json['averageCost'] as num?)?.toDouble() ?? 0,
      avgResolutionHours: (json['avgResolutionHours'] as num?)?.toDouble() ?? 0,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
    );
  }
}
