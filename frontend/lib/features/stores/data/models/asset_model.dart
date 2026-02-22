import '../../domain/entities/asset_entity.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Asset Model
// ═══════════════════════════════════════════════════════════════════════════

class AssetModel extends AssetEntity {
  const AssetModel({
    required super.id,
    required super.branchId,
    required super.name,
    required super.code,
    required super.category,
    super.description,
    super.serialNumber,
    super.purchaseDate,
    super.purchasePrice,
    super.currentValue,
    super.depreciationRate,
    super.condition,
    super.location,
    super.assignedToId,
    super.status,
    super.warrantyExpiry,
    super.imageUrl,
    super.notes,
    required super.createdAt,
    super.branchName,
    super.assignedToName,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'] as int,
      branchId: json['branchId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String?,
      serialNumber: json['serialNumber'] as String?,
      purchaseDate: _tryParseDate(json['purchaseDate']),
      purchasePrice: _toNullableDouble(json['purchasePrice']),
      currentValue: _toNullableDouble(json['currentValue']),
      depreciationRate: _toNullableDouble(json['depreciationRate']),
      condition: json['condition'] as String? ?? 'Good',
      location: json['location'] as String?,
      assignedToId: json['assignedToId'] as int?,
      status: json['status'] as String? ?? 'Available',
      warrantyExpiry: _tryParseDate(json['warrantyExpiry']),
      imageUrl: json['imageUrl'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      branchName:
          json['branch'] is Map ? json['branch']['name'] as String? : null,
      assignedToName: json['assignedTo'] is Map
          ? json['assignedTo']['name'] as String?
          : json['assignedToName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'name': name,
      'code': code,
      'category': category,
      if (description != null) 'description': description,
      if (serialNumber != null) 'serialNumber': serialNumber,
      if (purchaseDate != null)
        'purchaseDate': purchaseDate!.toIso8601String(),
      if (purchasePrice != null) 'purchasePrice': purchasePrice,
      if (currentValue != null) 'currentValue': currentValue,
      if (depreciationRate != null) 'depreciationRate': depreciationRate,
      'condition': condition,
      if (location != null) 'location': location,
      if (assignedToId != null) 'assignedToId': assignedToId,
      'status': status,
      if (warrantyExpiry != null)
        'warrantyExpiry': warrantyExpiry!.toIso8601String(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (notes != null) 'notes': notes,
    };
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Asset Repair Log Model
// ═══════════════════════════════════════════════════════════════════════════

class AssetRepairLogModel extends AssetRepairLogEntity {
  const AssetRepairLogModel({
    required super.id,
    required super.assetId,
    required super.reportedDate,
    required super.description,
    super.severity,
    super.status,
    super.repairCost,
    super.repairedById,
    super.completedDate,
    super.notes,
    super.assetName,
    super.repairedByName,
  });

  factory AssetRepairLogModel.fromJson(Map<String, dynamic> json) {
    return AssetRepairLogModel(
      id: json['id'] as int,
      assetId: json['assetId'] as int? ?? 0,
      reportedDate:
          DateTime.tryParse(json['reportedDate']?.toString() ?? '') ??
              DateTime.now(),
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String? ?? 'Medium',
      status: json['status'] as String? ?? 'Reported',
      repairCost: AssetModel._toNullableDouble(json['repairCost']),
      repairedById: json['repairedById'] as int?,
      completedDate: AssetModel._tryParseDate(json['completedDate']),
      notes: json['notes'] as String?,
      assetName:
          json['asset'] is Map ? json['asset']['name'] as String? : null,
      repairedByName: json['repairedBy'] is Map
          ? json['repairedBy']['name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'reportedDate': reportedDate.toIso8601String(),
      'description': description,
      'severity': severity,
      'status': status,
      if (repairCost != null) 'repairCost': repairCost,
      if (repairedById != null) 'repairedById': repairedById,
      if (completedDate != null)
        'completedDate': completedDate!.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Asset Transfer Model
// ═══════════════════════════════════════════════════════════════════════════

class AssetTransferModel extends AssetTransferEntity {
  const AssetTransferModel({
    required super.id,
    required super.assetId,
    required super.fromBranchId,
    required super.toBranchId,
    required super.transferDate,
    super.reason,
    super.status,
    super.approvedById,
    super.approvedDate,
    super.fromBranchName,
    super.toBranchName,
    super.assetName,
    super.approvedByName,
  });

  factory AssetTransferModel.fromJson(Map<String, dynamic> json) {
    return AssetTransferModel(
      id: json['id'] as int,
      assetId: json['assetId'] as int? ?? 0,
      fromBranchId: json['fromBranchId'] as int? ?? 0,
      toBranchId: json['toBranchId'] as int? ?? 0,
      transferDate:
          DateTime.tryParse(json['transferDate']?.toString() ?? '') ??
              DateTime.now(),
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'Pending',
      approvedById: json['approvedById'] as int?,
      approvedDate: AssetModel._tryParseDate(json['approvedDate']),
      fromBranchName: json['fromBranch'] is Map
          ? json['fromBranch']['name'] as String?
          : json['fromBranchName'] as String?,
      toBranchName: json['toBranch'] is Map
          ? json['toBranch']['name'] as String?
          : json['toBranchName'] as String?,
      assetName:
          json['asset'] is Map ? json['asset']['name'] as String? : null,
      approvedByName: json['approvedBy'] is Map
          ? json['approvedBy']['name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'fromBranchId': fromBranchId,
      'toBranchId': toBranchId,
      'transferDate': transferDate.toIso8601String(),
      if (reason != null) 'reason': reason,
      'status': status,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Asset Depreciation Summary Model
// ═══════════════════════════════════════════════════════════════════════════

class AssetDepreciationSummaryModel extends AssetDepreciationSummary {
  const AssetDepreciationSummaryModel({
    required super.totalAssets,
    required super.totalPurchaseValue,
    required super.totalCurrentValue,
    required super.totalDepreciation,
    required super.assetsByCondition,
  });

  factory AssetDepreciationSummaryModel.fromJson(Map<String, dynamic> json) {
    final conditionMap = <String, int>{};
    if (json['assetsByCondition'] is Map) {
      (json['assetsByCondition'] as Map).forEach((key, value) {
        conditionMap[key.toString()] =
            value is int ? value : int.tryParse(value.toString()) ?? 0;
      });
    }

    return AssetDepreciationSummaryModel(
      totalAssets: json['totalAssets'] as int? ?? 0,
      totalPurchaseValue:
          _toDouble(json['totalPurchaseValue']),
      totalCurrentValue:
          _toDouble(json['totalCurrentValue']),
      totalDepreciation:
          _toDouble(json['totalDepreciation']),
      assetsByCondition: conditionMap,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
