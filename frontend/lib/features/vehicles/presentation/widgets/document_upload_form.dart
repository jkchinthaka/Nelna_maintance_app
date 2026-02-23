import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/vehicle_provider.dart';

/// Bottom-sheet form for adding a document to a vehicle.
class DocumentUploadForm extends ConsumerStatefulWidget {
  final int vehicleId;
  final VoidCallback? onSaved;

  const DocumentUploadForm({
    super.key,
    required this.vehicleId,
    this.onSaved,
  });

  @override
  ConsumerState<DocumentUploadForm> createState() => _DocumentUploadFormState();
}

class _DocumentUploadFormState extends ConsumerState<DocumentUploadForm> {
  final _formKey = GlobalKey<FormState>();

  String _selectedType = 'INSURANCE';
  DateTime _issueDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  final _documentNoCtrl = TextEditingController();
  final _providerCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _fileUrlCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _isSubmitting = false;

  static const _documentTypes = [
    'INSURANCE',
    'LICENSE',
    'REGISTRATION',
    'EMISSION',
    'FITNESS',
    'PERMIT',
    'OTHER',
  ];

  @override
  void dispose() {
    _documentNoCtrl.dispose();
    _providerCtrl.dispose();
    _amountCtrl.dispose();
    _fileUrlCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final data = {
      'vehicleId': widget.vehicleId,
      'type': _selectedType,
      'documentNo': _documentNoCtrl.text.trim(),
      'issueDate': _issueDate.toIso8601String(),
      'expiryDate': _expiryDate.toIso8601String(),
      if (_providerCtrl.text.isNotEmpty) 'provider': _providerCtrl.text.trim(),
      if (_amountCtrl.text.isNotEmpty)
        'amount': double.tryParse(_amountCtrl.text),
      if (_fileUrlCtrl.text.isNotEmpty) 'fileUrl': _fileUrlCtrl.text.trim(),
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };

    final success =
        await ref.read(vehicleFormProvider.notifier).addDocument(data);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        widget.onSaved?.call();
      } else {
        final error = ref.read(vehicleFormProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to save document'),
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
                'Add Document',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // ── Document Type ───────────────────────────────────────
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: _inputDecor('Document Type'),
                items: _documentTypes
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.replaceAll('_', ' ')),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedType = v ?? _selectedType),
              ),
              const SizedBox(height: 12),

              // ── Document Number ─────────────────────────────────────
              TextFormField(
                controller: _documentNoCtrl,
                decoration: _inputDecor('Document Number *'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Document number is required'
                    : null,
              ),
              const SizedBox(height: 12),

              // ── Issue Date ──────────────────────────────────────────
              InkWell(
                onTap: () => _pickDate(
                  initial: _issueDate,
                  onPicked: (d) => _issueDate = d,
                ),
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Issue Date',
                    prefixIcon: const Icon(Icons.calendar_month_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  child: Text(dateFmt.format(_issueDate)),
                ),
              ),
              const SizedBox(height: 12),

              // ── Expiry Date ─────────────────────────────────────────
              InkWell(
                onTap: () => _pickDate(
                  initial: _expiryDate,
                  onPicked: (d) => _expiryDate = d,
                ),
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Expiry Date',
                    prefixIcon: const Icon(Icons.event_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  child: Text(dateFmt.format(_expiryDate)),
                ),
              ),
              const SizedBox(height: 12),

              // ── Provider + Amount (side by side) ────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _providerCtrl,
                      decoration: _inputDecor('Provider'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecor('Amount (LKR)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── File URL ────────────────────────────────────────────
              TextFormField(
                controller: _fileUrlCtrl,
                decoration: _inputDecor('File URL (optional)'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),

              // ── Notes ───────────────────────────────────────────────
              TextFormField(
                controller: _notesCtrl,
                decoration: _inputDecor('Notes'),
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
                          'Save Document',
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

  InputDecoration _inputDecor(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: AppColors.surface,
    );
  }
}
