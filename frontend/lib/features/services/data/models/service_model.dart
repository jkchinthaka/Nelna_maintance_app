import '../../domain/entities/service_entity.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Service Request Model
// ═══════════════════════════════════════════════════════════════════════════

class ServiceRequestModel extends ServiceRequestEntity {
  const ServiceRequestModel({
    required super.id,
    required super.requestNo,
    required super.branchId,
    required super.requestedById,
    super.assignedToId,
    super.vehicleId,
    super.machineId,
    required super.type,
    required super.priority,
    super.status,
    required super.title,
    required super.description,
    super.estimatedCost,
    super.actualCost,
    super.estimatedCompletionDate,
    super.actualCompletionDate,
    super.slaDeadline,
    super.approvedById,
    super.approvedDate,
    super.rejectionReason,
    super.completionNotes,
    required super.createdAt,
    required super.updatedAt,
    super.requestedByName,
    super.assignedToName,
    super.vehicleName,
    super.machineName,
    super.tasks,
    super.spareParts,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id: json['id'] as int,
      requestNo: json['requestNo'] as String? ?? '',
      branchId: json['branchId'] as int? ?? 0,
      requestedById: json['requestedById'] as int? ?? 0,
      assignedToId: json['assignedToId'] as int?,
      vehicleId: json['vehicleId'] as int?,
      machineId: json['machineId'] as int?,
      type: json['type'] as String? ?? 'Repair',
      priority: json['priority'] as String? ?? 'Medium',
      status: json['status'] as String? ?? 'Pending',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      estimatedCost: _toNullableDouble(json['estimatedCost']),
      actualCost: _toNullableDouble(json['actualCost']),
      estimatedCompletionDate: _tryParseDate(json['estimatedCompletionDate']),
      actualCompletionDate: _tryParseDate(json['actualCompletionDate']),
      slaDeadline: _tryParseDate(json['slaDeadline']),
      approvedById: json['approvedById'] as int?,
      approvedDate: _tryParseDate(json['approvedDate']),
      rejectionReason: json['rejectionReason'] as String?,
      completionNotes: json['completionNotes'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      requestedByName: _extractUserName(json['requestedBy']),
      assignedToName: _extractUserName(json['assignedTo']),
      vehicleName: json['vehicle'] is Map
          ? '${json['vehicle']['make'] ?? ''} ${json['vehicle']['model'] ?? ''} (${json['vehicle']['registrationNo'] ?? ''})'
              .trim()
          : null,
      machineName: json['machine'] is Map
          ? json['machine']['name'] as String?
          : null,
      tasks: json['tasks'] is List
          ? (json['tasks'] as List)
              .map((e) =>
                  ServiceTaskModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      spareParts: json['spareParts'] is List
          ? (json['spareParts'] as List)
              .map((e) =>
                  ServiceSparePartModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'requestedById': requestedById,
      if (assignedToId != null) 'assignedToId': assignedToId,
      if (vehicleId != null) 'vehicleId': vehicleId,
      if (machineId != null) 'machineId': machineId,
      'type': type,
      'priority': priority,
      'title': title,
      'description': description,
      if (estimatedCost != null) 'estimatedCost': estimatedCost,
      if (actualCost != null) 'actualCost': actualCost,
      if (estimatedCompletionDate != null)
        'estimatedCompletionDate':
            estimatedCompletionDate!.toIso8601String(),
      if (actualCompletionDate != null)
        'actualCompletionDate': actualCompletionDate!.toIso8601String(),
      if (slaDeadline != null) 'slaDeadline': slaDeadline!.toIso8601String(),
      if (completionNotes != null) 'completionNotes': completionNotes,
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

  static String? _extractUserName(dynamic user) {
    if (user is Map) {
      final first = user['firstName'] ?? user['name'] ?? '';
      final last = user['lastName'] ?? '';
      return '$first $last'.trim().isEmpty ? null : '$first $last'.trim();
    }
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Service Task Model
// ═══════════════════════════════════════════════════════════════════════════

class ServiceTaskModel extends ServiceTaskEntity {
  const ServiceTaskModel({
    required super.id,
    required super.serviceRequestId,
    required super.title,
    super.description,
    super.assignedToId,
    super.status,
    super.startedAt,
    super.completedAt,
    super.estimatedHours,
    super.actualHours,
    super.notes,
    super.assignedToName,
  });

  factory ServiceTaskModel.fromJson(Map<String, dynamic> json) {
    return ServiceTaskModel(
      id: json['id'] as int,
      serviceRequestId: json['serviceRequestId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      assignedToId: json['assignedToId'] as int?,
      status: json['status'] as String? ?? 'Pending',
      startedAt: _tryParseDate(json['startedAt']),
      completedAt: _tryParseDate(json['completedAt']),
      estimatedHours: _toNullableDouble(json['estimatedHours']),
      actualHours: _toNullableDouble(json['actualHours']),
      notes: json['notes'] as String?,
      assignedToName: json['assignedTo'] is Map
          ? '${json['assignedTo']['firstName'] ?? ''} ${json['assignedTo']['lastName'] ?? ''}'
              .trim()
          : json['assignedToName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceRequestId': serviceRequestId,
      'title': title,
      if (description != null) 'description': description,
      if (assignedToId != null) 'assignedToId': assignedToId,
      'status': status,
      if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (estimatedHours != null) 'estimatedHours': estimatedHours,
      if (actualHours != null) 'actualHours': actualHours,
      if (notes != null) 'notes': notes,
    };
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
//  Service Spare Part Model
// ═══════════════════════════════════════════════════════════════════════════

class ServiceSparePartModel extends ServiceSparePartEntity {
  const ServiceSparePartModel({
    required super.id,
    required super.serviceRequestId,
    required super.productId,
    required super.quantity,
    super.unitPrice,
    super.totalPrice,
    super.status,
    super.productName,
    super.productCode,
  });

  factory ServiceSparePartModel.fromJson(Map<String, dynamic> json) {
    return ServiceSparePartModel(
      id: json['id'] as int,
      serviceRequestId: json['serviceRequestId'] as int? ?? 0,
      productId: json['productId'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: _toNullableDouble(json['unitPrice']),
      totalPrice: _toNullableDouble(json['totalPrice']),
      status: json['status'] as String? ?? 'Requested',
      productName: json['product'] is Map
          ? json['product']['name'] as String?
          : json['productName'] as String?,
      productCode: json['product'] is Map
          ? json['product']['code'] as String?
          : json['productCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceRequestId': serviceRequestId,
      'productId': productId,
      'quantity': quantity,
      if (unitPrice != null) 'unitPrice': unitPrice,
      'status': status,
    };
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Service SLA Metrics Model
// ═══════════════════════════════════════════════════════════════════════════

class ServiceSLAMetricsModel extends ServiceSLAMetrics {
  const ServiceSLAMetricsModel({
    super.totalRequests,
    super.withinSLA,
    super.breachedSLA,
    super.avgResolutionHours,
    super.pendingCount,
    super.criticalCount,
  });

  factory ServiceSLAMetricsModel.fromJson(Map<String, dynamic> json) {
    return ServiceSLAMetricsModel(
      totalRequests: json['totalRequests'] as int? ?? 0,
      withinSLA: json['withinSLA'] as int? ?? 0,
      breachedSLA: json['breachedSLA'] as int? ?? 0,
      avgResolutionHours: _toDouble(json['avgResolutionHours']),
      pendingCount: json['pendingCount'] as int? ?? 0,
      criticalCount: json['criticalCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRequests': totalRequests,
      'withinSLA': withinSLA,
      'breachedSLA': breachedSLA,
      'avgResolutionHours': avgResolutionHours,
      'pendingCount': pendingCount,
      'criticalCount': criticalCount,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
