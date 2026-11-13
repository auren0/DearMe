import '../../l10n/generated/app_localizations.dart';

/// Human-readable countdown used on cards and the sealed-letter screen.
String formatCountdown(Duration remaining, AppLocalizations l10n) {
  if (remaining <= Duration.zero) {
    return l10n.opensNow;
  }
  if (remaining.inMinutes < 1) {
    return l10n.countdownLessThanMinute;
  }

  final days = remaining.inDays;
  final hours = remaining.inHours.remainder(24);
  final minutes = remaining.inMinutes.remainder(60);

  if (days > 0) {
    if (hours > 0) {
      return '${l10n.countdownDays(days)} · ${l10n.countdownHours(hours)}';
    }
    return l10n.countdownDays(days);
  }
  if (hours > 0) {
    if (minutes > 0) {
      return '${l10n.countdownHours(hours)} · '
          '${l10n.countdownMinutes(minutes)}';
    }
    return l10n.countdownHours(hours);
  }
  return l10n.countdownMinutes(minutes);
}
