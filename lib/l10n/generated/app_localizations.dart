import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In ru, this message translates to:
  /// **'DearMe'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In ru, this message translates to:
  /// **'Письма себе в будущее'**
  String get appTagline;

  /// No description provided for @appDescription.
  ///
  /// In ru, this message translates to:
  /// **'Тихое место, где можно оставить несколько слов тому, кем ты станешь.'**
  String get appDescription;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @disable.
  ///
  /// In ru, this message translates to:
  /// **'Отключить'**
  String get disable;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @back.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get back;

  /// No description provided for @done.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get done;

  /// No description provided for @edit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get edit;

  /// No description provided for @open.
  ///
  /// In ru, this message translates to:
  /// **'Открыть'**
  String get open;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @confirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get confirm;

  /// No description provided for @dismiss.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get dismiss;

  /// No description provided for @ok.
  ///
  /// In ru, this message translates to:
  /// **'Хорошо'**
  String get ok;

  /// No description provided for @refresh.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get refresh;

  /// No description provided for @loading.
  ///
  /// In ru, this message translates to:
  /// **'Загружаем…'**
  String get loading;

  /// No description provided for @unexpectedError.
  ///
  /// In ru, this message translates to:
  /// **'Что-то пошло не так. Попробуй ещё раз.'**
  String get unexpectedError;

  /// No description provided for @storageError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить письма.'**
  String get storageError;

  /// No description provided for @storageWriteError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить изменения.'**
  String get storageWriteError;

  /// No description provided for @storageUnavailableBanner.
  ///
  /// In ru, this message translates to:
  /// **'Хранилище недоступно: письма сохранятся только до перезапуска приложения.'**
  String get storageUnavailableBanner;

  /// No description provided for @settingsSaveError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить настройку.'**
  String get settingsSaveError;

  /// No description provided for @loadErrorTitle.
  ///
  /// In ru, this message translates to:
  /// **'Не получилось загрузить письма'**
  String get loadErrorTitle;

  /// No description provided for @tryAgain.
  ///
  /// In ru, this message translates to:
  /// **'Попробовать снова'**
  String get tryAgain;

  /// No description provided for @offlineOrPermission.
  ///
  /// In ru, this message translates to:
  /// **'Проверь свободное место и разрешения приложения.'**
  String get offlineOrPermission;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In ru, this message translates to:
  /// **'Доброе утро'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In ru, this message translates to:
  /// **'Добрый день'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In ru, this message translates to:
  /// **'Добрый вечер'**
  String get homeGreetingEvening;

  /// No description provided for @homeGreetingNight.
  ///
  /// In ru, this message translates to:
  /// **'Тихой ночи'**
  String get homeGreetingNight;

  /// No description provided for @homeHello.
  ///
  /// In ru, this message translates to:
  /// **'С возвращением.'**
  String get homeHello;

  /// No description provided for @homeSubtitleEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Напиши первое письмо себе в будущее.'**
  String get homeSubtitleEmpty;

  /// No description provided for @homeSummary.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, =0 {Пока ни одного письма. Самое время начать.} one {Одно письмо ждёт своего часа.} few {{count} письма ждут своего часа.} many {{count} писем ждут своего часа.} other {{count} письма ждут своего часа.}}'**
  String homeSummary(int count);

  /// No description provided for @homeSummaryAllRead.
  ///
  /// In ru, this message translates to:
  /// **'Все письма прочитаны. Можно написать новое — будущему себе.'**
  String get homeSummaryAllRead;

  /// No description provided for @homeNewLetter.
  ///
  /// In ru, this message translates to:
  /// **'Написать письмо'**
  String get homeNewLetter;

  /// No description provided for @homeReadySection.
  ///
  /// In ru, this message translates to:
  /// **'Можно открыть'**
  String get homeReadySection;

  /// No description provided for @homeSealedSection.
  ///
  /// In ru, this message translates to:
  /// **'Запечатано'**
  String get homeSealedSection;

  /// No description provided for @homeOpenedSection.
  ///
  /// In ru, this message translates to:
  /// **'Прочитано'**
  String get homeOpenedSection;

  /// No description provided for @homeDraftsSection.
  ///
  /// In ru, this message translates to:
  /// **'Черновики'**
  String get homeDraftsSection;

  /// No description provided for @homeFooterQuote.
  ///
  /// In ru, this message translates to:
  /// **'Некоторые слова лучше прочитать позже.'**
  String get homeFooterQuote;

  /// No description provided for @emptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Пока здесь тихо'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In ru, this message translates to:
  /// **'Твоё первое письмо уже ждёт, чтобы его написали. Выбери день — и оставь будущему себе несколько слов.'**
  String get emptyBody;

  /// No description provided for @emptyAction.
  ///
  /// In ru, this message translates to:
  /// **'Написать первое письмо'**
  String get emptyAction;

  /// No description provided for @emptyDraftsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся черновики'**
  String get emptyDraftsTitle;

  /// No description provided for @emptyDraftsBody.
  ///
  /// In ru, this message translates to:
  /// **'Начни письмо — и оно сохранится автоматически.'**
  String get emptyDraftsBody;

  /// No description provided for @statSealed.
  ///
  /// In ru, this message translates to:
  /// **'Запечатано'**
  String get statSealed;

  /// No description provided for @statReady.
  ///
  /// In ru, this message translates to:
  /// **'Готовы'**
  String get statReady;

  /// No description provided for @statOpened.
  ///
  /// In ru, this message translates to:
  /// **'Прочитано'**
  String get statOpened;

  /// No description provided for @statDrafts.
  ///
  /// In ru, this message translates to:
  /// **'Черновики'**
  String get statDrafts;

  /// No description provided for @statusSealed.
  ///
  /// In ru, this message translates to:
  /// **'Запечатано'**
  String get statusSealed;

  /// No description provided for @statusReady.
  ///
  /// In ru, this message translates to:
  /// **'Готово к открытию'**
  String get statusReady;

  /// No description provided for @statusOpened.
  ///
  /// In ru, this message translates to:
  /// **'Прочитано'**
  String get statusOpened;

  /// No description provided for @statusDraft.
  ///
  /// In ru, this message translates to:
  /// **'Черновик'**
  String get statusDraft;

  /// No description provided for @createdOn.
  ///
  /// In ru, this message translates to:
  /// **'Создано {date}'**
  String createdOn(String date);

  /// No description provided for @opensOn.
  ///
  /// In ru, this message translates to:
  /// **'Откроется {date}'**
  String opensOn(String date);

  /// No description provided for @openedOn.
  ///
  /// In ru, this message translates to:
  /// **'Открыто {date}'**
  String openedOn(String date);

  /// No description provided for @opensIn.
  ///
  /// In ru, this message translates to:
  /// **'До открытия'**
  String get opensIn;

  /// No description provided for @opensNow.
  ///
  /// In ru, this message translates to:
  /// **'Можно открыть сейчас'**
  String get opensNow;

  /// No description provided for @letterCount.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one {{count} письмо} few {{count} письма} many {{count} писем} other {{count} письма}}'**
  String letterCount(int count);

  /// No description provided for @countdownLessThanMinute.
  ///
  /// In ru, this message translates to:
  /// **'меньше минуты'**
  String get countdownLessThanMinute;

  /// No description provided for @countdownDays.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one {{count} день} few {{count} дня} many {{count} дней} other {{count} дня}}'**
  String countdownDays(int count);

  /// No description provided for @countdownHours.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one {{count} час} few {{count} часа} many {{count} часов} other {{count} часа}}'**
  String countdownHours(int count);

  /// No description provided for @countdownMinutes.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one {{count} минута} few {{count} минуты} many {{count} минут} other {{count} минуты}}'**
  String countdownMinutes(int count);

  /// No description provided for @countdownSeconds.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one {{count} секунда} few {{count} секунды} many {{count} секунд} other {{count} секунды}}'**
  String countdownSeconds(int count);

  /// No description provided for @editorNewTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новое письмо'**
  String get editorNewTitle;

  /// No description provided for @editorEditTitle.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать письмо'**
  String get editorEditTitle;

  /// No description provided for @editorTitleLabel.
  ///
  /// In ru, this message translates to:
  /// **'Заголовок'**
  String get editorTitleLabel;

  /// No description provided for @editorTitleHint.
  ///
  /// In ru, this message translates to:
  /// **'О чём это письмо?'**
  String get editorTitleHint;

  /// No description provided for @editorBodyLabel.
  ///
  /// In ru, this message translates to:
  /// **'Письмо'**
  String get editorBodyLabel;

  /// No description provided for @editorBodyHint.
  ///
  /// In ru, this message translates to:
  /// **'Дорогой я в будущем…'**
  String get editorBodyHint;

  /// No description provided for @editorOpenAt.
  ///
  /// In ru, this message translates to:
  /// **'Когда открыть'**
  String get editorOpenAt;

  /// No description provided for @editorOpenDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата открытия'**
  String get editorOpenDate;

  /// No description provided for @editorOpenTime.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get editorOpenTime;

  /// No description provided for @editorChooseDate.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать дату'**
  String get editorChooseDate;

  /// No description provided for @editorChooseTime.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать время'**
  String get editorChooseTime;

  /// No description provided for @editorOpenAtHelper.
  ///
  /// In ru, this message translates to:
  /// **'Письмо будет запечатано до этого момента.'**
  String get editorOpenAtHelper;

  /// No description provided for @editorTitleRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите заголовок.'**
  String get editorTitleRequired;

  /// No description provided for @editorTitleTooLong.
  ///
  /// In ru, this message translates to:
  /// **'Заголовок слишком длинный: максимум {max} символов.'**
  String editorTitleTooLong(int max);

  /// No description provided for @editorBodyRequired.
  ///
  /// In ru, this message translates to:
  /// **'Напишите хотя бы несколько слов.'**
  String get editorBodyRequired;

  /// No description provided for @editorBodyTooLong.
  ///
  /// In ru, this message translates to:
  /// **'Письмо слишком длинное: максимум {max} символов.'**
  String editorBodyTooLong(int max);

  /// No description provided for @editorOpenAtRequired.
  ///
  /// In ru, this message translates to:
  /// **'Выберите дату и время открытия.'**
  String get editorOpenAtRequired;

  /// No description provided for @editorOpenAtFuture.
  ///
  /// In ru, this message translates to:
  /// **'Дата открытия должна быть в будущем.'**
  String get editorOpenAtFuture;

  /// No description provided for @charCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} / {max}'**
  String charCount(int count, int max);

  /// No description provided for @autosaved.
  ///
  /// In ru, this message translates to:
  /// **'Черновик сохранён'**
  String get autosaved;

  /// No description provided for @autosaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить черновик.'**
  String get autosaveFailed;

  /// No description provided for @savedAt.
  ///
  /// In ru, this message translates to:
  /// **'Сохранено в {time}'**
  String savedAt(String time);

  /// No description provided for @discardTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отменить изменения?'**
  String get discardTitle;

  /// No description provided for @discardBody.
  ///
  /// In ru, this message translates to:
  /// **'Несохранённые изменения будут потеряны.'**
  String get discardBody;

  /// No description provided for @discardAction.
  ///
  /// In ru, this message translates to:
  /// **'Выйти без сохранения'**
  String get discardAction;

  /// No description provided for @keepEditing.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить редактирование'**
  String get keepEditing;

  /// No description provided for @saveDraft.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить черновик'**
  String get saveDraft;

  /// No description provided for @sealLetter.
  ///
  /// In ru, this message translates to:
  /// **'Запечатать письмо'**
  String get sealLetter;

  /// No description provided for @saveChanges.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить изменения'**
  String get saveChanges;

  /// No description provided for @saveConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Запечатать письмо?'**
  String get saveConfirmTitle;

  /// No description provided for @saveConfirmBody.
  ///
  /// In ru, this message translates to:
  /// **'Письмо будет запечатано до {date}.'**
  String saveConfirmBody(String date);

  /// No description provided for @saveConfirmAction.
  ///
  /// In ru, this message translates to:
  /// **'Запечатать'**
  String get saveConfirmAction;

  /// No description provided for @sealedSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Письмо запечатано. Увидимся в будущем.'**
  String get sealedSuccess;

  /// No description provided for @draftSaved.
  ///
  /// In ru, this message translates to:
  /// **'Черновик сохранён.'**
  String get draftSaved;

  /// No description provided for @letterUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Письмо обновлено.'**
  String get letterUpdated;

  /// No description provided for @editingSealedNotice.
  ///
  /// In ru, this message translates to:
  /// **'Письмо уже запечатано. Изменения перепланируют уведомление, но содержимое всё равно откроется только в назначенный момент.'**
  String get editingSealedNotice;

  /// No description provided for @draftNotice.
  ///
  /// In ru, this message translates to:
  /// **'Это черновик. Выбери дату и запечатай письмо, когда будешь готов.'**
  String get draftNotice;

  /// No description provided for @datePickerHelp.
  ///
  /// In ru, this message translates to:
  /// **'Выберите день открытия'**
  String get datePickerHelp;

  /// No description provided for @timePickerHelp.
  ///
  /// In ru, this message translates to:
  /// **'Выберите время открытия'**
  String get timePickerHelp;

  /// No description provided for @invalidDate.
  ///
  /// In ru, this message translates to:
  /// **'Некорректная дата.'**
  String get invalidDate;

  /// No description provided for @draftAutosaveHint.
  ///
  /// In ru, this message translates to:
  /// **'Автосохранение включено'**
  String get draftAutosaveHint;

  /// No description provided for @detailSealedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Запечатанное письмо'**
  String get detailSealedTitle;

  /// No description provided for @detailSealedBody.
  ///
  /// In ru, this message translates to:
  /// **'Ты написал его {createdDate}.\nОно откроется {openDate}.'**
  String detailSealedBody(String createdDate, String openDate);

  /// No description provided for @detailReadyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Письмо готово'**
  String get detailReadyTitle;

  /// No description provided for @detailReadyBody.
  ///
  /// In ru, this message translates to:
  /// **'Ты написал его {createdDate}.\nПора прочитать.'**
  String detailReadyBody(String createdDate);

  /// No description provided for @detailOpenButton.
  ///
  /// In ru, this message translates to:
  /// **'Открыть письмо'**
  String get detailOpenButton;

  /// No description provided for @detailLockedHint.
  ///
  /// In ru, this message translates to:
  /// **'Содержимое надёжно спрятано до назначенного дня.'**
  String get detailLockedHint;

  /// No description provided for @detailOpenedAt.
  ///
  /// In ru, this message translates to:
  /// **'Открыто {date}'**
  String detailOpenedAt(String date);

  /// No description provided for @detailWrittenAt.
  ///
  /// In ru, this message translates to:
  /// **'Написано {date}'**
  String detailWrittenAt(String date);

  /// No description provided for @detailDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить письмо?'**
  String get detailDeleteTitle;

  /// No description provided for @detailDeleteBody.
  ///
  /// In ru, this message translates to:
  /// **'«{title}» будет удалено навсегда. Это действие нельзя отменить.'**
  String detailDeleteBody(String title);

  /// No description provided for @detailDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Письмо удалено.'**
  String get detailDeleted;

  /// No description provided for @detailNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Письмо не найдено'**
  String get detailNotFound;

  /// No description provided for @detailNotFoundBody.
  ///
  /// In ru, this message translates to:
  /// **'Возможно, оно было удалено или ссылка устарела.'**
  String get detailNotFoundBody;

  /// No description provided for @detailBackHome.
  ///
  /// In ru, this message translates to:
  /// **'На главную'**
  String get detailBackHome;

  /// No description provided for @detailEdit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get detailEdit;

  /// No description provided for @detailReschedule.
  ///
  /// In ru, this message translates to:
  /// **'Изменить дату'**
  String get detailReschedule;

  /// No description provided for @detailDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get detailDelete;

  /// No description provided for @rescheduleTitle.
  ///
  /// In ru, this message translates to:
  /// **'Когда открыть письмо?'**
  String get rescheduleTitle;

  /// No description provided for @rescheduleSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Дата открытия обновлена.'**
  String get rescheduleSuccess;

  /// No description provided for @sealedEditNotAllowed.
  ///
  /// In ru, this message translates to:
  /// **'Запечатанное письмо нельзя редактировать. Можно изменить только дату открытия.'**
  String get sealedEditNotAllowed;

  /// No description provided for @detailSealedBadge.
  ///
  /// In ru, this message translates to:
  /// **'До открытия'**
  String get detailSealedBadge;

  /// No description provided for @sealStamp.
  ///
  /// In ru, this message translates to:
  /// **'ЗАПЕЧАТАНО'**
  String get sealStamp;

  /// No description provided for @wordCount.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one {{count} слово} few {{count} слова} many {{count} слов} other {{count} слова}}'**
  String wordCount(int count);

  /// No description provided for @detailLetterFromPast.
  ///
  /// In ru, this message translates to:
  /// **'Письмо из прошлого'**
  String get detailLetterFromPast;

  /// No description provided for @settingsAppearance.
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get settingsTheme;

  /// No description provided for @themeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get themeDark;

  /// No description provided for @themeOled.
  ///
  /// In ru, this message translates to:
  /// **'OLED'**
  String get themeOled;

  /// No description provided for @themeLightDescription.
  ///
  /// In ru, this message translates to:
  /// **'Тёплая бумага и мягкие тени.'**
  String get themeLightDescription;

  /// No description provided for @themeDarkDescription.
  ///
  /// In ru, this message translates to:
  /// **'Спокойные тёмные поверхности.'**
  String get themeDarkDescription;

  /// No description provided for @themeOledDescription.
  ///
  /// In ru, this message translates to:
  /// **'Чистый чёрный и высокий контраст.'**
  String get themeOledDescription;

  /// No description provided for @settingsLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get settingsLanguage;

  /// No description provided for @languageRu.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageRu;

  /// No description provided for @languageEn.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @settingsNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsEnabled.
  ///
  /// In ru, this message translates to:
  /// **'Напоминать об открытии'**
  String get settingsNotificationsEnabled;

  /// No description provided for @settingsNotificationsDescription.
  ///
  /// In ru, this message translates to:
  /// **'Системное уведомление придёт, когда письмо будет готово.'**
  String get settingsNotificationsDescription;

  /// No description provided for @notificationPermissionStatus.
  ///
  /// In ru, this message translates to:
  /// **'Разрешение'**
  String get notificationPermissionStatus;

  /// No description provided for @permissionGranted.
  ///
  /// In ru, this message translates to:
  /// **'Разрешено'**
  String get permissionGranted;

  /// No description provided for @permissionDenied.
  ///
  /// In ru, this message translates to:
  /// **'Запрещено'**
  String get permissionDenied;

  /// No description provided for @permissionNotDetermined.
  ///
  /// In ru, this message translates to:
  /// **'Ещё не запрошено'**
  String get permissionNotDetermined;

  /// No description provided for @permissionUnsupported.
  ///
  /// In ru, this message translates to:
  /// **'Не поддерживается на этом устройстве'**
  String get permissionUnsupported;

  /// No description provided for @requestPermission.
  ///
  /// In ru, this message translates to:
  /// **'Запросить разрешение'**
  String get requestPermission;

  /// No description provided for @testNotification.
  ///
  /// In ru, this message translates to:
  /// **'Проверить уведомление'**
  String get testNotification;

  /// No description provided for @testNotificationSent.
  ///
  /// In ru, this message translates to:
  /// **'Тестовое уведомление отправлено.'**
  String get testNotificationSent;

  /// No description provided for @testNotificationFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось показать уведомление. Проверь разрешение браузера или системы.'**
  String get testNotificationFailed;

  /// No description provided for @testNotificationNeedsPermission.
  ///
  /// In ru, this message translates to:
  /// **'Сначала разреши уведомления.'**
  String get testNotificationNeedsPermission;

  /// No description provided for @openSystemSettings.
  ///
  /// In ru, this message translates to:
  /// **'Открыть настройки системы'**
  String get openSystemSettings;

  /// No description provided for @systemSettingsUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Системные настройки уведомлений недоступны на этой платформе.'**
  String get systemSettingsUnavailable;

  /// No description provided for @notificationLimitationsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Возможности платформы'**
  String get notificationLimitationsTitle;

  /// No description provided for @notificationLimitationsLinux.
  ///
  /// In ru, this message translates to:
  /// **'Linux не предоставляет системный планировщик локальных уведомлений. Уведомления придут, пока DearMe запущено; само уведомление при этом системное.'**
  String get notificationLimitationsLinux;

  /// No description provided for @notificationLimitationsIos.
  ///
  /// In ru, this message translates to:
  /// **'iOS хранит не более 64 ожидающих уведомлений. DearMe планирует ближайшие 60, остальные добавит при следующем запуске.'**
  String get notificationLimitationsIos;

  /// No description provided for @notificationLimitationsAndroid.
  ///
  /// In ru, this message translates to:
  /// **'Android может задерживать фоновую доставку и требовать отключения оптимизации батареи для точного времени.'**
  String get notificationLimitationsAndroid;

  /// No description provided for @notificationLimitationsWeb.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления при закрытой вкладке требуют HTTPS, разрешения браузера и настроенного push-сервера. На iOS веб-приложение нужно добавить на экран «Домой». Поддержка зависит от браузера.'**
  String get notificationLimitationsWeb;

  /// No description provided for @notificationLimitationsWindows.
  ///
  /// In ru, this message translates to:
  /// **'Windows доставляет запланированные уведомления. Без MSIX-пакета приложение не может убрать уже показанное уведомление из центра, но отмена запланированного работает.'**
  String get notificationLimitationsWindows;

  /// No description provided for @notificationLimitationsMacos.
  ///
  /// In ru, this message translates to:
  /// **'macOS использует системные уведомления. Разрешение можно изменить в Системных настройках.'**
  String get notificationLimitationsMacos;

  /// No description provided for @notificationLimitationsNone.
  ///
  /// In ru, this message translates to:
  /// **'Платформа поддерживает системные уведомления.'**
  String get notificationLimitationsNone;

  /// No description provided for @notificationLimitationsWebUnsupported.
  ///
  /// In ru, this message translates to:
  /// **'Этот браузер не поддерживает Web Push или Service Worker, поэтому фоновые уведомления недоступны.'**
  String get notificationLimitationsWebUnsupported;

  /// No description provided for @pushServerStatus.
  ///
  /// In ru, this message translates to:
  /// **'Push-сервер'**
  String get pushServerStatus;

  /// No description provided for @pushServerConnected.
  ///
  /// In ru, this message translates to:
  /// **'Подключён'**
  String get pushServerConnected;

  /// No description provided for @pushServerNotConfigured.
  ///
  /// In ru, this message translates to:
  /// **'Не настроен'**
  String get pushServerNotConfigured;

  /// No description provided for @pushServerError.
  ///
  /// In ru, this message translates to:
  /// **'Нет связи'**
  String get pushServerError;

  /// No description provided for @pushServerNotConfiguredHint.
  ///
  /// In ru, this message translates to:
  /// **'Укажи адрес сервера при сборке: --dart-define=DEARME_PUSH_API=https://…'**
  String get pushServerNotConfiguredHint;

  /// No description provided for @notificationDisableConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отключить уведомления?'**
  String get notificationDisableConfirmTitle;

  /// No description provided for @notificationDisableConfirmBody.
  ///
  /// In ru, this message translates to:
  /// **'Запланированные напоминания будут отменены. Письма останутся запечатанными и откроются в назначенное время.'**
  String get notificationDisableConfirmBody;

  /// No description provided for @settingsData.
  ///
  /// In ru, this message translates to:
  /// **'Данные'**
  String get settingsData;

  /// No description provided for @dataLetters.
  ///
  /// In ru, this message translates to:
  /// **'Писем'**
  String get dataLetters;

  /// No description provided for @dataOpened.
  ///
  /// In ru, this message translates to:
  /// **'Открыто'**
  String get dataOpened;

  /// No description provided for @dataSealed.
  ///
  /// In ru, this message translates to:
  /// **'Запечатано'**
  String get dataSealed;

  /// No description provided for @dataDrafts.
  ///
  /// In ru, this message translates to:
  /// **'Черновиков'**
  String get dataDrafts;

  /// No description provided for @exportData.
  ///
  /// In ru, this message translates to:
  /// **'Экспортировать письма'**
  String get exportData;

  /// No description provided for @exportDescription.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить резервную копию в JSON.'**
  String get exportDescription;

  /// No description provided for @importData.
  ///
  /// In ru, this message translates to:
  /// **'Импортировать письма'**
  String get importData;

  /// No description provided for @importDescription.
  ///
  /// In ru, this message translates to:
  /// **'Добавить письма из файла экспорта.'**
  String get importDescription;

  /// No description provided for @deleteAllData.
  ///
  /// In ru, this message translates to:
  /// **'Удалить все данные'**
  String get deleteAllData;

  /// No description provided for @deleteAllDescription.
  ///
  /// In ru, this message translates to:
  /// **'Все письма и настройки будут удалены.'**
  String get deleteAllDescription;

  /// No description provided for @deleteAllTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить всё?'**
  String get deleteAllTitle;

  /// No description provided for @deleteAllBody.
  ///
  /// In ru, this message translates to:
  /// **'Все письма будут удалены навсегда. Это действие нельзя отменить.'**
  String get deleteAllBody;

  /// No description provided for @deleteAllConfirmHint.
  ///
  /// In ru, this message translates to:
  /// **'Введите {word}, чтобы подтвердить.'**
  String deleteAllConfirmHint(String word);

  /// No description provided for @deleteAllConfirmWord.
  ///
  /// In ru, this message translates to:
  /// **'УДАЛИТЬ'**
  String get deleteAllConfirmWord;

  /// No description provided for @deleteAllAction.
  ///
  /// In ru, this message translates to:
  /// **'Удалить всё'**
  String get deleteAllAction;

  /// No description provided for @dataDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Все данные удалены.'**
  String get dataDeleted;

  /// No description provided for @exportSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Резервная копия сохранена.'**
  String get exportSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось экспортировать письма.'**
  String get exportFailed;

  /// No description provided for @importSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Импорт завершён.'**
  String get importSuccess;

  /// No description provided for @importResult.
  ///
  /// In ru, this message translates to:
  /// **'Добавлено: {imported}, обновлено: {updated}, пропущено: {skipped}.'**
  String importResult(int imported, int updated, int skipped);

  /// No description provided for @importFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось импортировать письма.'**
  String get importFailed;

  /// No description provided for @importInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Файл не похож на резервную копию DearMe.'**
  String get importInvalid;

  /// No description provided for @importEmpty.
  ///
  /// In ru, this message translates to:
  /// **'В этом файле нет писем.'**
  String get importEmpty;

  /// No description provided for @importConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Импортировать письма?'**
  String get importConfirmTitle;

  /// No description provided for @importConfirmBody.
  ///
  /// In ru, this message translates to:
  /// **'Найдено писем: {count}. Письма с теми же идентификаторами обновятся, если импортированная версия новее.'**
  String importConfirmBody(int count);

  /// No description provided for @importConfirmAction.
  ///
  /// In ru, this message translates to:
  /// **'Импортировать'**
  String get importConfirmAction;

  /// No description provided for @settingsAbout.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get settingsAbout;

  /// No description provided for @aboutVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutDescription.
  ///
  /// In ru, this message translates to:
  /// **'DearMe — спокойное место для писем самому себе. Напиши сегодня, прочитай, когда придёт время.'**
  String get aboutDescription;

  /// No description provided for @aboutLicenses.
  ///
  /// In ru, this message translates to:
  /// **'Лицензии с открытым исходным кодом'**
  String get aboutLicenses;

  /// No description provided for @aboutPrivacy.
  ///
  /// In ru, this message translates to:
  /// **'Приватность'**
  String get aboutPrivacy;

  /// No description provided for @aboutPrivacyBody.
  ///
  /// In ru, this message translates to:
  /// **'Письма хранятся только на этом устройстве. На push-сервер передаются лишь идентификатор письма, время доставки и технические данные подписки — без текста письма.'**
  String get aboutPrivacyBody;

  /// No description provided for @aboutMadeWith.
  ///
  /// In ru, this message translates to:
  /// **'Сделано с заботой о будущем.'**
  String get aboutMadeWith;

  /// No description provided for @licensePageTitle.
  ///
  /// In ru, this message translates to:
  /// **'Лицензии'**
  String get licensePageTitle;

  /// No description provided for @notificationTitle.
  ///
  /// In ru, this message translates to:
  /// **'Твоё письмо из прошлого 💌'**
  String get notificationTitle;

  /// No description provided for @notificationBody.
  ///
  /// In ru, this message translates to:
  /// **'Письмо, которое ты написал себе, готово к открытию.'**
  String get notificationBody;

  /// No description provided for @notificationChannelName.
  ///
  /// In ru, this message translates to:
  /// **'Письма DearMe'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In ru, this message translates to:
  /// **'Напоминания об открытии писем'**
  String get notificationChannelDescription;

  /// No description provided for @testNotificationTitle.
  ///
  /// In ru, this message translates to:
  /// **'DearMe на связи'**
  String get testNotificationTitle;

  /// No description provided for @testNotificationBody.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления настроены. Письма из прошлого найдут тебя.'**
  String get testNotificationBody;

  /// No description provided for @errorNotificationSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Письмо сохранено, но уведомление запланировать не удалось.'**
  String get errorNotificationSchedule;

  /// No description provided for @errorNotificationPermission.
  ///
  /// In ru, this message translates to:
  /// **'Разрешение на уведомления не получено.'**
  String get errorNotificationPermission;

  /// No description provided for @errorNotificationUnsupported.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления недоступны на этой платформе.'**
  String get errorNotificationUnsupported;

  /// No description provided for @errorImportRead.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать выбранный файл.'**
  String get errorImportRead;

  /// No description provided for @errorImportParse.
  ///
  /// In ru, this message translates to:
  /// **'Файл повреждён или имеет неверный формат.'**
  String get errorImportParse;

  /// No description provided for @errorNoLettersToExport.
  ///
  /// In ru, this message translates to:
  /// **'Пока нечего экспортировать.'**
  String get errorNoLettersToExport;

  /// No description provided for @a11yOpenSettings.
  ///
  /// In ru, this message translates to:
  /// **'Открыть настройки'**
  String get a11yOpenSettings;

  /// No description provided for @a11yNewLetter.
  ///
  /// In ru, this message translates to:
  /// **'Создать новое письмо'**
  String get a11yNewLetter;

  /// No description provided for @a11yLetterCard.
  ///
  /// In ru, this message translates to:
  /// **'Письмо «{title}», {status}'**
  String a11yLetterCard(String title, String status);

  /// No description provided for @a11yBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get a11yBack;

  /// No description provided for @a11yMore.
  ///
  /// In ru, this message translates to:
  /// **'Ещё'**
  String get a11yMore;

  /// No description provided for @a11yThemeSelected.
  ///
  /// In ru, this message translates to:
  /// **'Выбрана тема {theme}'**
  String a11yThemeSelected(String theme);

  /// No description provided for @a11yLanguageSelected.
  ///
  /// In ru, this message translates to:
  /// **'Выбран язык {language}'**
  String a11yLanguageSelected(String language);

  /// No description provided for @weekdayShortMon.
  ///
  /// In ru, this message translates to:
  /// **'Пн'**
  String get weekdayShortMon;

  /// No description provided for @weekdayShortTue.
  ///
  /// In ru, this message translates to:
  /// **'Вт'**
  String get weekdayShortTue;

  /// No description provided for @weekdayShortWed.
  ///
  /// In ru, this message translates to:
  /// **'Ср'**
  String get weekdayShortWed;

  /// No description provided for @weekdayShortThu.
  ///
  /// In ru, this message translates to:
  /// **'Чт'**
  String get weekdayShortThu;

  /// No description provided for @weekdayShortFri.
  ///
  /// In ru, this message translates to:
  /// **'Пт'**
  String get weekdayShortFri;

  /// No description provided for @weekdayShortSat.
  ///
  /// In ru, this message translates to:
  /// **'Сб'**
  String get weekdayShortSat;

  /// No description provided for @weekdayShortSun.
  ///
  /// In ru, this message translates to:
  /// **'Вс'**
  String get weekdayShortSun;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
