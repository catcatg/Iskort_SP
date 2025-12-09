import 'package:intl/intl.dart';

class DateFormatter {
  /// Converts ISO 8601 or backend timestamps to:
  /// YYYY-MM-DD | hh:mm AM/PM
  static String formatDateTime(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      final date = DateFormat('yyyy-MM-dd').format(dt);
      final time = DateFormat('hh:mm a').format(dt);
      return '$date | $time';
    } catch (e) {
      return isoTime; // fallback if parsing fails
    }
  }
}
