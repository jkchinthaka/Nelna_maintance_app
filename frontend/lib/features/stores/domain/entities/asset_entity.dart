import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Asset Entity
// ═══════════════════════════════════════════════════════════════════════════

class AssetEntity extends Equatable {
  final int id;
  final int branchId;
  final String name;
  final String code;
  final String category;
  final String? description;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final double? currentValue;
  final double? depreciationRate;
  final String condition; // New, Good, Fair, Poor, Damaged
  final String? location;
  final int? assignedToId;
  final String status; // Available, InUse, UnderRepair, Disposed, Lost
  final DateTime? warrantyExpiry;
  final String? imageUrl;
  final String? notes;
  final DateTime createdAt;

  // Nested / joined fields (nullable — populated on detail views)
  final String? branchName;
  final String? assignedToName;

  const AssetEntity({
    required this.id,
    required this.branchId,
    required this.name,
    required this.code,
    required this.category,
    this.description,
    this.serialNumber,
    this.purchaseDate,
    this.purchasePrice,
    this.currentValue,
    this.depreciationRate,
    this.condition = 'Good',
    this.location,
    this.assignedToId,
    this.status = 'Available',
    this.warrantyExpiry,
    this.imageUrl,
    this.notes,
    required this.createdAt,
    this.branchName,
    this.assignedToName,
  });

  /// Human-readable display name.
  String get displayName => '$name ($code)';

  /// Years since purchase.
  double get yearsInService {
    if (purchaseDate == null) return 0;
    return DateTime.now().difference(purchaseDate!).inDays / 365.25;
  }

  /// Whether warranty has expired.
  bool get isWarrantyExpired =>
      warrantyExpiry != null && warrantyExpiry!.isBefore(DateTime.now());

  /// Whether warranty is expiring within 30 days.
  bool get isWarrantyExpiring =>
      warrantyExpiry != null &&
      !isWarrantyExpired &&
      warrantyExpiry!.isBefore(DateTime.now().add(const Duration(days: 30)));

  /// Total depreciation amount.
  double get totalDepreciation => (purchasePrice ?? 0) - (currentValue ?? 0);

  /// Depreciation percentage.
  double get depreciationPercentage {
    if (purchasePrice == null || purchasePrice == 0) return 0;
    return (totalDepreciation / purchasePrice!) * 100;
  }

  @override
  List<Object?> get props => [
    id,
    branchId,
    name,
    code,
    category,
    description,
    serialNumber,
    purchaseDate,
    purchasePrice,
    currentValue,
    depreciationRate,
    condition,
    location,
    assignedToId,
    status,
    warrantyExpiry,
    imageUrl,
    notes,
    createdAt,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Asset Repair Log Entity
// ═══════════════════════════════════════════════════════════════════════════

class AssetRepairLogEntity extends Equatable {
  final int id;
  final int assetId;
  final DateTime reportedDate;
  final String description;
  final String severity; // Low, Medium, High, Critical
  final String status; // Reported, InProgress, Completed
  final double? repairCost;
  final int? repairedById;
  final DateTime? completedDate;
  final String? notes;

  // Joined
  final String? assetName;
  final String? repairedByName;

  const AssetRepairLogEntity({
    required this.id,
    required this.assetId,
    required this.reportedDate,
    required this.description,
    this.severity = 'Medium',
    this.status = 'Reported',
    this.repairCost,
    this.repairedById,
    this.completedDate,
    this.notes,
    this.assetName,
    this.repairedByName,
  });

  /// Whether the repair is still open.
  bool get isOpen => status != 'Completed';

  @override
  List<Object?> get props => [
    id,
    assetId,
    reportedDate,
    description,
    severity,
    status,
    repairCost,
    repairedById,
    completedDate,
    notes,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Asset Transfer Entity
// ═══════════════════════════════════════════════════════════════════════════

class AssetTransferEntity extends Equatable {
  final int id;
  final int assetId;
  final int fromBranchId;
  final int toBranchId;
  final DateTime transferDate;
  final String? reason;
  final String status; // Pending, Approved, InTransit, Completed, Rejected
  final int? approvedById;
  final DateTime? approvedDate;

  // Joined
  final String? fromBranchName;
  final String? toBranchName;
  final String? assetName;
  final String? approvedByName;

  const AssetTransferEntity({
    required this.id,
    required this.assetId,
    required this.fromBranchId,
    required this.toBranchId,
    required this.transferDate,
    this.reason,
    this.status = 'Pending',
    this.approvedById,
    this.approvedDate,
    this.fromBranchName,
    this.toBranchName,
    this.assetName,
    this.approvedByName,
  });

  /// Whether the transfer can still be approved.
  bool get canApprove => status == 'Pending';

  /// Whether the transfer is still active (not completed or rejected).
  bool get isActive => status != 'Completed' && status != 'Rejected';

  @override
  List<Object?> get props => [
    id,
    assetId,
    fromBranchId,
    toBranchId,
    transferDate,
    reason,
    status,
    approvedById,
    approvedDate,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Asset Depreciation Summary
// ═══════════════════════════════════════════════════════════════════════════

class AssetDepreciationSummary extends Equatable {
  final int totalAssets;
  final double totalPurchaseValue;
  final double totalCurrentValue;
  final double totalDepreciation;
  final Map<String, int> assetsByCondition;

  const AssetDepreciationSummary({
    required this.totalAssets,
    required this.totalPurchaseValue,
    required this.totalCurrentValue,
    required this.totalDepreciation,
    required this.assetsByCondition,
  });

  /// Depreciation as a percentage.
  double get depreciationPercentage {
    if (totalPurchaseValue == 0) return 0;
    return (totalDepreciation / totalPurchaseValue) * 100;
  }

  @override
  List<Object?> get props => [
    totalAssets,
    totalPurchaseValue,
    totalCurrentValue,
    totalDepreciation,
    assetsByCondition,
  ];
}
