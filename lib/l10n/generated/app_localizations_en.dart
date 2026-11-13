// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'DearMe';

  @override
  String get appTagline => 'Letters to your future self';

  @override
  String get appDescription =>
      'A quiet place to leave a few words for the person you will become.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get disable => 'Turn off';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get edit => 'Edit';

  @override
  String get open => 'Open';

  @override
  String get retry => 'Retry';

  @override
  String get confirm => 'Confirm';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get ok => 'OK';

  @override
  String get refresh => 'Refresh';

  @override
  String get loading => 'Loading…';

  @override
  String get unexpectedError => 'Something went wrong. Please try again.';

  @override
  String get storageError => 'Could not load your letters.';

  @override
  String get storageWriteError => 'Could not save your changes.';

  @override
  String get storageUnavailableBanner =>
      'Storage is unavailable: letters will only last until the app restarts.';

  @override
  String get settingsSaveError => 'Could not save this setting.';

  @override
  String get loadErrorTitle => 'Your letters could not be loaded';

  @override
  String get tryAgain => 'Try again';

  @override
  String get offlineOrPermission =>
      'Check available storage and app permissions.';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeGreetingNight => 'Quiet night';

  @override
  String get homeHello => 'Welcome back.';

  @override
  String get homeSubtitleEmpty =>
      'Write your first letter to your future self.';

  @override
  String homeSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count letters are waiting for their moment.',
      one: 'One letter is waiting for its moment.',
      zero: 'No letters yet. It is a good day to begin.',
    );
    return '$_temp0';
  }

  @override
  String get homeSummaryAllRead =>
      'All letters are read. You can write a new one to your future self.';

  @override
  String get homeNewLetter => 'Write a letter';

  @override
  String get homeReadySection => 'Ready to open';

  @override
  String get homeSealedSection => 'Sealed';

  @override
  String get homeOpenedSection => 'Read';

  @override
  String get homeDraftsSection => 'Drafts';

  @override
  String get homeFooterQuote => 'Some words are better read later.';

  @override
  String get emptyTitle => 'Quiet here for now';

  @override
  String get emptyBody =>
      'Your first letter is waiting to be written. Choose a day and leave a few words for your future self.';

  @override
  String get emptyAction => 'Write your first letter';

  @override
  String get emptyDraftsTitle => 'Drafts will appear here';

  @override
  String get emptyDraftsBody =>
      'Start writing — your draft saves automatically.';

  @override
  String get statSealed => 'Sealed';

  @override
  String get statReady => 'Ready';

  @override
  String get statOpened => 'Read';

  @override
  String get statDrafts => 'Drafts';

  @override
  String get statusSealed => 'Sealed';

  @override
  String get statusReady => 'Ready to open';

  @override
  String get statusOpened => 'Read';

  @override
  String get statusDraft => 'Draft';

  @override
  String createdOn(String date) {
    return 'Created $date';
  }

  @override
  String opensOn(String date) {
    return 'Opens $date';
  }

  @override
  String openedOn(String date) {
    return 'Opened $date';
  }

  @override
  String get opensIn => 'Opens in';

  @override
  String get opensNow => 'Ready to open now';

  @override
  String letterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count letters',
      one: '$count letter',
    );
    return '$_temp0';
  }

  @override
  String get countdownLessThanMinute => 'less than a minute';

  @override
  String countdownDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String countdownHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '$count hour',
    );
    return '$_temp0';
  }

  @override
  String countdownMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '$count minute',
    );
    return '$_temp0';
  }

  @override
  String countdownSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
      one: '$count second',
    );
    return '$_temp0';
  }

  @override
  String get editorNewTitle => 'New letter';

  @override
  String get editorEditTitle => 'Edit letter';

  @override
  String get editorTitleLabel => 'Title';

  @override
  String get editorTitleHint => 'What is this letter about?';

  @override
  String get editorBodyLabel => 'Letter';

  @override
  String get editorBodyHint => 'Dear future me…';

  @override
  String get editorOpenAt => 'When to open';

  @override
  String get editorOpenDate => 'Opening date';

  @override
  String get editorOpenTime => 'Time';

  @override
  String get editorChooseDate => 'Choose a date';

  @override
  String get editorChooseTime => 'Choose a time';

  @override
  String get editorOpenAtHelper =>
      'This letter stays sealed until this moment.';

  @override
  String get editorTitleRequired => 'Please add a title.';

  @override
  String editorTitleTooLong(int max) {
    return 'The title is too long: $max characters max.';
  }

  @override
  String get editorBodyRequired => 'Write at least a few words.';

  @override
  String editorBodyTooLong(int max) {
    return 'This letter is too long: $max characters max.';
  }

  @override
  String get editorOpenAtRequired => 'Choose an opening date and time.';

  @override
  String get editorOpenAtFuture => 'The opening date must be in the future.';

  @override
  String charCount(int count, int max) {
    return '$count / $max';
  }

  @override
  String get autosaved => 'Draft saved';

  @override
  String get autosaveFailed => 'Could not save the draft.';

  @override
  String savedAt(String time) {
    return 'Saved at $time';
  }

  @override
  String get discardTitle => 'Discard changes?';

  @override
  String get discardBody => 'Your unsaved changes will be lost.';

  @override
  String get discardAction => 'Leave without saving';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get saveDraft => 'Save draft';

  @override
  String get sealLetter => 'Seal letter';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get saveConfirmTitle => 'Seal this letter?';

  @override
  String saveConfirmBody(String date) {
    return 'The letter will stay sealed until $date.';
  }

  @override
  String get saveConfirmAction => 'Seal';

  @override
  String get sealedSuccess => 'Your letter is sealed. See you in the future.';

  @override
  String get draftSaved => 'Draft saved.';

  @override
  String get letterUpdated => 'Letter updated.';

  @override
  String get editingSealedNotice =>
      'This letter is already sealed. Changes will reschedule the notification, but the content will still open only at the chosen moment.';

  @override
  String get draftNotice =>
      'This is a draft. Choose a date and seal it when you are ready.';

  @override
  String get datePickerHelp => 'Choose the opening day';

  @override
  String get timePickerHelp => 'Choose the opening time';

  @override
  String get invalidDate => 'Invalid date.';

  @override
  String get draftAutosaveHint => 'Autosave is on';

  @override
  String get detailSealedTitle => 'A sealed letter';

  @override
  String detailSealedBody(String createdDate, String openDate) {
    return 'You wrote it on $createdDate.\nIt opens on $openDate.';
  }

  @override
  String get detailReadyTitle => 'Your letter is ready';

  @override
  String detailReadyBody(String createdDate) {
    return 'You wrote it on $createdDate.\nIt is time to read it.';
  }

  @override
  String get detailOpenButton => 'Open letter';

  @override
  String get detailLockedHint =>
      'The content is safely hidden until the chosen day.';

  @override
  String detailOpenedAt(String date) {
    return 'Opened $date';
  }

  @override
  String detailWrittenAt(String date) {
    return 'Written $date';
  }

  @override
  String get detailDeleteTitle => 'Delete this letter?';

  @override
  String detailDeleteBody(String title) {
    return '“$title” will be permanently deleted. This cannot be undone.';
  }

  @override
  String get detailDeleted => 'Letter deleted.';

  @override
  String get detailNotFound => 'Letter not found';

  @override
  String get detailNotFoundBody =>
      'It may have been deleted, or this link is out of date.';

  @override
  String get detailBackHome => 'Back home';

  @override
  String get detailEdit => 'Edit';

  @override
  String get detailReschedule => 'Change opening date';

  @override
  String get detailDelete => 'Delete';

  @override
  String get rescheduleTitle => 'When should this letter open?';

  @override
  String get rescheduleSuccess => 'Opening date updated.';

  @override
  String get sealedEditNotAllowed =>
      'A sealed letter cannot be edited. Only its opening date can be changed.';

  @override
  String get detailSealedBadge => 'Until it opens';

  @override
  String get sealStamp => 'SEALED';

  @override
  String wordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '$count word',
    );
    return '$_temp0';
  }

  @override
  String get detailLetterFromPast => 'A letter from your past';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeOled => 'OLED';

  @override
  String get themeLightDescription => 'Warm paper and soft shadows.';

  @override
  String get themeDarkDescription => 'Calm dark surfaces.';

  @override
  String get themeOledDescription => 'True black and high contrast.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageRu => 'Russian';

  @override
  String get languageEn => 'English';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsEnabled => 'Remind me when letters open';

  @override
  String get settingsNotificationsDescription =>
      'A system notification arrives when a letter is ready.';

  @override
  String get notificationPermissionStatus => 'Permission';

  @override
  String get permissionGranted => 'Allowed';

  @override
  String get permissionDenied => 'Blocked';

  @override
  String get permissionNotDetermined => 'Not requested yet';

  @override
  String get permissionUnsupported => 'Not supported on this device';

  @override
  String get requestPermission => 'Request permission';

  @override
  String get testNotification => 'Test notification';

  @override
  String get testNotificationSent => 'Test notification sent.';

  @override
  String get testNotificationFailed =>
      'Could not show the notification. Check your browser or system permission.';

  @override
  String get testNotificationNeedsPermission => 'Allow notifications first.';

  @override
  String get openSystemSettings => 'Open system settings';

  @override
  String get systemSettingsUnavailable =>
      'System notification settings are not available on this platform.';

  @override
  String get notificationLimitationsTitle => 'Platform capabilities';

  @override
  String get notificationLimitationsLinux =>
      'Linux has no system scheduler for local notifications. Notifications arrive while DearMe is running; the notification itself is a real system notification.';

  @override
  String get notificationLimitationsIos =>
      'iOS keeps at most 64 pending notifications. DearMe schedules the next 60 and adds the rest on the next launch.';

  @override
  String get notificationLimitationsAndroid =>
      'Android may delay background delivery and may need battery optimization disabled for precise timing.';

  @override
  String get notificationLimitationsWeb =>
      'Notifications with the tab closed require HTTPS, browser permission and a configured push server. On iOS the web app must be added to the Home Screen. Support varies by browser.';

  @override
  String get notificationLimitationsWindows =>
      'Windows delivers scheduled notifications. Without an MSIX package the app cannot remove an already-shown notification from Action Center, but cancelling a scheduled one works.';

  @override
  String get notificationLimitationsMacos =>
      'macOS uses system notifications. You can change permission in System Settings.';

  @override
  String get notificationLimitationsNone =>
      'The platform supports system notifications.';

  @override
  String get notificationLimitationsWebUnsupported =>
      'This browser does not support Web Push or Service Workers, so background notifications are unavailable.';

  @override
  String get pushServerStatus => 'Push server';

  @override
  String get pushServerConnected => 'Connected';

  @override
  String get pushServerNotConfigured => 'Not configured';

  @override
  String get pushServerError => 'Unreachable';

  @override
  String get pushServerNotConfiguredHint =>
      'Set the server address at build time: --dart-define=DEARME_PUSH_API=https://…';

  @override
  String get notificationDisableConfirmTitle => 'Turn notifications off?';

  @override
  String get notificationDisableConfirmBody =>
      'Scheduled reminders will be cancelled. Letters stay sealed and will still open at the chosen time.';

  @override
  String get settingsData => 'Data';

  @override
  String get dataLetters => 'Letters';

  @override
  String get dataOpened => 'Read';

  @override
  String get dataSealed => 'Sealed';

  @override
  String get dataDrafts => 'Drafts';

  @override
  String get exportData => 'Export letters';

  @override
  String get exportDescription => 'Save a JSON backup.';

  @override
  String get importData => 'Import letters';

  @override
  String get importDescription => 'Add letters from an export file.';

  @override
  String get deleteAllData => 'Delete all data';

  @override
  String get deleteAllDescription =>
      'All letters and settings will be removed.';

  @override
  String get deleteAllTitle => 'Delete everything?';

  @override
  String get deleteAllBody =>
      'All letters will be permanently deleted. This cannot be undone.';

  @override
  String deleteAllConfirmHint(String word) {
    return 'Type $word to confirm.';
  }

  @override
  String get deleteAllConfirmWord => 'DELETE';

  @override
  String get deleteAllAction => 'Delete everything';

  @override
  String get dataDeleted => 'All data deleted.';

  @override
  String get exportSuccess => 'Backup saved.';

  @override
  String get exportFailed => 'Could not export letters.';

  @override
  String get importSuccess => 'Import complete.';

  @override
  String importResult(int imported, int updated, int skipped) {
    return 'Added: $imported, updated: $updated, skipped: $skipped.';
  }

  @override
  String get importFailed => 'Could not import letters.';

  @override
  String get importInvalid => 'This file does not look like a DearMe backup.';

  @override
  String get importEmpty => 'There are no letters in this file.';

  @override
  String get importConfirmTitle => 'Import letters?';

  @override
  String importConfirmBody(int count) {
    return '$count letters found. Letters with the same identifiers will be updated if the imported version is newer.';
  }

  @override
  String get importConfirmAction => 'Import';

  @override
  String get settingsAbout => 'About';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutDescription =>
      'DearMe is a calm place for letters to yourself. Write today, read when the time comes.';

  @override
  String get aboutLicenses => 'Open source licenses';

  @override
  String get aboutPrivacy => 'Privacy';

  @override
  String get aboutPrivacyBody =>
      'Letters live only on this device. Only the letter identifier, delivery time and technical subscription data are sent to the push server — never the letter text.';

  @override
  String get aboutMadeWith => 'Made with care for the future.';

  @override
  String get licensePageTitle => 'Licenses';

  @override
  String get notificationTitle => 'A letter from your past 💌';

  @override
  String get notificationBody =>
      'Your letter to your future self is ready to open.';

  @override
  String get notificationChannelName => 'DearMe letters';

  @override
  String get notificationChannelDescription => 'Reminders when letters open';

  @override
  String get testNotificationTitle => 'DearMe is here';

  @override
  String get testNotificationBody =>
      'Notifications are ready. Letters from the past will find you.';

  @override
  String get errorNotificationSchedule =>
      'The letter was saved, but the notification could not be scheduled.';

  @override
  String get errorNotificationPermission =>
      'Notification permission was not granted.';

  @override
  String get errorNotificationUnsupported =>
      'Notifications are not available on this platform.';

  @override
  String get errorImportRead => 'Could not read the selected file.';

  @override
  String get errorImportParse =>
      'The file is damaged or has an unsupported format.';

  @override
  String get errorNoLettersToExport => 'There is nothing to export yet.';

  @override
  String get a11yOpenSettings => 'Open settings';

  @override
  String get a11yNewLetter => 'Create a new letter';

  @override
  String a11yLetterCard(String title, String status) {
    return 'Letter “$title”, $status';
  }

  @override
  String get a11yBack => 'Back';

  @override
  String get a11yMore => 'More';

  @override
  String a11yThemeSelected(String theme) {
    return '$theme theme selected';
  }

  @override
  String a11yLanguageSelected(String language) {
    return '$language language selected';
  }

  @override
  String get weekdayShortMon => 'Mon';

  @override
  String get weekdayShortTue => 'Tue';

  @override
  String get weekdayShortWed => 'Wed';

  @override
  String get weekdayShortThu => 'Thu';

  @override
  String get weekdayShortFri => 'Fri';

  @override
  String get weekdayShortSat => 'Sat';

  @override
  String get weekdayShortSun => 'Sun';
}
