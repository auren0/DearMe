import 'package:dearme/core/models/letter.dart';
import 'package:dearme/core/models/letter_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 6, 1, 12);

  group('Letter status', () {
    test('a draft stays a draft even with an opening date', () {
      final letter = Letter.create(
        now: now,
        title: 'Draft',
        body: 'Body',
        openAt: now.add(const Duration(days: 2)),
      );
      expect(letter.statusAt(now), LetterStatus.draft);
    });

    test('a sealed letter becomes ready exactly at the opening instant', () {
      final openAt = now.add(const Duration(hours: 1));
      final letter = Letter.create(
        now: now,
        title: 'Sealed',
        body: 'Body',
        openAt: openAt,
        isDraft: false,
      );
      expect(
        letter.statusAt(openAt.subtract(const Duration(seconds: 1))),
        LetterStatus.sealed,
      );
      expect(letter.statusAt(openAt), LetterStatus.ready);
      expect(
        letter.statusAt(openAt.add(const Duration(days: 1))),
        LetterStatus.ready,
      );
    });

    test('openedAt always wins over time-based status', () {
      final letter = Letter.create(
        now: now,
        title: 'Opened',
        body: 'Body',
        openAt: now.add(const Duration(days: 1)),
        isDraft: false,
      ).copyWith(openedAt: now);
      expect(letter.statusAt(now), LetterStatus.opened);
    });
  });

  group('Letter serialization', () {
    test('round trips all fields in UTC', () {
      final letter = Letter.create(
        now: now,
        title: 'Title',
        body: 'Line one\nLine two',
        openAt: now.add(const Duration(days: 30)),
        isDraft: false,
      ).copyWith(openedAt: now.add(const Duration(days: 31)));

      final decoded = Letter.tryFromJson(letter.toJson());
      expect(decoded, isNotNull);
      expect(decoded!.id, letter.id);
      expect(decoded.title, letter.title);
      expect(decoded.body, letter.body);
      expect(decoded.openAt, letter.openAt);
      expect(decoded.openedAt, letter.openedAt);
      expect(decoded.notificationId, letter.notificationId);
      expect(decoded.isDraft, isFalse);
      expect(decoded.createdAt.isUtc, isTrue);
    });

    test('rejects malformed and impossible records safely', () {
      expect(Letter.tryFromJson(null), isNull);
      expect(Letter.tryFromJson(<String, Object?>{'id': 12}), isNull);
      expect(
        Letter.tryFromJson(<String, Object?>{
          'id': 'x',
          'title': 'Title',
          'body': 'Body',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'isDraft': false,
        }),
        isNull,
      );
    });

    test('a draft without a date is valid', () {
      final draft = Letter.create(now: now, title: 'Draft', body: 'Body');
      final decoded = Letter.tryFromJson(draft.toJson());
      expect(decoded, isNotNull);
      expect(decoded!.openAt, isNull);
      expect(decoded.isDraft, isTrue);
    });
  });

  test('word count ignores surrounding whitespace', () {
    final letter = Letter.create(
      now: now,
      title: 'Words',
      body: '  One two\nthree  ',
    );
    expect(letter.wordCount, 3);
  });
}
