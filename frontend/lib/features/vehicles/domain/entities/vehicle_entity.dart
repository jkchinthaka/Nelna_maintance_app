import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Vehicle Entity
// ═══════════════════════════════════════════════════════════════════════════

class VehicleEntity extends Equatable {
  final int id;
  final int branchId;
  final String registrationNo;
  final String make;
  final String model;
  final int? year;
  final String? engineNo;
  final String? chassisNo;
  final String fuelType;
  final String vehicleType;
  final String? color;
  final double mileage;
  final String status;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final DateTime? insuranceExpiry;
  final DateTime? licenseExpiry;
  final DateTime? lastServiceDate;
  final DateTime? nextServiceDate;
  final double? nextServiceMileage;
  final String? imageUrl;
  final String? notes;
  final DateTime createdAt;

  // Nested relations (nullable — populated on detail views)
  final String? branchName;
  final List<VehicleDocumentEntity>? documents;
  final List<FuelLogEntity>? fuelLogs;
  final List<VehicleDriverEntity>? drivers;

  const VehicleEntity({
    required this.id,
    required this.branchId,
    required this.registrationNo,
    required this.make,
    required this.model,
    this.year,
    this.engineNo,
    this.chassisNo,
    required this.fuelType,
    required this.vehicleType,
    this.color,
    this.mileage = 0,
    this.status = 'ACTIVE',
    this.purchaseDate,
    this.purchasePrice,
    this.insuranceExpiry,
    this.licenseExpiry,
    this.lastServiceDate,
    this.nextServiceDate,
    this.nextServiceMileage,
    this.imageUrl,
    this.notes,
    required this.createdAt,
    this.branchName,
    this.documents,
    this.fuelLogs,
    this.drivers,
  });

  /// Human‑readable display name.
  String get displayName => '$make $model ($registrationNo)';

  /// Whether the vehicle insurance is expired or expiring within 30 days.
  bool get isInsuranceExpiring =>
      insuranceExpiry != null &&
      insuranceExpiry!.isBefore(DateTime.now().add(const Duration(days: 30)));

  /// Whether the licence is expired or expiring within 30 days.
  bool get isLicenseExpiring =>
      licenseExpiry != null &&
      licenseExpiry!.isBefore(DateTime.now().add(const Duration(days: 30)));

  @override
  List<Object?> get props => [
    id,
    branchId,
    registrationNo,
    make,
    model,
    year,
    engineNo,
    chassisNo,
    fuelType,
    vehicleType,
    color,
    mileage,
    status,
    purchaseDate,
    purchasePrice,
    insuranceExpiry,
    licenseExpiry,
    lastServiceDate,
    nextServiceDate,
    nextServiceMileage,
    imageUrl,
    notes,
    createdAt,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Vehicle Document Entity
// ═══════════════════════════════════════════════════════════════════════════

class VehicleDocumentEntity extends Equatable {
  final int id;
  final int vehicleId;
  final String type;
  final String documentNo;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String? provider;
  final double? amount;
  final String? fileUrl;
  final bool isActive;

  const VehicleDocumentEntity({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.documentNo,
    required this.issueDate,
    required this.expiryDate,
    this.provider,
    this.amount,
    this.fileUrl,
    this.isActive = true,
  });

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  bool get isExpiringSoon =>
      !isExpired &&
      expiryDate.isBefore(DateTime.now().add(const Duration(days: 30)));

  @override
  List<Object?> get props => [
    id,
    vehicleId,
    type,
    documentNo,
    issueDate,
    expiryDate,
    provider,
    amount,
    fileUrl,
    isActive,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Fuel Log Entity
// ═══════════════════════════════════════════════════════════════════════════

class FuelLogEntity extends Equatable {
  final int id;
  final int vehicleId;
  final DateTime date;
  final String fuelType;
  final double quantity;
  final double unitPrice;
  final double totalCost;
  final double mileage;
  final String? station;
  final String? receiptNo;

  const FuelLogEntity({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.fuelType,
    required this.quantity,
    required this.unitPrice,
    required this.totalCost,
    required this.mileage,
    this.station,
    this.receiptNo,
  });

  @override
  List<Object?> get props => [
    id,
    vehicleId,
    date,
    fuelType,
    quantity,
    unitPrice,
    totalCost,
    mileage,
    station,
    receiptNo,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Vehicle Driver Entity
// ═══════════════════════════════════════════════════════════════════════════

class VehicleDriverEntity extends Equatable {
  final int id;
  final int vehicleId;
  final int driverId;
  final DateTime assignedDate;
  final DateTime? releasedDate;
  final bool isActive;
  final String? driverName;

  const VehicleDriverEntity({
    required this.id,
    required this.vehicleId,
    required this.driverId,
    required this.assignedDate,
    this.releasedDate,
    this.isActive = true,
    this.driverName,
  });

  @override
  List<Object?> get props => [
    id,
    vehicleId,
    driverId,
    assignedDate,
    releasedDate,
    isActive,
    driverName,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Vehicle Cost Analytics
// ═══════════════════════════════════════════════════════════════════════════

class VehicleCostAnalytics extends Equatable {
  final VehicleEntity vehicle;
  final FuelCostSummary fuelCosts;
  final double serviceCosts;
  final double totalCost;

  const VehicleCostAnalytics({
    required this.vehicle,
    required this.fuelCosts,
    required this.serviceCosts,
    required this.totalCost,
  });

  @override
  List<Object?> get props => [vehicle, fuelCosts, serviceCosts, totalCost];
}

class FuelCostSummary extends Equatable {
  final double totalCost;
  final int entries;
  final double avgUnitPrice;

  const FuelCostSummary({
    required this.totalCost,
    required this.entries,
    required this.avgUnitPrice,
  });

  @override
  List<Object?> get props => [totalCost, entries, avgUnitPrice];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Service Reminder
// ═══════════════════════════════════════════════════════════════════════════

class ServiceReminder extends Equatable {
  final int vehicleId;
  final String registrationNo;
  final String type;
  final String message;
  final DateTime? dueDate;

  const ServiceReminder({
    required this.vehicleId,
    required this.registrationNo,
    required this.type,
    required this.message,
    this.dueDate,
  });

  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now());

  @override
  List<Object?> get props => [
    vehicleId,
    registrationNo,
    type,
    message,
    dueDate,
  ];
}
