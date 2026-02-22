import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Service Request Entity
// ═══════════════════════════════════════════════════════════════════════════

/// Enumerates service request types.
enum ServiceType { Repair, Maintenance, Inspection, Emergency }

/// Enumerates service request priority levels.
enum ServicePriority { Critical, High, Medium, Low }

/// Enumerates service request statuses.
enum ServiceStatus {
  Pending,
  Approved,
  InProgress,
  OnHold,
  Completed,
  Rejected,
  Cancelled,
}

class ServiceRequestEntity extends Equatable {
  final int id;
  final String requestNo;
  final int branchId;
  final int requestedById;
  final int? assignedToId;
  final int? vehicleId;
  final int? machineId;
  final String type;
  final String priority;
  final String status;
  final String title;
  final String description;
  final double? estimatedCost;
  final double? actualCost;
  final DateTime? estimatedCompletionDate;
  final DateTime? actualCompletionDate;
  final DateTime? slaDeadline;
  final int? approvedById;
  final DateTime? approvedDate;
  final String? rejectionReason;
  final String? completionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nested relations (populated on detail views)
  final String? requestedByName;
  final String? assignedToName;
  final String? vehicleName;
  final String? machineName;
  final List<ServiceTaskEntity>? tasks;
  final List<ServiceSparePartEntity>? spareParts;

  const ServiceRequestEntity({
    required this.id,
    required this.requestNo,
    required this.branchId,
    required this.requestedById,
    this.assignedToId,
    this.vehicleId,
    this.machineId,
    required this.type,
    required this.priority,
    this.status = 'Pending',
    required this.title,
    required this.description,
    this.estimatedCost,
    this.actualCost,
    this.estimatedCompletionDate,
    this.actualCompletionDate,
    this.slaDeadline,
    this.approvedById,
    this.approvedDate,
    this.rejectionReason,
    this.completionNotes,
    required this.createdAt,
    required this.updatedAt,
    this.requestedByName,
    this.assignedToName,
    this.vehicleName,
    this.machineName,
    this.tasks,
    this.spareParts,
  });

  /// Human-readable display for the service request.
  String get displayTitle => '$requestNo – $title';

  /// Whether this request has breached its SLA deadline.
  bool get isSLABreached =>
      slaDeadline != null &&
      status != 'Completed' &&
      status != 'Cancelled' &&
      slaDeadline!.isBefore(DateTime.now());

  /// Remaining SLA duration (negative if breached).
  Duration? get slaRemaining => slaDeadline?.difference(DateTime.now());

  /// Task completion ratio (0.0 – 1.0).
  double get taskProgress {
    if (tasks == null || tasks!.isEmpty) return 0;
    final completed = tasks!.where((t) => t.status == 'Completed').length;
    return completed / tasks!.length;
  }

  /// Total spare parts cost.
  double get totalSparePartsCost {
    if (spareParts == null || spareParts!.isEmpty) return 0;
    return spareParts!.fold(0.0, (sum, p) => sum + (p.totalPrice ?? 0));
  }

  @override
  List<Object?> get props => [
        id,
        requestNo,
        branchId,
        requestedById,
        assignedToId,
        vehicleId,
        machineId,
        type,
        priority,
        status,
        title,
        description,
        estimatedCost,
        actualCost,
        estimatedCompletionDate,
        actualCompletionDate,
        slaDeadline,
        approvedById,
        approvedDate,
        rejectionReason,
        completionNotes,
        createdAt,
        updatedAt,
      ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Service Task Entity
// ═══════════════════════════════════════════════════════════════════════════

class ServiceTaskEntity extends Equatable {
  final int id;
  final int serviceRequestId;
  final String title;
  final String? description;
  final int? assignedToId;
  final String status; // Pending, InProgress, Completed
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double? estimatedHours;
  final double? actualHours;
  final String? notes;
  final String? assignedToName;

  const ServiceTaskEntity({
    required this.id,
    required this.serviceRequestId,
    required this.title,
    this.description,
    this.assignedToId,
    this.status = 'Pending',
    this.startedAt,
    this.completedAt,
    this.estimatedHours,
    this.actualHours,
    this.notes,
    this.assignedToName,
  });

  bool get isCompleted => status == 'Completed';
  bool get isInProgress => status == 'InProgress';

  @override
  List<Object?> get props => [
        id,
        serviceRequestId,
        title,
        description,
        assignedToId,
        status,
        startedAt,
        completedAt,
        estimatedHours,
        actualHours,
        notes,
        assignedToName,
      ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Service Spare Part Entity
// ═══════════════════════════════════════════════════════════════════════════

class ServiceSparePartEntity extends Equatable {
  final int id;
  final int serviceRequestId;
  final int productId;
  final int quantity;
  final double? unitPrice;
  final double? totalPrice;
  final String status; // Requested, Approved, Issued, Returned
  final String? productName;
  final String? productCode;

  const ServiceSparePartEntity({
    required this.id,
    required this.serviceRequestId,
    required this.productId,
    required this.quantity,
    this.unitPrice,
    this.totalPrice,
    this.status = 'Requested',
    this.productName,
    this.productCode,
  });

  @override
  List<Object?> get props => [
        id,
        serviceRequestId,
        productId,
        quantity,
        unitPrice,
        totalPrice,
        status,
        productName,
        productCode,
      ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Service SLA Metrics
// ═══════════════════════════════════════════════════════════════════════════

class ServiceSLAMetrics extends Equatable {
  final int totalRequests;
  final int withinSLA;
  final int breachedSLA;
  final double avgResolutionHours;
  final int pendingCount;
  final int criticalCount;

  const ServiceSLAMetrics({
    this.totalRequests = 0,
    this.withinSLA = 0,
    this.breachedSLA = 0,
    this.avgResolutionHours = 0,
    this.pendingCount = 0,
    this.criticalCount = 0,
  });

  double get slaComplianceRate =>
      totalRequests > 0 ? (withinSLA / totalRequests) * 100 : 0;

  @override
  List<Object?> get props => [
        totalRequests,
        withinSLA,
        breachedSLA,
        avgResolutionHours,
        pendingCount,
        criticalCount,
      ];
}
