import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../providers/vehicle_provider.dart';

/// Create / Edit vehicle form screen.
///
/// Pass an existing [VehicleEntity] via GoRouter `extra` to enable edit mode.
class VehicleFormScreen extends ConsumerStatefulWidget {
  final VehicleEntity? vehicle;

  const VehicleFormScreen({super.key, this.vehicle});

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEditMode;

  // Controllers
  late final TextEditingController _registrationCtrl;
  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _engineNoCtrl;
  late final TextEditingController _chassisNoCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _mileageCtrl;
  late final TextEditingController _purchasePriceCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _branchIdCtrl;

  // Dropdowns
  String _fuelType = 'DIESEL';
  String _vehicleType = 'Car';
  String _status = 'ACTIVE';

  // Dates
  DateTime? _purchaseDate;
  DateTime? _insuranceExpiry;
  DateTime? _licenseExpiry;

  static const _fuelTypes = ['PETROL', 'DIESEL', 'ELECTRIC', 'HYBRID', 'GAS'];
  static const _vehicleTypes = [
    'Car',
    'Van',
    'Truck',
    'Bus',
    'Motorcycle',
    'Heavy Vehicle',
    'Three Wheeler',
    'Other',
  ];
  static const _statusOptions = [
    'ACTIVE',
    'IN_SERVICE',
    'INACTIVE',
    'BREAKDOWN',
    'DISPOSED',
  ];

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _isEditMode = v != null;

    _registrationCtrl = TextEditingController(text: v?.registrationNo ?? '');
    _makeCtrl = TextEditingController(text: v?.make ?? '');
    _modelCtrl = TextEditingController(text: v?.model ?? '');
    _yearCtrl = TextEditingController(text: v?.year?.toString() ?? '');
    _engineNoCtrl = TextEditingController(text: v?.engineNo ?? '');
    _chassisNoCtrl = TextEditingController(text: v?.chassisNo ?? '');
    _colorCtrl = TextEditingController(text: v?.color ?? '');
    _mileageCtrl = TextEditingController(
      text: v?.mileage.toStringAsFixed(0) ?? '0',
    );
    _purchasePriceCtrl = TextEditingController(
      text: v?.purchasePrice?.toStringAsFixed(2) ?? '',
    );
    _notesCtrl = TextEditingController(text: v?.notes ?? '');
    _branchIdCtrl = TextEditingController(text: v?.branchId.toString() ?? '1');

