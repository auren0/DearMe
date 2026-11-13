import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

/// Time zone detection used to notice a zone change while the app was closed.
///
/// Scheduling itself always uses an absolute UTC instant, so a time zone change
/// never changes the instant a letter opens. Rescheduling simply refreshes the
/// OS-level calendar trigger and is a no-op semantically.
class TimeZoneService {
  const TimeZoneService();

  Future<String> currentIdentifier() async {
    if (kIsWeb) {
      return 'web';
    }
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      return timezone.identifier;
    } on Object {
      return 'UTC';
    }
  }
}
