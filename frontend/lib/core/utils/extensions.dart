import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  String Extensions
// ═══════════════════════════════════════════════════════════════════════════
extension StringExtension on String {
  /// Capitalises the first letter of the string.
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Basic e-mail validation.
  bool get isValidEmail {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(this);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  DateTime Extensions
// ═══════════════════════════════════════════════════════════════════════════
extension DateTimeExtension on DateTime {
  /// Formats as `yyyy-MM-dd`.
  String get formatted => DateFormat('yyyy-MM-dd').format(this);

  /// Formats with time: `yyyy-MM-dd HH:mm`.
  String get formattedWithTime => DateFormat('yyyy-MM-dd HH:mm').format(this);

  /// Human-friendly relative time string.
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    }
    final years = (diff.inDays / 365).floor();
    return '$years year${years == 1 ? '' : 's'} ago';
  }

  /// True if the date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Number Extensions
// ═══════════════════════════════════════════════════════════════════════════
extension NumberExtension on num {
  /// Formats as currency, e.g. `LKR 1,234.56`.
  String toCurrency({String symbol = 'LKR'}) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '$symbol ',
      decimalDigits: 2,
    );
    return formatter.format(this);
  }
}
