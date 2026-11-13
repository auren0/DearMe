import 'package:dearme/core/models/app_locale_option.dart';
import 'package:dearme/core/models/app_settings.dart';
import 'package:dearme/core/models/app_theme_option.dart';
import 'package:dearme/core/models/letter.dart';
import 'package:dearme/features/letters/presentation/letter_detail_screen.dart';
import 'package:dearme/features/letters/presentation/letter_editor_screen.dart';
import 'package:dearme/features/settings/presentation/settings_screen.dart';
import 'package:dearme/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_icons_kit/fluent_icons_kit.dart';

import '../support/test_app.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  final ru = lookupAppLocalizations(const Locale('ru'));
  final en = lookupAppLocalizations(const Locale('en'));

  testWidgets('home renders the empty state in Russian by default', (
    tester,
  ) async {
    await pumpTestApp(tester);

    expect(find.text('DearMe'), findsWidgets);
    expect(find.text(ru.emptyTitle), findsOneWidget);
    expect(find.text(ru.homeNewLetter), findsWidgets);
  });

  testWidgets('language changes immediately and is persisted', (tester) async {
    final harness = await pumpTestApp(tester);
    await tapVisible(tester, find.byTooltip(ru.a11yOpenSettings));

    expect(find.byType(SettingsScreen), findsOneWidget);
    await tapVisible(tester, find.text(ru.languageEn));

    expect(find.text(en.settingsTitle), findsOneWidget);
    expect(find.text(en.settingsAppearance), findsOneWidget);
    expect(
      (await harness.settingsRepository.load()).locale,
      AppLocaleOption.english,
    );
  });

  testWidgets('theme changes immediately and is persisted', (tester) async {
    final harness = await pumpTestApp(tester);
    await tapVisible(tester, find.byTooltip(ru.a11yOpenSettings));

    await tapVisible(tester, find.text(ru.themeLight));

    final scaffold = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(scaffold).brightness, Brightness.light);
    expect(
      (await harness.settingsRepository.load()).theme,
      AppThemeOption.light,
    );
  });

  testWidgets(
    'writing and sealing a letter hides its body on the detail screen',
    (tester) async {
      final harness = await pumpTestApp(tester);
      await tapVisible(tester, find.text(ru.homeNewLetter).first);
      expect(find.byType(LetterEditorScreen), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'To future me');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'This body must stay hidden until opening day.',
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text(ru.sealLetter));

      expect(find.text(ru.saveConfirmTitle), findsOneWidget);
      await tapVisible(tester, find.text(ru.saveConfirmAction));

      expect(find.byType(LetterDetailScreen), findsOneWidget);
      final letters = await harness.repository.getAll();
      expect(letters.length, 1);
      expect(letters.single.title, 'To future me');
      expect(letters.single.isDraft, isFalse);
      expect(letters.single.openAt, isNotNull);
      expect(
        letters.single.openAt!.isAfter(DateTime.utc(2026, 6, 1, 12)),
        isTrue,
      );
      expect(find.text('To future me'), findsOneWidget);
      expect(
        find.text('This body must stay hidden until opening day.'),
        findsNothing,
      );
      expect(harness.notifications.scheduled.length, 1);
    },
  );

  testWidgets('a sealed letter cannot reveal its body', (tester) async {
    final now = DateTime.utc(2026, 6, 1, 12);
    final sealed = buildLetter(
      now: now,
      title: 'Sealed thoughts',
      body: 'Top secret body',
      openAt: now.add(const Duration(days: 5)),
    );
    await pumpTestApp(tester, letters: <Letter>[sealed], now: now);
    await tapVisible(tester, find.text('Sealed thoughts'));

    expect(find.byType(LetterDetailScreen), findsOneWidget);
    expect(find.text(ru.detailLockedHint), findsOneWidget);
    expect(find.text('Top secret body'), findsNothing);
    expect(find.text(ru.detailOpenButton), findsNothing);
  });

  testWidgets(
    'a ready letter opens after its date and persists the read state',
    (tester) async {
      final now = DateTime.utc(2026, 6, 1, 12);
      final ready = buildLetter(
        now: now,
        title: 'Ready thoughts',
        body: 'Now it is time to read.',
        openAt: now.subtract(const Duration(days: 1)),
      );
      final harness = await pumpTestApp(
        tester,
        letters: <Letter>[ready],
        now: now,
      );
      await tapVisible(tester, find.text('Ready thoughts'));

      expect(find.text(ru.detailOpenButton), findsOneWidget);
      await tapVisible(tester, find.text(ru.detailOpenButton));
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pumpAndSettle();

      expect(find.text('Now it is time to read.'), findsOneWidget);
      final stored = await harness.repository.getById(ready.id);
      expect(stored?.openedAt, isNotNull);
      expect(harness.notifications.scheduled, isEmpty);
    },
  );

  testWidgets('deleting a letter asks for confirmation and removes it', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 6, 1, 12);
    final sealed = buildLetter(
      now: now,
      title: 'Delete me',
      openAt: now.add(const Duration(days: 5)),
    );
    final harness = await pumpTestApp(
      tester,
      letters: <Letter>[sealed],
      now: now,
    );
    await tapVisible(tester, find.text('Delete me'));

    await tapVisible(tester, find.byIcon(FluentIcons.line.more_vertical));
    await tapVisible(tester, find.text(ru.detailDelete));
    expect(find.text(ru.detailDeleteTitle), findsOneWidget);
    await tapVisible(
      tester,
      find.widgetWithText(FilledButton, ru.detailDelete),
    );

    expect(await harness.repository.getAll(), isEmpty);
    expect(find.text(ru.emptyTitle), findsOneWidget);
  });

  testWidgets('a draft can be deleted from the editor', (tester) async {
    final now = DateTime.utc(2026, 6, 1, 12);
    final draft = buildLetter(
      now: now,
      id: 'draft-delete',
      title: 'Draft to delete',
      isDraft: true,
    );
    final harness = await pumpTestApp(
      tester,
      letters: <Letter>[draft],
      now: now,
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Draft to delete'));
    expect(find.byType(LetterEditorScreen), findsOneWidget);

    await tapVisible(tester, find.text(ru.detailDelete));
    expect(find.text(ru.detailDeleteTitle), findsOneWidget);
    await tapVisible(
      tester,
      find.widgetWithText(FilledButton, ru.detailDelete),
    );

    expect(await harness.repository.getAll(), isEmpty);
    expect(find.text(ru.emptyTitle), findsOneWidget);
  });

  testWidgets('the editor validates required fields', (tester) async {
    await pumpTestApp(tester);
    await tapVisible(tester, find.text(ru.homeNewLetter).first);

    await tapVisible(tester, find.text(ru.sealLetter));

    expect(find.text(ru.editorTitleRequired), findsOneWidget);
    expect(find.text(ru.editorBodyRequired), findsOneWidget);
    expect(find.text(ru.saveConfirmTitle), findsNothing);
  });

  testWidgets('the settings screen shows data counts', (tester) async {
    final now = DateTime.utc(2026, 6, 1, 12);
    final draft = buildLetter(
      now: now,
      id: 'draft-1',
      title: 'Draft title',
      isDraft: true,
    );
    final settings = const AppSettings(
      theme: AppThemeOption.dark,
      locale: AppLocaleOption.russian,
      notificationsEnabled: true,
    );
    await pumpTestApp(
      tester,
      letters: <Letter>[draft],
      settings: settings,
      now: now,
    );
    await tapVisible(tester, find.byTooltip(ru.a11yOpenSettings));

    expect(find.text(ru.dataLetters), findsOneWidget);
    expect(find.text(ru.dataDrafts), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });
}
