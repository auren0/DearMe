import 'package:dearme/core/models/letter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('home survives a narrow screen with large text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    final now = DateTime.utc(2026, 6, 1, 12);
    final letter = buildLetter(
      now: now,
      title: 'A rather long letter title for accessibility',
      openAt: now.add(const Duration(days: 30)),
    );
    await pumpTestApp(tester, letters: <Letter>[letter], now: now);
    expect(tester.takeException(), isNull);
    expect(find.text('DearMe'), findsWidgets);
  });

  testWidgets('editor survives a narrow screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await pumpTestApp(tester);
    await tester.ensureVisible(find.text('Написать письмо').first);
    await tester.tap(find.text('Написать письмо').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings survive a narrow large-text screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await pumpTestApp(tester);
    await tester.ensureVisible(find.byTooltip('Открыть настройки'));
    await tester.tap(find.byTooltip('Открыть настройки'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('sealed detail survives a narrow large-text screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    final now = DateTime.utc(2026, 6, 1, 12);
    final letter = buildLetter(
      now: now,
      title: 'Sealed on a small phone',
      openAt: now.add(const Duration(days: 30)),
    );
    await pumpTestApp(tester, letters: <Letter>[letter], now: now);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sealed on a small phone'));
    await tester.tap(find.text('Sealed on a small phone'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