    _fuelType = v?.fuelType ?? 'DIESEL';
    _vehicleType = v?.vehicleType ?? 'Car';
    _status = v?.status ?? 'ACTIVE';
    _purchaseDate = v?.purchaseDate;
    _insuranceExpiry = v?.insuranceExpiry;
    _licenseExpiry = v?.licenseExpiry;
  }

  @override
  void dispose() {
    _registrationCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _engineNoCtrl.dispose();
    _chassisNoCtrl.dispose();
    _colorCtrl.dispose();
    _mileageCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _notesCtrl.dispose();
    _branchIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    String label,
    DateTime? initial,
    ValueChanged<DateTime> onPicked,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
      helpText: label,
    );
    if (date != null) {
      setState(() => onPicked(date));
    }
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'branchId': int.tryParse(_branchIdCtrl.text) ?? 1,
      'registrationNo': _registrationCtrl.text.trim(),
      'make': _makeCtrl.text.trim(),
      'model': _modelCtrl.text.trim(),
      if (_yearCtrl.text.isNotEmpty) 'year': int.tryParse(_yearCtrl.text),
      if (_engineNoCtrl.text.isNotEmpty) 'engineNo': _engineNoCtrl.text.trim(),
      if (_chassisNoCtrl.text.isNotEmpty)
        'chassisNo': _chassisNoCtrl.text.trim(),
      'fuelType': _fuelType,
      'vehicleType': _vehicleType,
      if (_colorCtrl.text.isNotEmpty) 'color': _colorCtrl.text.trim(),
      'mileage': double.tryParse(_mileageCtrl.text) ?? 0,
      'status': _status,
      if (_purchaseDate != null)
        'purchaseDate': _purchaseDate!.toIso8601String(),
      if (_purchasePriceCtrl.text.isNotEmpty)
        'purchasePrice': double.tryParse(_purchasePriceCtrl.text),
      if (_insuranceExpiry != null)
        'insuranceExpiry': _insuranceExpiry!.toIso8601String(),
      if (_licenseExpiry != null)
        'licenseExpiry': _licenseExpiry!.toIso8601String(),
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(vehicleFormProvider.notifier);
    final data = _buildPayload();

    bool success;
    if (_isEditMode) {
      success = await notifier.updateVehicle(widget.vehicle!.id, data);
    } else {
      success = await notifier.createVehicle(data);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehicle ${_isEditMode ? 'updated' : 'created'} successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      ref.invalidate(vehicleListProvider(const VehicleListParams()));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(vehicleFormProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Vehicle' : 'New Vehicle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                    const Icon(Icons.error_outline, color: AppColors.error),
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

            // ── Vehicle Identity ──────────────────────────────────────────
            _sectionHeader('Vehicle Identity'),
            _textField(
              controller: _registrationCtrl,
              label: 'Registration No *',
              icon: Icons.badge_outlined,
              validator: _required,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: _makeCtrl,
                    label: 'Make *',
                    icon: Icons.factory_outlined,
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    controller: _modelCtrl,
                    label: 'Model *',
                    icon: Icons.directions_car_outlined,
                    validator: _required,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: _yearCtrl,
                    label: 'Year',
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    controller: _colorCtrl,
                    label: 'Color',
                    icon: Icons.palette_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _dropdown(
                    label: 'Fuel Type',
                    value: _fuelType,
                    items: _fuelTypes,
                    onChanged: (v) =>
                        setState(() => _fuelType = v ?? _fuelType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dropdown(
                    label: 'Vehicle Type',
                    value: _vehicleType,
                    items: _vehicleTypes,
                    onChanged: (v) =>
                        setState(() => _vehicleType = v ?? _vehicleType),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _dropdown(
              label: 'Status',
              value: _status,
              items: _statusOptions,
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),

            const SizedBox(height: 24),
            _sectionHeader('Technical Details'),
            _textField(
              controller: _engineNoCtrl,
              label: 'Engine No',
              icon: Icons.settings_outlined,
            ),
            const SizedBox(height: 12),
            _textField(
              controller: _chassisNoCtrl,
              label: 'Chassis No',
              icon: Icons.build_outlined,
            ),
            const SizedBox(height: 12),
            _textField(
              controller: _mileageCtrl,
              label: 'Current Mileage (km)',
              icon: Icons.speed,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),
            _sectionHeader('Purchase & Dates'),
            _textField(
              controller: _branchIdCtrl,
              label: 'Branch ID *',
              icon: Icons.business_outlined,
              keyboardType: TextInputType.number,
              validator: _required,
            ),
            const SizedBox(height: 12),
            _textField(
              controller: _purchasePriceCtrl,
              label: 'Purchase Price (LKR)',
              icon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            _datePicker(
              label: 'Purchase Date',
              value: _purchaseDate,
              onPicked: (d) => _purchaseDate = d,
            ),
            const SizedBox(height: 12),
            _datePicker(
              label: 'Insurance Expiry',
              value: _insuranceExpiry,
              onPicked: (d) => _insuranceExpiry = d,
            ),
            const SizedBox(height: 12),
            _datePicker(
              label: 'License Expiry',
              value: _licenseExpiry,
              onPicked: (d) => _licenseExpiry = d,
            ),

            const SizedBox(height: 24),
            _sectionHeader('Additional'),
            _textField(
              controller: _notesCtrl,
              label: 'Notes',
              icon: Icons.notes,
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // ── Save Button ──────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: formState.isLoading ? null : _onSave,
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
                        _isEditMode ? 'Update Vehicle' : 'Create Vehicle',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  // ── Reusable Widgets ────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: AppColors.surface,
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: AppColors.surface,
      ),
      items: items
          .map(
            (e) =>
                DropdownMenuItem(value: e, child: Text(e.replaceAll('_', ' '))),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPicked,
  }) {
    return InkWell(
      onTap: () => _pickDate(label, value, onPicked),
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: AppColors.surface,
        ),
        child: Text(
          value != null
              ? DateFormat('dd MMM yyyy').format(value)
              : 'Select date',
          style: TextStyle(
            color: value != null
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }
}
