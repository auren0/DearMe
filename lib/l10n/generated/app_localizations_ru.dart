// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'DearMe';

  @override
  String get appTagline => 'Письма себе в будущее';

  @override
  String get appDescription =>
      'Тихое место, где можно оставить несколько слов тому, кем ты станешь.';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get cancel => 'Отмена';

  @override
  String get disable => 'Отключить';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get close => 'Закрыть';

  @override
  String get back => 'Назад';

  @override
  String get done => 'Готово';

  @override
  String get edit => 'Изменить';

  @override
  String get open => 'Открыть';

  @override
  String get retry => 'Повторить';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get dismiss => 'Закрыть';

  @override
  String get ok => 'Хорошо';

  @override
  String get refresh => 'Обновить';

  @override
  String get loading => 'Загружаем…';

  @override
  String get unexpectedError => 'Что-то пошло не так. Попробуй ещё раз.';

  @override
  String get storageError => 'Не удалось загрузить письма.';

  @override
  String get storageWriteError => 'Не удалось сохранить изменения.';

  @override
  String get storageUnavailableBanner =>
      'Хранилище недоступно: письма сохранятся только до перезапуска приложения.';

  @override
  String get settingsSaveError => 'Не удалось сохранить настройку.';

  @override
  String get loadErrorTitle => 'Не получилось загрузить письма';

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String get offlineOrPermission =>
      'Проверь свободное место и разрешения приложения.';

  @override
  String get homeGreetingMorning => 'Доброе утро';

  @override
  String get homeGreetingAfternoon => 'Добрый день';

  @override
  String get homeGreetingEvening => 'Добрый вечер';

  @override
  String get homeGreetingNight => 'Тихой ночи';

  @override
  String get homeHello => 'С возвращением.';

  @override
  String get homeSubtitleEmpty => 'Напиши первое письмо себе в будущее.';

  @override
  String homeSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count письма ждут своего часа.',
      many: '$count писем ждут своего часа.',
      few: '$count письма ждут своего часа.',
      one: 'Одно письмо ждёт своего часа.',
      zero: 'Пока ни одного письма. Самое время начать.',
    );
    return '$_temp0';
  }

  @override
  String get homeSummaryAllRead =>
      'Все письма прочитаны. Можно написать новое — будущему себе.';

  @override
  String get homeNewLetter => 'Написать письмо';

  @override
  String get homeReadySection => 'Можно открыть';

  @override
  String get homeSealedSection => 'Запечатано';

  @override
  String get homeOpenedSection => 'Прочитано';

  @override
  String get homeDraftsSection => 'Черновики';

  @override
  String get homeFooterQuote => 'Некоторые слова лучше прочитать позже.';

  @override
  String get emptyTitle => 'Пока здесь тихо';

  @override
  String get emptyBody =>
      'Твоё первое письмо уже ждёт, чтобы его написали. Выбери день — и оставь будущему себе несколько слов.';

  @override
  String get emptyAction => 'Написать первое письмо';

  @override
  String get emptyDraftsTitle => 'Здесь появятся черновики';

  @override
  String get emptyDraftsBody =>
      'Начни письмо — и оно сохранится автоматически.';

  @override
  String get statSealed => 'Запечатано';

  @override
  String get statReady => 'Готовы';

  @override
  String get statOpened => 'Прочитано';

  @override
  String get statDrafts => 'Черновики';

  @override
  String get statusSealed => 'Запечатано';

  @override
  String get statusReady => 'Готово к открытию';

  @override
  String get statusOpened => 'Прочитано';

  @override
  String get statusDraft => 'Черновик';

  @override
  String createdOn(String date) {
    return 'Создано $date';
  }

  @override
  String opensOn(String date) {
    return 'Откроется $date';
  }

  @override
  String openedOn(String date) {
    return 'Открыто $date';
  }

  @override
  String get opensIn => 'До открытия';

  @override
  String get opensNow => 'Можно открыть сейчас';

  @override
  String letterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count письма',
      many: '$count писем',
      few: '$count письма',
      one: '$count письмо',
    );
    return '$_temp0';
  }

  @override
  String get countdownLessThanMinute => 'меньше минуты';

  @override
  String countdownDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String countdownHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часа',
      many: '$count часов',
      few: '$count часа',
      one: '$count час',
    );
    return '$_temp0';
  }

  @override
  String countdownMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минуты',
      many: '$count минут',
      few: '$count минуты',
      one: '$count минута',
    );
    return '$_temp0';
  }

  @override
  String countdownSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count секунды',
      many: '$count секунд',
      few: '$count секунды',
      one: '$count секунда',
    );
    return '$_temp0';
  }

  @override
  String get editorNewTitle => 'Новое письмо';

  @override
  String get editorEditTitle => 'Редактировать письмо';

  @override
  String get editorTitleLabel => 'Заголовок';

  @override
  String get editorTitleHint => 'О чём это письмо?';

  @override
  String get editorBodyLabel => 'Письмо';

  @override
  String get editorBodyHint => 'Дорогой я в будущем…';

  @override
  String get editorOpenAt => 'Когда открыть';

  @override
  String get editorOpenDate => 'Дата открытия';

  @override
  String get editorOpenTime => 'Время';

  @override
  String get editorChooseDate => 'Выбрать дату';

  @override
  String get editorChooseTime => 'Выбрать время';

  @override
  String get editorOpenAtHelper => 'Письмо будет запечатано до этого момента.';

  @override
  String get editorTitleRequired => 'Введите заголовок.';

  @override
  String editorTitleTooLong(int max) {
    return 'Заголовок слишком длинный: максимум $max символов.';
  }

  @override
  String get editorBodyRequired => 'Напишите хотя бы несколько слов.';

  @override
  String editorBodyTooLong(int max) {
    return 'Письмо слишком длинное: максимум $max символов.';
  }

  @override
  String get editorOpenAtRequired => 'Выберите дату и время открытия.';

  @override
  String get editorOpenAtFuture => 'Дата открытия должна быть в будущем.';

  @override
  String charCount(int count, int max) {
    return '$count / $max';
  }

  @override
  String get autosaved => 'Черновик сохранён';

  @override
  String get autosaveFailed => 'Не удалось сохранить черновик.';

  @override
  String savedAt(String time) {
    return 'Сохранено в $time';
  }

  @override
  String get discardTitle => 'Отменить изменения?';

  @override
  String get discardBody => 'Несохранённые изменения будут потеряны.';

  @override
  String get discardAction => 'Выйти без сохранения';

  @override
  String get keepEditing => 'Продолжить редактирование';

  @override
  String get saveDraft => 'Сохранить черновик';

  @override
  String get sealLetter => 'Запечатать письмо';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get saveConfirmTitle => 'Запечатать письмо?';

  @override
  String saveConfirmBody(String date) {
    return 'Письмо будет запечатано до $date.';
  }

  @override
  String get saveConfirmAction => 'Запечатать';

  @override
  String get sealedSuccess => 'Письмо запечатано. Увидимся в будущем.';

  @override
  String get draftSaved => 'Черновик сохранён.';

  @override
  String get letterUpdated => 'Письмо обновлено.';

  @override
  String get editingSealedNotice =>
      'Письмо уже запечатано. Изменения перепланируют уведомление, но содержимое всё равно откроется только в назначенный момент.';

  @override
  String get draftNotice =>
      'Это черновик. Выбери дату и запечатай письмо, когда будешь готов.';

  @override
  String get datePickerHelp => 'Выберите день открытия';

  @override
  String get timePickerHelp => 'Выберите время открытия';

  @override
  String get invalidDate => 'Некорректная дата.';

  @override
  String get draftAutosaveHint => 'Автосохранение включено';

  @override
  String get detailSealedTitle => 'Запечатанное письмо';

  @override
  String detailSealedBody(String createdDate, String openDate) {
    return 'Ты написал его $createdDate.\nОно откроется $openDate.';
  }

  @override
  String get detailReadyTitle => 'Письмо готово';

  @override
  String detailReadyBody(String createdDate) {
    return 'Ты написал его $createdDate.\nПора прочитать.';
  }

  @override
  String get detailOpenButton => 'Открыть письмо';

  @override
  String get detailLockedHint =>
      'Содержимое надёжно спрятано до назначенного дня.';

  @override
  String detailOpenedAt(String date) {
    return 'Открыто $date';
  }

  @override
  String detailWrittenAt(String date) {
    return 'Написано $date';
  }

  @override
  String get detailDeleteTitle => 'Удалить письмо?';

  @override
  String detailDeleteBody(String title) {
    return '«$title» будет удалено навсегда. Это действие нельзя отменить.';
  }

  @override
  String get detailDeleted => 'Письмо удалено.';

  @override
  String get detailNotFound => 'Письмо не найдено';

  @override
  String get detailNotFoundBody =>
      'Возможно, оно было удалено или ссылка устарела.';

  @override
  String get detailBackHome => 'На главную';

  @override
  String get detailEdit => 'Редактировать';

  @override
  String get detailReschedule => 'Изменить дату';

  @override
  String get detailDelete => 'Удалить';

  @override
  String get rescheduleTitle => 'Когда открыть письмо?';

  @override
  String get rescheduleSuccess => 'Дата открытия обновлена.';

  @override
  String get sealedEditNotAllowed =>
      'Запечатанное письмо нельзя редактировать. Можно изменить только дату открытия.';

  @override
  String get detailSealedBadge => 'До открытия';

  @override
  String get sealStamp => 'ЗАПЕЧАТАНО';

  @override
  String wordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слова',
      many: '$count слов',
      few: '$count слова',
      one: '$count слово',
    );
    return '$_temp0';
  }

  @override
  String get detailLetterFromPast => 'Письмо из прошлого';

  @override
  String get settingsAppearance => 'Оформление';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeOled => 'OLED';

  @override
  String get themeLightDescription => 'Тёплая бумага и мягкие тени.';

  @override
  String get themeDarkDescription => 'Спокойные тёмные поверхности.';

  @override
  String get themeOledDescription => 'Чистый чёрный и высокий контраст.';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageEn => 'English';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsNotificationsEnabled => 'Напоминать об открытии';

  @override
  String get settingsNotificationsDescription =>
      'Системное уведомление придёт, когда письмо будет готово.';

  @override
  String get notificationPermissionStatus => 'Разрешение';

  @override
  String get permissionGranted => 'Разрешено';

  @override
  String get permissionDenied => 'Запрещено';

  @override
  String get permissionNotDetermined => 'Ещё не запрошено';

  @override
  String get permissionUnsupported => 'Не поддерживается на этом устройстве';

  @override
  String get requestPermission => 'Запросить разрешение';

  @override
  String get testNotification => 'Проверить уведомление';

  @override
  String get testNotificationSent => 'Тестовое уведомление отправлено.';

  @override
  String get testNotificationFailed =>
      'Не удалось показать уведомление. Проверь разрешение браузера или системы.';

  @override
  String get testNotificationNeedsPermission => 'Сначала разреши уведомления.';

  @override
  String get openSystemSettings => 'Открыть настройки системы';

  @override
  String get systemSettingsUnavailable =>
      'Системные настройки уведомлений недоступны на этой платформе.';

  @override
  String get notificationLimitationsTitle => 'Возможности платформы';

  @override
  String get notificationLimitationsLinux =>
      'Linux не предоставляет системный планировщик локальных уведомлений. Уведомления придут, пока DearMe запущено; само уведомление при этом системное.';

  @override
  String get notificationLimitationsIos =>
      'iOS хранит не более 64 ожидающих уведомлений. DearMe планирует ближайшие 60, остальные добавит при следующем запуске.';

  @override
  String get notificationLimitationsAndroid =>
      'Android может задерживать фоновую доставку и требовать отключения оптимизации батареи для точного времени.';

  @override
  String get notificationLimitationsWeb =>
      'Уведомления при закрытой вкладке требуют HTTPS, разрешения браузера и настроенного push-сервера. На iOS веб-приложение нужно добавить на экран «Домой». Поддержка зависит от браузера.';

  @override
  String get notificationLimitationsWindows =>
      'Windows доставляет запланированные уведомления. Без MSIX-пакета приложение не может убрать уже показанное уведомление из центра, но отмена запланированного работает.';

  @override
  String get notificationLimitationsMacos =>
      'macOS использует системные уведомления. Разрешение можно изменить в Системных настройках.';

  @override
  String get notificationLimitationsNone =>
      'Платформа поддерживает системные уведомления.';

  @override
  String get notificationLimitationsWebUnsupported =>
      'Этот браузер не поддерживает Web Push или Service Worker, поэтому фоновые уведомления недоступны.';

  @override
  String get pushServerStatus => 'Push-сервер';

  @override
  String get pushServerConnected => 'Подключён';

  @override
  String get pushServerNotConfigured => 'Не настроен';

  @override
  String get pushServerError => 'Нет связи';

  @override
  String get pushServerNotConfiguredHint =>
      'Укажи адрес сервера при сборке: --dart-define=DEARME_PUSH_API=https://…';

  @override
  String get notificationDisableConfirmTitle => 'Отключить уведомления?';

  @override
  String get notificationDisableConfirmBody =>
      'Запланированные напоминания будут отменены. Письма останутся запечатанными и откроются в назначенное время.';

  @override
  String get settingsData => 'Данные';

  @override
  String get dataLetters => 'Писем';

  @override
  String get dataOpened => 'Открыто';

  @override
  String get dataSealed => 'Запечатано';

  @override
  String get dataDrafts => 'Черновиков';

  @override
  String get exportData => 'Экспортировать письма';

  @override
  String get exportDescription => 'Сохранить резервную копию в JSON.';

  @override
  String get importData => 'Импортировать письма';

  @override
  String get importDescription => 'Добавить письма из файла экспорта.';

  @override
  String get deleteAllData => 'Удалить все данные';

  @override
  String get deleteAllDescription => 'Все письма и настройки будут удалены.';

  @override
  String get deleteAllTitle => 'Удалить всё?';

  @override
  String get deleteAllBody =>
      'Все письма будут удалены навсегда. Это действие нельзя отменить.';

  @override
  String deleteAllConfirmHint(String word) {
    return 'Введите $word, чтобы подтвердить.';
  }

  @override
  String get deleteAllConfirmWord => 'УДАЛИТЬ';

  @override
  String get deleteAllAction => 'Удалить всё';

  @override
  String get dataDeleted => 'Все данные удалены.';

  @override
  String get exportSuccess => 'Резервная копия сохранена.';

  @override
  String get exportFailed => 'Не удалось экспортировать письма.';

  @override
  String get importSuccess => 'Импорт завершён.';

  @override
  String importResult(int imported, int updated, int skipped) {
    return 'Добавлено: $imported, обновлено: $updated, пропущено: $skipped.';
  }

  @override
  String get importFailed => 'Не удалось импортировать письма.';

  @override
  String get importInvalid => 'Файл не похож на резервную копию DearMe.';

  @override
  String get importEmpty => 'В этом файле нет писем.';

  @override
  String get importConfirmTitle => 'Импортировать письма?';

  @override
  String importConfirmBody(int count) {
    return 'Найдено писем: $count. Письма с теми же идентификаторами обновятся, если импортированная версия новее.';
  }

  @override
  String get importConfirmAction => 'Импортировать';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String aboutVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get aboutDescription =>
      'DearMe — спокойное место для писем самому себе. Напиши сегодня, прочитай, когда придёт время.';

  @override
  String get aboutLicenses => 'Лицензии с открытым исходным кодом';

  @override
  String get aboutPrivacy => 'Приватность';

  @override
  String get aboutPrivacyBody =>
      'Письма хранятся только на этом устройстве. На push-сервер передаются лишь идентификатор письма, время доставки и технические данные подписки — без текста письма.';

  @override
  String get aboutMadeWith => 'Сделано с заботой о будущем.';

  @override
  String get licensePageTitle => 'Лицензии';

  @override
  String get notificationTitle => 'Твоё письмо из прошлого 💌';

  @override
  String get notificationBody =>
      'Письмо, которое ты написал себе, готово к открытию.';

  @override
  String get notificationChannelName => 'Письма DearMe';

  @override
  String get notificationChannelDescription => 'Напоминания об открытии писем';

  @override
  String get testNotificationTitle => 'DearMe на связи';

  @override
  String get testNotificationBody =>
      'Уведомления настроены. Письма из прошлого найдут тебя.';

  @override
  String get errorNotificationSchedule =>
      'Письмо сохранено, но уведомление запланировать не удалось.';

  @override
  String get errorNotificationPermission =>
      'Разрешение на уведомления не получено.';

  @override
  String get errorNotificationUnsupported =>
      'Уведомления недоступны на этой платформе.';

  @override
  String get errorImportRead => 'Не удалось прочитать выбранный файл.';

  @override
  String get errorImportParse => 'Файл повреждён или имеет неверный формат.';

  @override
  String get errorNoLettersToExport => 'Пока нечего экспортировать.';

  @override
  String get a11yOpenSettings => 'Открыть настройки';

  @override
  String get a11yNewLetter => 'Создать новое письмо';

  @override
  String a11yLetterCard(String title, String status) {
    return 'Письмо «$title», $status';
  }

  @override
  String get a11yBack => 'Назад';

  @override
  String get a11yMore => 'Ещё';

  @override
  String a11yThemeSelected(String theme) {
    return 'Выбрана тема $theme';
  }

  @override
  String a11yLanguageSelected(String language) {
    return 'Выбран язык $language';
  }

  @override
  String get weekdayShortMon => 'Пн';

  @override
  String get weekdayShortTue => 'Вт';

  @override
  String get weekdayShortWed => 'Ср';

  @override
  String get weekdayShortThu => 'Чт';

  @override
  String get weekdayShortFri => 'Пт';

  @override
  String get weekdayShortSat => 'Сб';

  @override
  String get weekdayShortSun => 'Вс';
}
