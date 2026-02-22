import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/service_entity.dart';
import '../providers/service_provider.dart';

/// Create / Edit service request form screen.
///
/// Pass an existing [ServiceRequestEntity] via GoRouter `extra` to enable
/// edit mode.
class ServiceFormScreen extends ConsumerStatefulWidget {
  final ServiceRequestEntity? serviceRequest;

  const ServiceFormScreen({super.key, this.serviceRequest});

  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEditMode;

  // Controllers
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _estimatedCostCtrl;
  late final TextEditingController _branchIdCtrl;
  late final TextEditingController _requestedByIdCtrl;
  late final TextEditingController _assignedToIdCtrl;
  late final TextEditingController _vehicleIdCtrl;
  late final TextEditingController _machineIdCtrl;

  // Dropdowns
  String _type = 'Repair';
  String _priority = 'Medium';

  // Dates
  DateTime? _estimatedCompletionDate;

  static const _typeOptions = [
    'Repair',
    'Maintenance',
    'Inspection',
    'Emergency',
  ];
  static const _priorityOptions = ['Critical', 'High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    final s = widget.serviceRequest;
    _isEditMode = s != null;

    _titleCtrl = TextEditingController(text: s?.title ?? '');
    _descriptionCtrl = TextEditingController(text: s?.description ?? '');
    _estimatedCostCtrl = TextEditingController(
      text: s?.estimatedCost?.toStringAsFixed(2) ?? '',
    );
    _branchIdCtrl = TextEditingController(text: s?.branchId.toString() ?? '1');
    _requestedByIdCtrl = TextEditingController(
      text: s?.requestedById.toString() ?? '',
    );
    _assignedToIdCtrl = TextEditingController(
      text: s?.assignedToId?.toString() ?? '',
    );
    _vehicleIdCtrl = TextEditingController(
      text: s?.vehicleId?.toString() ?? '',
    );
    _machineIdCtrl = TextEditingController(
      text: s?.machineId?.toString() ?? '',
    );

    _type = s?.type ?? 'Repair';
    _priority = s?.priority ?? 'Medium';
    _estimatedCompletionDate = s?.estimatedCompletionDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _estimatedCostCtrl.dispose();
    _branchIdCtrl.dispose();
    _requestedByIdCtrl.dispose();
    _assignedToIdCtrl.dispose();
    _vehicleIdCtrl.dispose();
    _machineIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _estimatedCompletionDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _estimatedCompletionDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'type': _type,
      'priority': _priority,
      'branchId': int.tryParse(_branchIdCtrl.text) ?? 1,
      if (_requestedByIdCtrl.text.isNotEmpty)
        'requestedById': int.tryParse(_requestedByIdCtrl.text),
      if (_assignedToIdCtrl.text.isNotEmpty)
        'assignedToId': int.tryParse(_assignedToIdCtrl.text),
      if (_vehicleIdCtrl.text.isNotEmpty)
        'vehicleId': int.tryParse(_vehicleIdCtrl.text),
      if (_machineIdCtrl.text.isNotEmpty)
        'machineId': int.tryParse(_machineIdCtrl.text),
      if (_estimatedCostCtrl.text.isNotEmpty)
        'estimatedCost': double.tryParse(_estimatedCostCtrl.text),
      if (_estimatedCompletionDate != null)
        'estimatedCompletionDate': _estimatedCompletionDate!.toIso8601String(),
    };

    final notifier = ref.read(serviceFormProvider.notifier);
    bool success;

    if (_isEditMode) {
      success = await notifier.updateServiceRequest(
        widget.serviceRequest!.id,
        data,
      );
    } else {
      success = await notifier.createServiceRequest(data);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Service request updated successfully'
                : 'Service request created successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (mounted) {
      final errorMsg = ref.read(serviceFormProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'Something went wrong'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(serviceFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Service Request' : 'New Service Request',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Type Selector ───────────────────────────────────────────
            Text(
              'Service Type',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _buildTypeSelector(),
            const SizedBox(height: 20),

            // ── Priority Selector ───────────────────────────────────────
            Text(
              'Priority',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _buildPrioritySelector(),
            const SizedBox(height: 20),

            // ── Title ───────────────────────────────────────────────────
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'Brief title for the service request',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // ── Description ─────────────────────────────────────────────
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Detailed description of the issue or request…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 16),

            // ── Vehicle ID ──────────────────────────────────────────────
            TextFormField(
              controller: _vehicleIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Vehicle ID (optional)',
                hintText: 'Enter vehicle ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_car_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // ── Machine ID ──────────────────────────────────────────────
            TextFormField(
              controller: _machineIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Machine ID (optional)',
                hintText: 'Enter machine ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.precision_manufacturing_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // ── Estimated Cost ──────────────────────────────────────────
            TextFormField(
              controller: _estimatedCostCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Estimated Cost',
                hintText: '0.00',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                prefixText: 'Rs ',
              ),
            ),
            const SizedBox(height: 16),

            // ── Estimated Completion Date ────────────────────────────────
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Estimated Completion Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _estimatedCompletionDate != null
                      ? DateFormat(
                          'dd MMM yyyy',
                        ).format(_estimatedCompletionDate!)
                      : 'Select date',
                  style: TextStyle(
                    color: _estimatedCompletionDate != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Assign To ───────────────────────────────────────────────
            TextFormField(
              controller: _assignedToIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Assign To (User ID)',
                hintText: 'Enter technician user ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            // ── Branch ID ───────────────────────────────────────────────
            TextFormField(
              controller: _branchIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Branch ID *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Branch ID is required'
                  : null,
            ),
            const SizedBox(height: 32),

            // ── Submit Button ───────────────────────────────────────────
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: formState.isLoading ? null : _submit,
                icon: formState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_isEditMode ? Icons.save : Icons.send),
                label: Text(
                  _isEditMode ? 'Update Request' : 'Submit Request',
                  style: const TextStyle(fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Type Selector ───────────────────────────────────────────────────────

  Widget _buildTypeSelector() {
    final icons = {
      'Repair': Icons.build,
      'Maintenance': Icons.handyman,
      'Inspection': Icons.search,
      'Emergency': Icons.warning_amber_rounded,
    };
    final colors = {
      'Repair': AppColors.info,
      'Maintenance': AppColors.secondary,
      'Inspection': AppColors.primary,
      'Emergency': AppColors.error,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _typeOptions.map((t) {
        final selected = _type == t;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icons[t],
                size: 16,
                color: selected ? Colors.white : colors[t],
              ),
              const SizedBox(width: 6),
              Text(t),
            ],
          ),
          selected: selected,
          selectedColor: colors[t],
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          onSelected: (val) {
            if (val) setState(() => _type = t);
          },
        );
      }).toList(),
    );
  }

  // ── Priority Selector ──────────────────────────────────────────────────

  Widget _buildPrioritySelector() {
    final colors = {
      'Critical': AppColors.error,
      'High': const Color(0xFFE67E22),
      'Medium': AppColors.warning,
      'Low': AppColors.info,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _priorityOptions.map((p) {
        final selected = _priority == p;
        return ChoiceChip(
          label: Text(p),
          selected: selected,
          selectedColor: colors[p],
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          avatar: selected
              ? null
              : CircleAvatar(
                  backgroundColor: colors[p]!.withOpacity(0.2),
                  radius: 6,
                  child: CircleAvatar(backgroundColor: colors[p], radius: 4),
                ),
          onSelected: (val) {
            if (val) setState(() => _priority = p);
          },
        );
      }).toList(),
    );
  }
}
