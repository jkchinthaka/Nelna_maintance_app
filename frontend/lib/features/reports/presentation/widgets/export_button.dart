import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/report_provider.dart';

/// Export button with a dropdown for PDF / Excel.
/// Triggers the export, saves to temp directory, then opens the file.
class ExportButton extends ConsumerStatefulWidget {
  final String reportType;

  const ExportButton({super.key, required this.reportType});

  @override
  ConsumerState<ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends ConsumerState<ExportButton> {
  bool _exporting = false;

  Future<void> _export(String format) async {
    setState(() => _exporting = true);

    try {
      final range = ref.read(reportDateRangeProvider);
      final branch = ref.read(reportBranchProvider);

      final params = ExportParams(
        type: widget.reportType,
        format: format,
        startDate: range.start,
        endDate: range.end,
        branchId: branch,
      );

      final bytes = await ref.read(exportReportProvider(params).future);
      await _saveAndOpen(bytes, format);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _saveAndOpen(Uint8List bytes, String format) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final ext = format == 'pdf' ? 'pdf' : 'xlsx';
    final filePath = '${dir.path}/${widget.reportType}_$timestamp.$ext';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    await OpenFile.open(filePath);
  }

  @override
  Widget build(BuildContext context) {
    if (_exporting) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return PopupMenuButton<String>(
      onSelected: _export,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(
                Icons.picture_as_pdf_rounded,
                color: AppColors.error,
                size: 20,
              ),
              SizedBox(width: 10),
              Text('Export as PDF'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'excel',
          child: Row(
            children: [
              Icon(
                Icons.table_chart_rounded,
                color: AppColors.success,
                size: 20,
              ),
              SizedBox(width: 10),
              Text('Export as Excel'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.file_download_outlined, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              'Export',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
