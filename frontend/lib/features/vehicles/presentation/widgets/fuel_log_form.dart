import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/vehicle_provider.dart';

/// Bottom‑sheet form for adding a fuel log to a vehicle.
class FuelLogForm extends ConsumerStatefulWidget {
  final int vehicleId;
  final String defaultFuelType;
  final VoidCallback? onSaved;

  const FuelLogForm({
    super.key,
    required this.vehicleId,
    this.defaultFuelType = 'DIESEL',
    this.onSaved,
  });

  @override
  ConsumerState<FuelLogForm> createState() => _FuelLogFormState();
}

class _FuelLogFormState extends ConsumerState<FuelLogForm> {
  final _formKey = GlobalKey<FormState>();

  late String _fuelType;
  DateTime _date = DateTime.now();

  final _quantityCtrl = TextEditingController();
  final _unitPriceCtrl = TextEditingController();
  final _totalCostCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  final _stationCtrl = TextEditingController();
  final _receiptNoCtrl = TextEditingController();

  bool _isSubmitting = false;

  static const _fuelTypes = ['PETROL', 'DIESEL', 'ELECTRIC', 'HYBRID', 'GAS'];

  @override
  void initState() {
    super.initState();
    _fuelType = widget.defaultFuelType;

    _quantityCtrl.addListener(_autoCalculateTotalCost);
    _unitPriceCtrl.addListener(_autoCalculateTotalCost);
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _unitPriceCtrl.dispose();
    _totalCostCtrl.dispose();
    _mileageCtrl.dispose();
    _stationCtrl.dispose();
    _receiptNoCtrl.dispose();
    super.dispose();
  }

  void _autoCalculateTotalCost() {
    final qty = double.tryParse(_quantityCtrl.text);
    final price = double.tryParse(_unitPriceCtrl.text);
    if (qty != null && price != null) {
      _totalCostCtrl.text = (qty * price).toStringAsFixed(2);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Fuel Date',
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final data = {
      'vehicleId': widget.vehicleId,
      'date': _date.toIso8601String(),
      'fuelType': _fuelType,
      'quantity': double.tryParse(_quantityCtrl.text) ?? 0,
      'unitPrice': double.tryParse(_unitPriceCtrl.text) ?? 0,
      'totalCost': double.tryParse(_totalCostCtrl.text) ?? 0,
      'mileage': double.tryParse(_mileageCtrl.text) ?? 0,
      if (_stationCtrl.text.isNotEmpty) 'station': _stationCtrl.text.trim(),
      if (_receiptNoCtrl.text.isNotEmpty)
        'receiptNo': _receiptNoCtrl.text.trim(),
    };

    final success = await ref
        .read(vehicleFormProvider.notifier)
        .addFuelLog(data);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        widget.onSaved?.call();
      } else {
        final error = ref.read(vehicleFormProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to save fuel log'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // ── Handle ──────────────────────────────────────────────────
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
                'Add Fuel Log',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // ── Date ────────────────────────────────────────────────────
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: const Icon(Icons.calendar_month_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  child: Text(DateFormat('dd MMM yyyy').format(_date)),
                ),
              ),
              const SizedBox(height: 12),

              // ── Fuel Type ───────────────────────────────────────────────
              DropdownButtonFormField<String>(
                value: _fuelTypes.contains(_fuelType)
                    ? _fuelType
                    : _fuelTypes.first,
                decoration: InputDecoration(
                  labelText: 'Fuel Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                items: _fuelTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _fuelType = v ?? _fuelType),
              ),
              const SizedBox(height: 12),

              // ── Quantity + Unit Price (side by side) ─────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _requiredNum,
                      decoration: _inputDecor('Quantity (L)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _requiredNum,
                      decoration: _inputDecor('Unit Price'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Total Cost (auto‑calculated) ────────────────────────────
              TextFormField(
                controller: _totalCostCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecor('Total Cost (LKR)'),
                readOnly: true,
              ),
              const SizedBox(height: 12),

              // ── Mileage ─────────────────────────────────────────────────
              TextFormField(
                controller: _mileageCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _requiredNum,
                decoration: _inputDecor('Odometer Reading (km)'),
              ),
              const SizedBox(height: 12),

              // ── Station + Receipt ───────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stationCtrl,
                      decoration: _inputDecor('Station'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _receiptNoCtrl,
                      decoration: _inputDecor('Receipt No'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Save Button ─────────────────────────────────────────────
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
                          'Save Fuel Log',
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

  // ── Helpers ──────────────────────────────────────────────────────────────

  InputDecoration _inputDecor(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: AppColors.surface,
    );
  }

  String? _requiredNum(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (double.tryParse(value) == null) return 'Enter a valid number';
    return null;
  }
}
