import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/machine_entity.dart';
import '../providers/machine_provider.dart';

/// Create / Edit form for a machine. Pass a [MachineEntity] via GoRouter extra
/// for editing mode; omit for creation mode.
class MachineFormScreen extends ConsumerStatefulWidget {
  final MachineEntity? existingMachine;

  const MachineFormScreen({super.key, this.existingMachine});

  @override
  ConsumerState<MachineFormScreen> createState() => _MachineFormScreenState();
}

class _MachineFormScreenState extends ConsumerState<MachineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final bool _isEditing;

  // Controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _manufacturerCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _serialNumberCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _operatingHoursCtrl;
  late final TextEditingController _purchasePriceCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _conditionCtrl;

  String _selectedStatus = 'ACTIVE';
  String _selectedType = 'Production';
  int _selectedBranchId = 1;
  DateTime? _purchaseDate;
  DateTime? _nextMaintenanceDate;

  static const _statusOptions = [
    'ACTIVE',
    'UNDER_MAINTENANCE',
    'DECOMMISSIONED',
    'IDLE',
  ];

  static const _typeOptions = [
    'Production',
    'Packaging',
    'Processing',
    'Utility',
    'Transport',
    'Quality Control',
  ];

  static const _branchOptions = <int, String>{
    1: 'Head Office',
    2: 'Factory Branch',
  };

  @override
  void initState() {
    super.initState();
    final m = widget.existingMachine;
    _isEditing = m != null;

    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _codeCtrl = TextEditingController(text: m?.code ?? '');
    _manufacturerCtrl = TextEditingController(text: m?.manufacturer ?? '');
    _modelCtrl = TextEditingController(text: m?.model ?? '');
    _serialNumberCtrl = TextEditingController(text: m?.serialNumber ?? '');
    _locationCtrl = TextEditingController(text: m?.location ?? '');
    _operatingHoursCtrl = TextEditingController(
      text: m != null ? m.operatingHours.toString() : '',
    );
    _purchasePriceCtrl = TextEditingController(
      text: m?.purchasePrice?.toString() ?? '',
    );
    _notesCtrl = TextEditingController(text: m?.notes ?? '');
    _conditionCtrl = TextEditingController(text: m?.condition ?? '');

    if (m != null) {
      _selectedStatus = m.status;
      _selectedType = m.type;
      _selectedBranchId = m.branchId;
      _purchaseDate = m.purchaseDate;
      _nextMaintenanceDate = m.nextMaintenanceDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _manufacturerCtrl.dispose();
    _modelCtrl.dispose();
    _serialNumberCtrl.dispose();
    _locationCtrl.dispose();
    _operatingHoursCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _notesCtrl.dispose();
    _conditionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'branchId': _selectedBranchId,
      'name': _nameCtrl.text.trim(),
      'code': _codeCtrl.text.trim(),
      'type': _selectedType,
      'status': _selectedStatus,
      if (_manufacturerCtrl.text.isNotEmpty)
        'manufacturer': _manufacturerCtrl.text.trim(),
      if (_modelCtrl.text.isNotEmpty) 'model': _modelCtrl.text.trim(),
      if (_serialNumberCtrl.text.isNotEmpty)
        'serialNumber': _serialNumberCtrl.text.trim(),
      if (_locationCtrl.text.isNotEmpty) 'location': _locationCtrl.text.trim(),
      if (_operatingHoursCtrl.text.isNotEmpty)
        'operatingHours': double.tryParse(_operatingHoursCtrl.text) ?? 0,
      if (_purchasePriceCtrl.text.isNotEmpty)
        'purchasePrice': double.tryParse(_purchasePriceCtrl.text),
      if (_purchaseDate != null)
        'purchaseDate': _purchaseDate!.toIso8601String(),
      if (_nextMaintenanceDate != null)
        'nextMaintenanceDate': _nextMaintenanceDate!.toIso8601String(),
      if (_conditionCtrl.text.isNotEmpty)
        'condition': _conditionCtrl.text.trim(),
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };

    final notifier = ref.read(machineFormProvider.notifier);
    bool success;

    if (_isEditing) {
      success = await notifier.updateMachine(widget.existingMachine!.id, data);
    } else {
      success = await notifier.createMachine(data);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Machine updated successfully'
                : 'Machine created successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(machineFormProvider);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Machine' : 'Add Machine'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Error Banner ──────────────────────────────────────────
            if (formState.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formState.errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Basic Info ────────────────────────────────────────────
            _sectionLabel('Basic Information'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameCtrl,
              decoration: _inputDecoration('Machine Name *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _codeCtrl,
              decoration: _inputDecoration('Machine Code *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Code is required' : null,
            ),
            const SizedBox(height: 16),

            // Status dropdown
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: _inputDecoration('Status'),
              items: _statusOptions
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.replaceAll('_', ' ')),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedStatus = v);
              },
            ),
            const SizedBox(height: 16),

            // Type dropdown
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: _inputDecoration('Type / Category'),
              items: _typeOptions
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedType = v);
              },
            ),
            const SizedBox(height: 16),

            // Branch dropdown
            DropdownButtonFormField<int>(
              value: _selectedBranchId,
              decoration: _inputDecoration('Branch *'),
              items: _branchOptions.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              validator: (v) => v == null ? 'Branch is required' : null,
              onChanged: (v) {
                if (v != null) setState(() => _selectedBranchId = v);
              },
            ),
            const SizedBox(height: 24),

            // ── Manufacturer Details ──────────────────────────────────
            _sectionLabel('Manufacturer Details'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _manufacturerCtrl,
              decoration: _inputDecoration('Manufacturer'),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _modelCtrl,
              decoration: _inputDecoration('Model'),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _serialNumberCtrl,
              decoration: _inputDecoration('Serial Number'),
            ),
            const SizedBox(height: 24),

            // ── Location & Operating ──────────────────────────────────
            _sectionLabel('Location & Operating'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _locationCtrl,
              decoration: _inputDecoration('Location'),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _operatingHoursCtrl,
              decoration: _inputDecoration('Operating Hours'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _conditionCtrl,
              decoration: _inputDecoration('Condition'),
            ),
            const SizedBox(height: 24),

            // ── Purchase Details ──────────────────────────────────────
            _sectionLabel('Purchase Details'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _purchasePriceCtrl,
              decoration: _inputDecoration('Purchase Price (LKR)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),

            // Purchase date picker
            InkWell(
              onTap: () => _pickDate(
                initial: _purchaseDate,
                onPicked: (d) => _purchaseDate = d,
              ),
              child: InputDecorator(
                decoration: _inputDecoration('Purchase Date'),
                child: Text(
                  _purchaseDate != null
                      ? dateFmt.format(_purchaseDate!)
                      : 'Select date',
                  style: TextStyle(
                    color: _purchaseDate != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Next maintenance date picker
            InkWell(
              onTap: () => _pickDate(
                initial: _nextMaintenanceDate,
                onPicked: (d) => _nextMaintenanceDate = d,
              ),
              child: InputDecorator(
                decoration: _inputDecoration('Next Maintenance Date'),
                child: Text(
                  _nextMaintenanceDate != null
                      ? dateFmt.format(_nextMaintenanceDate!)
                      : 'Select date',
                  style: TextStyle(
                    color: _nextMaintenanceDate != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Notes ────────────────────────────────────────────────
            _sectionLabel('Additional Notes'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _notesCtrl,
              decoration: _inputDecoration('Notes'),
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            // ── Submit Button ────────────────────────────────────────
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: formState.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: formState.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update Machine' : 'Create Machine',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
