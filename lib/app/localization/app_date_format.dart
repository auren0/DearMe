import 'package:intl/intl.dart';

/// Date formatting is centralized so that every screen uses the same locale
/// and time zone conversion rules.
abstract final class AppDateFormatter {
  static String date(DateTime utc, String localeName) {
    return DateFormat.yMMMMd(localeName).format(utc.toLocal());
  }

  static String dateTime(DateTime utc, String localeName) {
    return DateFormat.yMMMMd(localeName).add_jm().format(utc.toLocal());
  }

  static String dateShort(DateTime utc, String localeName) {
    return DateFormat.MMMd(localeName).format(utc.toLocal());
  }

  static String time(DateTime utc, String localeName) {
    return DateFormat.jm(localeName).format(utc.toLocal());
  }

  static String timeOfDay(int hour, int minute, String localeName) {
    final now = DateTime.now();
    return DateFormat.jm(localeName)
        .format(DateTime(now.year, now.month, now.day, hour, minute));
  }

  static String weekdayShort(DateTime date, String localeName) {
    return DateFormat.E(localeName).format(date);
  }
}
