import 'package:intl/intl.dart';

/// Formats an ISO-8601 timestamp for task UI (local time).
String? formatTaskTimestamp(String? iso) {
  if (iso == null || iso.trim().isEmpty) return null;
  try {
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('d MMM yyyy, h:mm a').format(dt);
  } catch (_) {
    return null;
  }
}
