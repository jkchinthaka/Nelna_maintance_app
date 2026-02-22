import '../../domain/entities/machine_entity.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Machine Model
// ═══════════════════════════════════════════════════════════════════════════

class MachineModel extends MachineEntity {
  const MachineModel({
    required super.id,
    required super.branchId,
    required super.name,
    required super.code,
    required super.type,
    super.manufacturer,
    super.model,
    super.serialNumber,
    super.purchaseDate,
    super.purchasePrice,
    super.location,
    super.status,
    super.condition,
    super.lastMaintenanceDate,
    super.nextMaintenanceDate,
    super.operatingHours,
    super.imageUrl,
    super.specifications,
    super.notes,
    required super.createdAt,
    super.branchName,
  });

  factory MachineModel.fromJson(Map<String, dynamic> json) {
    return MachineModel(
      id: json['id'] as int,
      branchId: json['branchId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? json['category'] as String? ?? '',
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      serialNumber: json['serialNumber'] as String?,
      purchaseDate: _tryParseDate(json['purchaseDate']),
      purchasePrice: _toNullableDouble(json['purchasePrice']),
      location: json['location'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      condition: json['condition'] as String?,
      lastMaintenanceDate: _tryParseDate(json['lastMaintenanceDate']),
      nextMaintenanceDate: _tryParseDate(json['nextMaintenanceDate']),
      operatingHours: _toDouble(json['operatingHours']),
      imageUrl: json['imageUrl'] as String?,
      specifications: json['specifications'] is Map<String, dynamic>
          ? json['specifications'] as Map<String, dynamic>
          : null,
      notes: json['notes'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      branchName: json['branch'] is Map
          ? json['branch']['name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'name': name,
      'code': code,
      'type': type,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (model != null) 'model': model,
      if (serialNumber != null) 'serialNumber': serialNumber,
      if (purchaseDate != null) 'purchaseDate': purchaseDate!.toIso8601String(),
      if (purchasePrice != null) 'purchasePrice': purchasePrice,
      if (location != null) 'location': location,
      'status': status,
      if (condition != null) 'condition': condition,
      if (lastMaintenanceDate != null)
        'lastMaintenanceDate': lastMaintenanceDate!.toIso8601String(),
      if (nextMaintenanceDate != null)
        'nextMaintenanceDate': nextMaintenanceDate!.toIso8601String(),
      'operatingHours': operatingHours,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (specifications != null) 'specifications': specifications,
      if (notes != null) 'notes': notes,
    };
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

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
//  Maintenance Schedule Model
// ═══════════════════════════════════════════════════════════════════════════

class MaintenanceScheduleModel extends MaintenanceScheduleEntity {
  const MaintenanceScheduleModel({
    required super.id,
    required super.machineId,
    required super.type,
    required super.frequency,
    super.lastPerformed,
    required super.nextDue,
    super.assignedTo,
    super.instructions,
    super.isActive,
    super.estimatedDuration,
    super.estimatedCost,
  });

  factory MaintenanceScheduleModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceScheduleModel(
      id: json['id'] as int,
      machineId: json['machineId'] as int? ?? 0,
      type: json['type'] as String? ?? 'Preventive',
      frequency: json['frequency'] as String? ?? 'Monthly',
      lastPerformed: MachineModel._tryParseDate(json['lastPerformed']),
      nextDue:
          DateTime.tryParse(json['nextDue']?.toString() ?? '') ??
          DateTime.now(),
      assignedTo: json['assignedTo'] as String?,
      instructions: json['instructions'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      estimatedDuration: json['estimatedDuration'] as int?,
      estimatedCost: MachineModel._toNullableDouble(json['estimatedCost']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'machineId': machineId,
      'type': type,
      'frequency': frequency,
      if (lastPerformed != null)
        'lastPerformed': lastPerformed!.toIso8601String(),
      'nextDue': nextDue.toIso8601String(),
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (instructions != null) 'instructions': instructions,
      'isActive': isActive,
      if (estimatedDuration != null) 'estimatedDuration': estimatedDuration,
      if (estimatedCost != null) 'estimatedCost': estimatedCost,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Breakdown Log Model
// ═══════════════════════════════════════════════════════════════════════════

class BreakdownLogModel extends BreakdownLogEntity {
  const BreakdownLogModel({
    required super.id,
    required super.machineId,
    super.reportedBy,
    required super.reportedDate,
    required super.description,
    required super.severity,
    super.status,
    super.resolvedDate,
    super.resolvedBy,
    super.rootCause,
    super.actionTaken,
    super.downtimeHours,
    super.cost,
    super.machineName,
  });

  factory BreakdownLogModel.fromJson(Map<String, dynamic> json) {
    return BreakdownLogModel(
      id: json['id'] as int,
      machineId: json['machineId'] as int? ?? 0,
      reportedBy: json['reportedBy'] as String?,
      reportedDate:
          DateTime.tryParse(json['reportedDate']?.toString() ?? '') ??
          DateTime.now(),
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String? ?? 'Medium',
      status: json['status'] as String? ?? 'REPORTED',
      resolvedDate: MachineModel._tryParseDate(json['resolvedDate']),
      resolvedBy: json['resolvedBy'] as String?,
      rootCause: json['rootCause'] as String?,
      actionTaken: json['actionTaken'] as String?,
      downtimeHours: MachineModel._toNullableDouble(json['downtimeHours']),
      cost: MachineModel._toNullableDouble(json['cost']),
      machineName: json['machine'] is Map
          ? json['machine']['name'] as String?
          : json['machineName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'machineId': machineId,
      if (reportedBy != null) 'reportedBy': reportedBy,
      'reportedDate': reportedDate.toIso8601String(),
      'description': description,
      'severity': severity,
      'status': status,
      if (resolvedDate != null) 'resolvedDate': resolvedDate!.toIso8601String(),
      if (resolvedBy != null) 'resolvedBy': resolvedBy,
      if (rootCause != null) 'rootCause': rootCause,
      if (actionTaken != null) 'actionTaken': actionTaken,
      if (downtimeHours != null) 'downtimeHours': downtimeHours,
      if (cost != null) 'cost': cost,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  AMC Contract Model
// ═══════════════════════════════════════════════════════════════════════════

class AMCContractModel extends AMCContractEntity {
  const AMCContractModel({
    required super.id,
    required super.machineId,
    required super.vendorName,
    required super.contractNo,
    required super.startDate,
    required super.endDate,
    required super.amount,
    super.coverageDetails,
    super.contactPerson,
    super.contactPhone,
    super.terms,
    super.isActive,
  });

  factory AMCContractModel.fromJson(Map<String, dynamic> json) {
    return AMCContractModel(
      id: json['id'] as int,
      machineId: json['machineId'] as int? ?? 0,
      vendorName: json['vendorName'] as String? ?? '',
      contractNo: json['contractNo'] as String? ?? '',
      startDate:
          DateTime.tryParse(json['startDate']?.toString() ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['endDate']?.toString() ?? '') ??
          DateTime.now(),
      amount: MachineModel._toDouble(json['amount']),
      coverageDetails: json['coverageDetails'] as String?,
      contactPerson: json['contactPerson'] as String?,
      contactPhone: json['contactPhone'] as String?,
      terms: json['terms'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'machineId': machineId,
      'vendorName': vendorName,
      'contractNo': contractNo,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'amount': amount,
      if (coverageDetails != null) 'coverageDetails': coverageDetails,
      if (contactPerson != null) 'contactPerson': contactPerson,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (terms != null) 'terms': terms,
      'isActive': isActive,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Machine Service History Model
// ═══════════════════════════════════════════════════════════════════════════

class MachineServiceHistoryModel extends MachineServiceHistoryEntity {
  const MachineServiceHistoryModel({
    required super.id,
    required super.machineId,
    required super.serviceDate,
    required super.serviceType,
    required super.description,
    super.performedBy,
    super.cost,
    super.nextServiceDate,
    super.notes,
  });

  factory MachineServiceHistoryModel.fromJson(Map<String, dynamic> json) {
    return MachineServiceHistoryModel(
      id: json['id'] as int,
      machineId: json['machineId'] as int? ?? 0,
      serviceDate:
          DateTime.tryParse(json['serviceDate']?.toString() ?? '') ??
          DateTime.now(),
      serviceType: json['serviceType'] as String? ?? '',
      description: json['description'] as String? ?? '',
      performedBy: json['performedBy'] as String?,
      cost: MachineModel._toNullableDouble(json['cost']),
      nextServiceDate: MachineModel._tryParseDate(json['nextServiceDate']),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'machineId': machineId,
      'serviceDate': serviceDate.toIso8601String(),
      'serviceType': serviceType,
      'description': description,
      if (performedBy != null) 'performedBy': performedBy,
      if (cost != null) 'cost': cost,
      if (nextServiceDate != null)
        'nextServiceDate': nextServiceDate!.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }
}
