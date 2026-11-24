import 'package:dearme/shared/widgets/grouped_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each group position exposes exactly the intended corners', () {
    const radius = Radius.circular(groupedTileRadius);

    expect(
      groupedTileBorderRadius(GroupedTilePosition.single),
      const BorderRadius.all(radius),
    );
    expect(
      groupedTileBorderRadius(GroupedTilePosition.first),
      const BorderRadius.only(topLeft: radius, topRight: radius),
    );
    expect(
      groupedTileBorderRadius(GroupedTilePosition.middle),
      BorderRadius.zero,
    );
    expect(
      groupedTileBorderRadius(GroupedTilePosition.last),
      const BorderRadius.only(bottomLeft: radius, bottomRight: radius),
    );
  });

  test('positions are derived from the index and group length', () {
    expect(groupedTilePositionAt(0, 1), GroupedTilePosition.single);
    expect(groupedTilePositionAt(0, 3), GroupedTilePosition.first);
    expect(groupedTilePositionAt(1, 3), GroupedTilePosition.middle);
    expect(groupedTilePositionAt(2, 3), GroupedTilePosition.last);
  });

  testWidgets('grouped tiles use matching shapes for background and splash', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupedSettingsGroup(
            children: <Widget>[
              GroupedSettingsTile(title: 'First', onTap: () {}),
              GroupedSettingsTile(title: 'Middle', onTap: () {}),
              GroupedSettingsTile(title: 'Last', onTap: () {}),
            ],
          ),
        ),
      ),
    );

    const expected = <GroupedTilePosition>[
      GroupedTilePosition.first,
      GroupedTilePosition.middle,
      GroupedTilePosition.last,
    ];

    for (var index = 0; index < expected.length; index++) {
      final tileFinder = find.byType(GroupedSettingsTile).at(index);
      final materialFinder = find.descendant(
        of: tileFinder,
        matching: find.byType(Material),
      );
      final inkWellFinder = find.descendant(
        of: tileFinder,
        matching: find.byType(InkWell),
      );
      final listTileFinder = find.descendant(
        of: tileFinder,
        matching: find.byType(ListTile),
      );

      final material = tester.widget<Material>(materialFinder.first);
      final inkWell = tester.widget<InkWell>(inkWellFinder.first);
      final borderRadius = groupedTileBorderRadius(expected[index]);

      expect(
        material.shape,
        RoundedRectangleBorder(borderRadius: borderRadius),
      );
      expect(
        (inkWell.customBorder! as RoundedRectangleBorder).borderRadius,
        borderRadius,
      );

      // The Material and the ListTile must occupy exactly the same rectangle:
      // no transparent strip between ink and row.
      expect(
        tester.getRect(materialFinder.first),
        tester.getRect(listTileFinder.first),
      );
      expect(tester.getRect(tileFinder), tester.getRect(materialFinder.first));
    }
  });

  testWidgets('grouped rows have no extra vertical gap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupedSettingsGroup(
            children: <Widget>[
              GroupedSettingsTile(title: 'First', onTap: () {}),
              GroupedSettingsTile(title: 'Middle', onTap: () {}),
              GroupedSettingsTile(title: 'Last', onTap: () {}),
            ],
          ),
        ),
      ),
    );

    final first = tester.getRect(find.byType(GroupedSettingsTile).at(0));
    final middle = tester.getRect(find.byType(GroupedSettingsTile).at(1));
    final last = tester.getRect(find.byType(GroupedSettingsTile).at(2));

    // A one-pixel divider is the only separation allowed.
    expect(middle.top - first.bottom, moreOrLessEquals(1));
    expect(last.top - middle.bottom, moreOrLessEquals(1));
  });

  testWidgets('a standalone tile is fully rounded', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupedSettingsTile(title: 'Alone', onTap: () {}),
        ),
      ),
    );

    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(GroupedSettingsTile),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(
      material.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(groupedTileRadius)),
      ),
    );
  });
}
