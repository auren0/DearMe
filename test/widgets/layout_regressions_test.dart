import 'package:dearme/app/theme/app_theme.dart';
import 'package:dearme/features/letters/presentation/widgets/brand_mark.dart';
import 'package:dearme/features/letters/presentation/widgets/envelope_art.dart';
import 'package:dearme/shared/widgets/grouped_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('the brand mark has no leading letter icon', (tester) async {
    await pumpTestApp(tester);

    expect(find.byType(BrandMark), findsOneWidget);
    expect(
      find.descendant(of: find.byType(BrandMark), matching: find.byType(Icon)),
      findsNothing,
    );
  });

  testWidgets('the envelope seal stays centered in a stretched parent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: SizedBox(
            width: 1000,
            height: 400,
            child: EnvelopeArt(width: 260),
          ),
        ),
      ),
    );

    final envelope = tester.getRect(find.byType(EnvelopeArt));
    final seal = tester.getRect(
      find.byKey(const ValueKey<String>('envelope-wax-seal')),
    );

    expect(seal.center.dx, moreOrLessEquals(envelope.center.dx, epsilon: 0.5));
  });

  testWidgets('theme cards have equal size on a wide screen', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await pumpTestApp(tester);
    await tester.ensureVisible(find.byTooltip('Открыть настройки'));
    await tester.tap(find.byTooltip('Открыть настройки'));
    await tester.pumpAndSettle();

    final light = tester.getSize(
      find.byKey(const ValueKey<String>('theme-light')),
    );
    final dark = tester.getSize(
      find.byKey(const ValueKey<String>('theme-dark')),
    );
    final oled = tester.getSize(
      find.byKey(const ValueKey<String>('theme-oled')),
    );

    expect(dark, light);
    expect(oled, light);
  });

  testWidgets('the export row has square top corners', (tester) async {
    await pumpTestApp(tester);
    await tester.ensureVisible(find.byTooltip('Открыть настройки'));
    await tester.tap(find.byTooltip('Открыть настройки'));
    await tester.pumpAndSettle();

    final exportTile = find.byKey(
      const ValueKey<String>('settings-export-tile'),
    );
    expect(exportTile, findsOneWidget);

    final tile = tester.widget<GroupedSettingsTile>(exportTile);
    expect(tile.position, GroupedTilePosition.middle);

    final material = tester.widget<Material>(
      find.descendant(of: exportTile, matching: find.byType(Material)).first,
    );
    final shape = material.shape! as RoundedRectangleBorder;
    final radius = shape.borderRadius.resolve(TextDirection.ltr);
    expect(radius.topLeft, Radius.zero);
    expect(radius.topRight, Radius.zero);
  });
}
