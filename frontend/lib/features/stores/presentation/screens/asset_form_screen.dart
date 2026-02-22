import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/asset_entity.dart';
import '../providers/asset_provider.dart';

/// Create / Edit form for assets with all fields, date pickers, dropdowns.
class AssetFormScreen extends ConsumerStatefulWidget {
  /// If non-null, we are editing an existing asset.
  final int? assetId;

  const AssetFormScreen({super.key, this.assetId});

  @override
  ConsumerState<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends ConsumerState<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isInitialized = false;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _serialNumberCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController();
  final _currentValueCtrl = TextEditingController();
  final _depreciationRateCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Dropdown values
  String _category = 'General';
  String _condition = 'Good';
  String _status = 'Available';
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;

  static const _categories = [
    'General',
    'Furniture',
    'Electronics',
    'Computer',
    'Machinery',
    'Tools',
    'Vehicle',
    'Other',
  ];

  static const _conditions = ['New', 'Good', 'Fair', 'Poor', 'Damaged'];

  static const _statuses = [
    'Available',
    'InUse',
    'UnderRepair',
    'Disposed',
    'Lost',
  ];

  bool get _isEditing => widget.assetId != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descriptionCtrl.dispose();
    _serialNumberCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _currentValueCtrl.dispose();
    _depreciationRateCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _populateFields(AssetEntity asset) {
    if (_isInitialized) return;
    _isInitialized = true;

    _nameCtrl.text = asset.name;
    _codeCtrl.text = asset.code;
    _descriptionCtrl.text = asset.description ?? '';
    _serialNumberCtrl.text = asset.serialNumber ?? '';
    _purchasePriceCtrl.text = asset.purchasePrice?.toString() ?? '';
    _currentValueCtrl.text = asset.currentValue?.toString() ?? '';
    _depreciationRateCtrl.text = asset.depreciationRate?.toString() ?? '';
    _locationCtrl.text = asset.location ?? '';
    _notesCtrl.text = asset.notes ?? '';
    _category = asset.category;
    _condition = asset.condition;
    _status = asset.status;
    _purchaseDate = asset.purchaseDate;
    _warrantyExpiry = asset.warrantyExpiry;
  }

  Future<void> _pickDate(BuildContext context, bool isPurchase) async {
    final initial =
        (isPurchase ? _purchaseDate : _warrantyExpiry) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        if (isPurchase) {
          _purchaseDate = picked;
        } else {
          _warrantyExpiry = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'code': _codeCtrl.text.trim(),
      'category': _category,
      'condition': _condition,
      'status': _status,
      if (_descriptionCtrl.text.isNotEmpty)
        'description': _descriptionCtrl.text.trim(),
      if (_serialNumberCtrl.text.isNotEmpty)
        'serialNumber': _serialNumberCtrl.text.trim(),
      if (_purchasePriceCtrl.text.isNotEmpty)
        'purchasePrice': double.tryParse(_purchasePriceCtrl.text),
      if (_currentValueCtrl.text.isNotEmpty)
        'currentValue': double.tryParse(_currentValueCtrl.text),
      if (_depreciationRateCtrl.text.isNotEmpty)
        'depreciationRate': double.tryParse(_depreciationRateCtrl.text),
      if (_locationCtrl.text.isNotEmpty) 'location': _locationCtrl.text.trim(),
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
      if (_purchaseDate != null)
        'purchaseDate': _purchaseDate!.toIso8601String(),
      if (_warrantyExpiry != null)
        'warrantyExpiry': _warrantyExpiry!.toIso8601String(),
    };

    final notifier = ref.read(assetFormProvider.notifier);
    final success = _isEditing
        ? await notifier.updateAsset(widget.assetId!, data)
        : await notifier.createAsset(data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_isEditing ? 'Asset updated' : 'Asset created'),
        ),
      );
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(assetFormProvider);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Asset' : 'New Asset'),
      ),
      body: _isEditing
          ? ref.watch(assetDetailProvider(widget.assetId!)).when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (asset) {
                  _populateFields(asset);
                  return _buildForm(formState, dateFmt);
                },
              )
          : _buildForm(formState, dateFmt),
    );
  }

  Widget _buildForm(AssetFormState formState, DateFormat dateFmt) {
    return LoadingOverlay(
      isLoading: formState.isLoading,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (formState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    formState.errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Basic Info ──────────────────────────────────────────
              _sectionLabel('Basic Information'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Asset Name *',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Asset Code *',
                  prefixIcon: Icon(Icons.qr_code),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Code is required' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _serialNumberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Serial Number',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),
              _sectionLabel('Condition & Status'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _condition,
                      decoration: const InputDecoration(
                        labelText: 'Condition',
                        border: OutlineInputBorder(),
                      ),
                      items: _conditions
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _condition = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: _statuses
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _status = v);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _sectionLabel('Financial Details'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Price',
                        prefixText: 'Rs ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _currentValueCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Current Value',
                        prefixText: 'Rs ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _depreciationRateCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Depreciation Rate (% per annum)',
                  prefixIcon: Icon(Icons.trending_down),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),
              _sectionLabel('Dates'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _dateField(
                      label: 'Purchase Date',
                      value: _purchaseDate,
                      dateFmt: dateFmt,
                      onTap: () => _pickDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _dateField(
                      label: 'Warranty Expiry',
                      value: _warrantyExpiry,
                      dateFmt: dateFmt,
                      onTap: () => _pickDate(context, false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _sectionLabel('Other'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: formState.isLoading ? null : _submit,
                icon: Icon(_isEditing ? Icons.save : Icons.add),
                label: Text(_isEditing ? 'Update Asset' : 'Create Asset'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required DateFormat dateFmt,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(
          value != null ? dateFmt.format(value) : 'Select date',
          style: TextStyle(
            color: value != null
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
