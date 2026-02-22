import '../../domain/entities/vehicle_entity.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Vehicle Model
// ═══════════════════════════════════════════════════════════════════════════

class VehicleModel extends VehicleEntity {
  const VehicleModel({
    required super.id,
    required super.branchId,
    required super.registrationNo,
    required super.make,
    required super.model,
    super.year,
    super.engineNo,
    super.chassisNo,
    required super.fuelType,
    required super.vehicleType,
    super.color,
    super.mileage,
    super.status,
    super.purchaseDate,
    super.purchasePrice,
    super.insuranceExpiry,
    super.licenseExpiry,
    super.lastServiceDate,
    super.nextServiceDate,
    super.nextServiceMileage,
    super.imageUrl,
    super.notes,
    required super.createdAt,
    super.branchName,
    super.documents,
    super.fuelLogs,
    super.drivers,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as int,
      branchId: json['branchId'] as int? ?? 0,
      registrationNo: json['registrationNo'] as String? ?? '',
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as int?,
      engineNo: json['engineNo'] as String?,
      chassisNo: json['chassisNo'] as String?,
      fuelType: json['fuelType'] as String? ?? 'DIESEL',
      vehicleType: json['vehicleType'] as String? ?? '',
      color: json['color'] as String?,
      mileage: _toDouble(json['mileage']),
      status: json['status'] as String? ?? 'ACTIVE',
      purchaseDate: _tryParseDate(json['purchaseDate']),
      purchasePrice: _toNullableDouble(json['purchasePrice']),
      insuranceExpiry: _tryParseDate(json['insuranceExpiry']),
      licenseExpiry: _tryParseDate(json['licenseExpiry']),
      lastServiceDate: _tryParseDate(json['lastServiceDate']),
      nextServiceDate: _tryParseDate(json['nextServiceDate']),
      nextServiceMileage: _toNullableDouble(json['nextServiceMileage']),
      imageUrl: json['imageUrl'] as String?,
      notes: json['notes'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      branchName: json['branch'] is Map
          ? json['branch']['name'] as String?
          : null,
      documents: json['documents'] is List
          ? (json['documents'] as List)
                .map(
                  (e) =>
                      VehicleDocumentModel.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : null,
      fuelLogs: json['fuelLogs'] is List
          ? (json['fuelLogs'] as List)
                .map((e) => FuelLogModel.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      drivers: json['drivers'] is List
          ? (json['drivers'] as List)
                .map(
                  (e) => VehicleDriverModel.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'registrationNo': registrationNo,
      'make': make,
      'model': model,
      if (year != null) 'year': year,
      if (engineNo != null) 'engineNo': engineNo,
      if (chassisNo != null) 'chassisNo': chassisNo,
      'fuelType': fuelType,
      'vehicleType': vehicleType,
      if (color != null) 'color': color,
      'mileage': mileage,
      'status': status,
      if (purchaseDate != null) 'purchaseDate': purchaseDate!.toIso8601String(),
      if (purchasePrice != null) 'purchasePrice': purchasePrice,
      if (insuranceExpiry != null)
        'insuranceExpiry': insuranceExpiry!.toIso8601String(),
      if (licenseExpiry != null)
        'licenseExpiry': licenseExpiry!.toIso8601String(),
      if (lastServiceDate != null)
        'lastServiceDate': lastServiceDate!.toIso8601String(),
      if (nextServiceDate != null)
        'nextServiceDate': nextServiceDate!.toIso8601String(),
      if (nextServiceMileage != null) 'nextServiceMileage': nextServiceMileage,
      if (imageUrl != null) 'imageUrl': imageUrl,
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
//  Vehicle Document Model
// ═══════════════════════════════════════════════════════════════════════════

class VehicleDocumentModel extends VehicleDocumentEntity {
  const VehicleDocumentModel({
    required super.id,
    required super.vehicleId,
    required super.type,
    required super.documentNo,
    required super.issueDate,
    required super.expiryDate,
    super.provider,
    super.amount,
    super.fileUrl,
    super.isActive,
  });

  factory VehicleDocumentModel.fromJson(Map<String, dynamic> json) {
    return VehicleDocumentModel(
      id: json['id'] as int,
      vehicleId: json['vehicleId'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      documentNo: json['documentNo'] as String? ?? '',
      issueDate:
          DateTime.tryParse(json['issueDate']?.toString() ?? '') ??
          DateTime.now(),
      expiryDate:
          DateTime.tryParse(json['expiryDate']?.toString() ?? '') ??
          DateTime.now(),
      provider: json['provider'] as String?,
      amount: VehicleModel._toNullableDouble(json['amount']),
      fileUrl: json['fileUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'type': type,
      'documentNo': documentNo,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      if (provider != null) 'provider': provider,
      if (amount != null) 'amount': amount,
      if (fileUrl != null) 'fileUrl': fileUrl,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Fuel Log Model
// ═══════════════════════════════════════════════════════════════════════════

class FuelLogModel extends FuelLogEntity {
  const FuelLogModel({
    required super.id,
    required super.vehicleId,
    required super.date,
    required super.fuelType,
    required super.quantity,
    required super.unitPrice,
    required super.totalCost,
    required super.mileage,
    super.station,
    super.receiptNo,
  });

  factory FuelLogModel.fromJson(Map<String, dynamic> json) {
    return FuelLogModel(
      id: json['id'] as int,
      vehicleId: json['vehicleId'] as int? ?? 0,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      fuelType: json['fuelType'] as String? ?? 'DIESEL',
      quantity: VehicleModel._toDouble(json['quantity']),
      unitPrice: VehicleModel._toDouble(json['unitPrice']),
      totalCost: VehicleModel._toDouble(json['totalCost']),
      mileage: VehicleModel._toDouble(json['mileage']),
      station: json['station'] as String?,
      receiptNo: json['receiptNo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'fuelType': fuelType,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalCost': totalCost,
      'mileage': mileage,
      if (station != null) 'station': station,
      if (receiptNo != null) 'receiptNo': receiptNo,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Vehicle Driver Model
// ═══════════════════════════════════════════════════════════════════════════

class VehicleDriverModel extends VehicleDriverEntity {
  const VehicleDriverModel({
    required super.id,
    required super.vehicleId,
    required super.driverId,
    required super.assignedDate,
    super.releasedDate,
    super.isActive,
    super.driverName,
  });

  factory VehicleDriverModel.fromJson(Map<String, dynamic> json) {
    // Driver name comes from the nested `driver` relation or top‑level field.
    String? name = json['driverName'] as String?;
    if (name == null && json['driver'] is Map) {
      final d = json['driver'] as Map<String, dynamic>;
      final fn = d['firstName'] ?? '';
      final ln = d['lastName'] ?? '';
      name = '$fn $ln'.trim();
      if (name.isEmpty) name = null;
    }

    return VehicleDriverModel(
      id: json['id'] as int,
      vehicleId: json['vehicleId'] as int? ?? 0,
      driverId: json['driverId'] as int? ?? 0,
      assignedDate:
          DateTime.tryParse(json['assignedDate']?.toString() ?? '') ??
          DateTime.now(),
      releasedDate: json['releasedDate'] != null
          ? DateTime.tryParse(json['releasedDate'].toString())
          : null,
      isActive: json['isActive'] as bool? ?? true,
      driverName: name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'driverId': driverId,
      'assignedDate': assignedDate.toIso8601String(),
      if (releasedDate != null) 'releasedDate': releasedDate!.toIso8601String(),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Cost Analytics Model
// ═══════════════════════════════════════════════════════════════════════════

class VehicleCostAnalyticsModel extends VehicleCostAnalytics {
  const VehicleCostAnalyticsModel({
    required super.vehicle,
    required super.fuelCosts,
    required super.serviceCosts,
    required super.totalCost,
  });

  factory VehicleCostAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final vehicleJson =
        json['vehicle'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final fuelJson =
        json['fuelCosts'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return VehicleCostAnalyticsModel(
      vehicle: VehicleModel.fromJson(vehicleJson),
      fuelCosts: FuelCostSummaryModel.fromJson(fuelJson),
      serviceCosts: VehicleModel._toDouble(json['serviceCosts']),
      totalCost: VehicleModel._toDouble(json['totalCost']),
    );
  }
}

class FuelCostSummaryModel extends FuelCostSummary {
  const FuelCostSummaryModel({
    required super.totalCost,
    required super.entries,
    required super.avgUnitPrice,
  });

  factory FuelCostSummaryModel.fromJson(Map<String, dynamic> json) {
    return FuelCostSummaryModel(
      totalCost: VehicleModel._toDouble(json['totalCost']),
      entries: json['entries'] as int? ?? 0,
      avgUnitPrice: VehicleModel._toDouble(json['avgUnitPrice']),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Service Reminder Model
// ═══════════════════════════════════════════════════════════════════════════

class ServiceReminderModel extends ServiceReminder {
  const ServiceReminderModel({
    required super.vehicleId,
    required super.registrationNo,
    required super.type,
    required super.message,
    super.dueDate,
  });

  factory ServiceReminderModel.fromJson(Map<String, dynamic> json) {
    return ServiceReminderModel(
      vehicleId: json['vehicleId'] as int? ?? 0,
      registrationNo: json['registrationNo'] as String? ?? '',
      type: json['type'] as String? ?? '',
      message: json['message'] as String? ?? '',
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'].toString())
          : null,
    );
  }
}
