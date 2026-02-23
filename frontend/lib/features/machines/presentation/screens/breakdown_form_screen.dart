import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/machine_entity.dart';
import '../providers/machine_provider.dart';

/// Form for reporting a machine breakdown.
/// If [machineId] / [machineName] are provided, the machine is pre‑selected.
class BreakdownFormScreen extends ConsumerStatefulWidget {
  final int? machineId;
  final String? machineName;

  const BreakdownFormScreen({super.key, this.machineId, this.machineName});

  @override
  ConsumerState<BreakdownFormScreen> createState() =>
      _BreakdownFormScreenState();
}

class _BreakdownFormScreenState extends ConsumerState<BreakdownFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descCtrl;
  late final TextEditingController _reportedByCtrl;
  late final TextEditingController _rootCauseCtrl;
  late final TextEditingController _actionTakenCtrl;
  late final TextEditingController _downtimeCtrl;
  late final TextEditingController _costCtrl;

  String _selectedSeverity = 'Medium';
  DateTime _reportedDate = DateTime.now();

  // Placeholder for machine selection (use pre-selected if provided)
  int? _machineId;
  String? _machineName;

  final List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  static const _severityOptions = ['Critical', 'High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _machineId = widget.machineId;
    _machineName = widget.machineName;

    _descCtrl = TextEditingController();
    _reportedByCtrl = TextEditingController();
    _rootCauseCtrl = TextEditingController();
    _actionTakenCtrl = TextEditingController();
    _downtimeCtrl = TextEditingController();
    _costCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _reportedByCtrl.dispose();
    _rootCauseCtrl.dispose();
    _actionTakenCtrl.dispose();
    _downtimeCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReportedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reportedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _reportedDate = picked);
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return AppColors.error;
      case 'High':
        return Colors.deepOrange;
      case 'Medium':
        return AppColors.warning;
      case 'Low':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_machineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a machine'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final data = <String, dynamic>{
      'machineId': _machineId,
      'description': _descCtrl.text.trim(),
      'severity': _selectedSeverity.toUpperCase(),
      'reportedDate': _reportedDate.toIso8601String(),
      'status': 'REPORTED',
      if (_reportedByCtrl.text.isNotEmpty)
        'reportedBy': _reportedByCtrl.text.trim(),
      if (_rootCauseCtrl.text.isNotEmpty)
        'rootCause': _rootCauseCtrl.text.trim(),
      if (_actionTakenCtrl.text.isNotEmpty)
        'actionTaken': _actionTakenCtrl.text.trim(),
      if (_downtimeCtrl.text.isNotEmpty)
        'downtimeHours': double.tryParse(_downtimeCtrl.text),
      if (_costCtrl.text.isNotEmpty) 'cost': double.tryParse(_costCtrl.text),
    };

    final notifier = ref.read(machineFormProvider.notifier);
    final success = await notifier.createBreakdownLog(data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Breakdown reported successfully'),
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
        title: const Text('Report Breakdown'),
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

            // ── Machine selector ──────────────────────────────────────
            _sectionLabel('Machine'),
            const SizedBox(height: 12),

            if (_machineName != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.precision_manufacturing,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _machineName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 18,
                    ),
                  ],
                ),
              )
            else
              // Machine selector (when not pre-selected)
              InkWell(
                onTap: () => _showMachinePickerDialog(),
                child: InputDecorator(
                  decoration: _inputDecoration('Select Machine *'),
                  child: Text(
                    'Tap to select a machine',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // ── Breakdown Details ─────────────────────────────────────
            _sectionLabel('Breakdown Details'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descCtrl,
              decoration: _inputDecoration('Description *'),
              maxLines: 4,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 16),

            // Severity dropdown
            DropdownButtonFormField<String>(
              value: _selectedSeverity,
              decoration: _inputDecoration('Severity'),
              items: _severityOptions.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _severityColor(s),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(s),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedSeverity = v);
              },
            ),
            const SizedBox(height: 16),

            // Reported date picker
            InkWell(
              onTap: _pickReportedDate,
              child: InputDecorator(
                decoration: _inputDecoration('Reported Date'),
                child: Text(
                  dateFmt.format(_reportedDate),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _reportedByCtrl,
              decoration: _inputDecoration('Reported By'),
            ),
            const SizedBox(height: 24),

            // ── Root Cause & Action ───────────────────────────────────
            _sectionLabel('Analysis (Optional)'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _rootCauseCtrl,
              decoration: _inputDecoration('Root Cause'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _actionTakenCtrl,
              decoration: _inputDecoration('Action Taken'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _downtimeCtrl,
                    decoration: _inputDecoration('Downtime (hrs)'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _costCtrl,
                    decoration: _inputDecoration('Cost (LKR)'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Photo Upload ──────────────────────────────────────────
            _sectionLabel('Attachments'),
            const SizedBox(height: 12),

            // Selected images preview
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_selectedImages[i].path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedImages.removeAt(i));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Add photo button
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.border,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.surface,
              ),
              child: InkWell(
                onTap: _pickImages,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 36,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedImages.isEmpty
                          ? 'Tap to attach photos'
                          : 'Tap to add more photos (${_selectedImages.length} selected)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit Button ────────────────────────────────────────
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: formState.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
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
                    : const Text(
                        'Report Breakdown',
                        style: TextStyle(
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

  Future<void> _pickImages() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    if (source == ImageSource.gallery) {
      final images = await _imagePicker.pickMultiImage(imageQuality: 80);
      if (images.isNotEmpty) {
        setState(() => _selectedImages.addAll(images));
      }
    } else {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() => _selectedImages.add(image));
      }
    }
  }

  void _showMachinePickerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _MachinePickerDialog(
        onSelected: (machine) {
          setState(() {
            _machineId = machine.id;
            _machineName = machine.name;
          });
        },
      ),
    );
  }

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

// ═══════════════════════════════════════════════════════════════════════════
//  Machine Picker Dialog
// ═══════════════════════════════════════════════════════════════════════════

class _MachinePickerDialog extends ConsumerStatefulWidget {
  final ValueChanged<MachineEntity> onSelected;

  const _MachinePickerDialog({required this.onSelected});

  @override
  ConsumerState<_MachinePickerDialog> createState() =>
      _MachinePickerDialogState();
}

class _MachinePickerDialogState extends ConsumerState<_MachinePickerDialog> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final params = MachineListParams(
      limit: 50,
      search: _search.isNotEmpty ? _search : null,
      status: 'ACTIVE',
    );
    final machinesAsync = ref.watch(machineListProvider(params));

    return AlertDialog(
      title: const Text('Select Machine'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search machines...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: machinesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text('Error: $err',
                      style: const TextStyle(color: AppColors.error)),
                ),
                data: (machines) {
                  if (machines.isEmpty) {
                    return const Center(child: Text('No machines found'));
                  }
                  return ListView.separated(
                    itemCount: machines.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final m = machines[i];
                      return ListTile(
                        leading: const Icon(Icons.precision_manufacturing,
                            color: AppColors.primary),
                        title: Text(m.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(m.code),
                        dense: true,
                        onTap: () {
                          widget.onSelected(m);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
