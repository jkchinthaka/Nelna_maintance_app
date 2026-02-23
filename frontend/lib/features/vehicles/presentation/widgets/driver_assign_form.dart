import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/vehicle_provider.dart';

/// Bottom-sheet form for assigning a driver to a vehicle.
class DriverAssignForm extends ConsumerStatefulWidget {
  final int vehicleId;
  final VoidCallback? onSaved;

  const DriverAssignForm({
    super.key,
    required this.vehicleId,
    this.onSaved,
  });

  @override
  ConsumerState<DriverAssignForm> createState() => _DriverAssignFormState();
}

class _DriverAssignFormState extends ConsumerState<DriverAssignForm> {
  final _formKey = GlobalKey<FormState>();

  final _driverIdCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _assignedDate = DateTime.now();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _driverIdCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _assignedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Select Assignment Date',
    );
    if (picked != null) {
      setState(() => _assignedDate = picked);
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final data = {
      'vehicleId': widget.vehicleId,
      'driverId': int.tryParse(_driverIdCtrl.text.trim()) ?? 0,
      'assignedDate': _assignedDate.toIso8601String(),
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };

    final success =
        await ref.read(vehicleFormProvider.notifier).assignDriver(data);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        widget.onSaved?.call();
      } else {
        final error = ref.read(vehicleFormProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to assign driver'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ──────────────────────────────────────────────
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Assign Driver',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // ── Driver ID ───────────────────────────────────────────
              TextFormField(
                controller: _driverIdCtrl,
                decoration: InputDecoration(
                  labelText: 'Driver ID *',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  helperText: 'Enter the user ID of the driver',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Driver ID is required';
                  if (int.tryParse(v.trim()) == null)
                    return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // ── Assigned Date ───────────────────────────────────────
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Assignment Date',
                    prefixIcon: const Icon(Icons.calendar_month_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  child: Text(dateFmt.format(_assignedDate)),
                ),
              ),
              const SizedBox(height: 12),

              // ── Notes ───────────────────────────────────────────────
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // ── Save Button ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Assign Driver',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
