import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Machine Entity
// ═══════════════════════════════════════════════════════════════════════════

class MachineEntity extends Equatable {
  final int id;
  final int branchId;
  final String name;
  final String code;
  final String type; // category
  final String? manufacturer;
  final String? model;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final String? location;
  final String status; // Active, UnderMaintenance, Decommissioned, Idle
  final String? condition;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;
  final double operatingHours;
  final String? imageUrl;
  final Map<String, dynamic>? specifications;
  final String? notes;
  final DateTime createdAt;

  // Nested relation (nullable — populated on detail views)
  final String? branchName;

  const MachineEntity({
    required this.id,
    required this.branchId,
    required this.name,
    required this.code,
    required this.type,
    this.manufacturer,
    this.model,
    this.serialNumber,
    this.purchaseDate,
    this.purchasePrice,
    this.location,
    this.status = 'ACTIVE',
    this.condition,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    this.operatingHours = 0,
    this.imageUrl,
    this.specifications,
    this.notes,
    required this.createdAt,
    this.branchName,
  });

  /// Human‑readable display name.
  String get displayName => '$name ($code)';

  /// Whether next maintenance is overdue.
  bool get isMaintenanceOverdue =>
      nextMaintenanceDate != null &&
      nextMaintenanceDate!.isBefore(DateTime.now());

  /// Whether next maintenance is upcoming within 7 days.
  bool get isMaintenanceSoon =>
      nextMaintenanceDate != null &&
      !isMaintenanceOverdue &&
      nextMaintenanceDate!.isBefore(
        DateTime.now().add(const Duration(days: 7)),
      );

  @override
  List<Object?> get props => [
    id,
    branchId,
    name,
    code,
    type,
    manufacturer,
    model,
    serialNumber,
    purchaseDate,
    purchasePrice,
    location,
    status,
    condition,
    lastMaintenanceDate,
    nextMaintenanceDate,
    operatingHours,
    imageUrl,
    specifications,
    notes,
    createdAt,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Maintenance Schedule Entity
// ═══════════════════════════════════════════════════════════════════════════

class MaintenanceScheduleEntity extends Equatable {
  final int id;
  final int machineId;
  final String type; // Preventive, Predictive, Corrective
  final String frequency; // Daily, Weekly, Monthly, Quarterly, Yearly
  final DateTime? lastPerformed;
  final DateTime nextDue;
  final String? assignedTo;
  final String? instructions;
  final bool isActive;
  final int? estimatedDuration; // in minutes
  final double? estimatedCost;

  const MaintenanceScheduleEntity({
    required this.id,
    required this.machineId,
    required this.type,
    required this.frequency,
    this.lastPerformed,
    required this.nextDue,
    this.assignedTo,
    this.instructions,
    this.isActive = true,
    this.estimatedDuration,
    this.estimatedCost,
  });

  /// Whether the schedule is overdue.
  bool get isOverdue => nextDue.isBefore(DateTime.now());

  /// Whether the schedule is due within 3 days.
  bool get isDueSoon =>
      !isOverdue &&
      nextDue.isBefore(DateTime.now().add(const Duration(days: 3)));

  @override
  List<Object?> get props => [
    id,
    machineId,
    type,
    frequency,
    lastPerformed,
    nextDue,
    assignedTo,
    instructions,
    isActive,
    estimatedDuration,
    estimatedCost,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Breakdown Log Entity
// ═══════════════════════════════════════════════════════════════════════════

class BreakdownLogEntity extends Equatable {
  final int id;
  final int machineId;
  final String? reportedBy;
  final DateTime reportedDate;
  final String description;
  final String severity; // Critical, High, Medium, Low
  final String status; // Reported, InProgress, Resolved, Closed
  final DateTime? resolvedDate;
  final String? resolvedBy;
  final String? rootCause;
  final String? actionTaken;
  final double? downtimeHours;
  final double? cost;
  final String? machineName;

  const BreakdownLogEntity({
    required this.id,
    required this.machineId,
    this.reportedBy,
    required this.reportedDate,
    required this.description,
    required this.severity,
    this.status = 'REPORTED',
    this.resolvedDate,
    this.resolvedBy,
    this.rootCause,
    this.actionTaken,
    this.downtimeHours,
    this.cost,
    this.machineName,
  });

  /// Whether the breakdown is still open (not resolved/closed).
  bool get isOpen => status == 'REPORTED' || status == 'IN_PROGRESS';

  @override
  List<Object?> get props => [
    id,
    machineId,
    reportedBy,
    reportedDate,
    description,
    severity,
    status,
    resolvedDate,
    resolvedBy,
    rootCause,
    actionTaken,
    downtimeHours,
    cost,
    machineName,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  AMC Contract Entity
// ═══════════════════════════════════════════════════════════════════════════

class AMCContractEntity extends Equatable {
  final int id;
  final int machineId;
  final String vendorName;
  final String contractNo;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final String? coverageDetails;
  final String? contactPerson;
  final String? contactPhone;
  final String? terms;
  final bool isActive;

  const AMCContractEntity({
    required this.id,
    required this.machineId,
    required this.vendorName,
    required this.contractNo,
    required this.startDate,
    required this.endDate,
    required this.amount,
    this.coverageDetails,
    this.contactPerson,
    this.contactPhone,
    this.terms,
    this.isActive = true,
  });

  /// Days remaining until contract expires.
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  /// Whether the contract has expired.
  bool get isExpired => endDate.isBefore(DateTime.now());

  /// Whether the contract is expiring within 30 days.
  bool get isExpiringSoon =>
      !isExpired &&
      endDate.isBefore(DateTime.now().add(const Duration(days: 30)));

  @override
  List<Object?> get props => [
    id,
    machineId,
    vendorName,
    contractNo,
    startDate,
    endDate,
    amount,
    coverageDetails,
    contactPerson,
    contactPhone,
    terms,
    isActive,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Machine Service History Entity
// ═══════════════════════════════════════════════════════════════════════════

class MachineServiceHistoryEntity extends Equatable {
  final int id;
  final int machineId;
  final DateTime serviceDate;
  final String serviceType;
  final String description;
  final String? performedBy;
  final double? cost;
  final DateTime? nextServiceDate;
  final String? notes;

  const MachineServiceHistoryEntity({
    required this.id,
    required this.machineId,
    required this.serviceDate,
    required this.serviceType,
    required this.description,
    this.performedBy,
    this.cost,
    this.nextServiceDate,
    this.notes,
  });

  @override
  List<Object?> get props => [
    id,
    machineId,
    serviceDate,
    serviceType,
    description,
    performedBy,
    cost,
    nextServiceDate,
    notes,
  ];
}
