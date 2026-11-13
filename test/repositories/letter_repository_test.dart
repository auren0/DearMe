import 'package:dearme/core/database/app_database.dart';
import 'package:dearme/core/models/letter.dart';
import 'package:dearme/features/letters/data/sembast_letter_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  late AppDatabase database;
  late SembastLetterRepository repository;
  final now = DateTime.utc(2026, 6, 1, 12);

  setUp(() async {
    final db = await databaseFactoryMemory.openDatabase(
      'dearme-test-${DateTime.now().microsecondsSinceEpoch}.db',
    );
    database = AppDatabase.fromDatabase(db);
    repository = SembastLetterRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('stores, reads and sorts letters', () async {
    final older = Letter.create(
      now: now.subtract(const Duration(days: 2)),
      title: 'Older',
      body: 'Body',
    );
    final newer = Letter.create(now: now, title: 'Newer', body: 'Body');
    await repository.upsert(older);
    await repository.upsert(newer);

    final all = await repository.getAll();
    expect(all.map((letter) => letter.title), <String>['Newer', 'Older']);
    expect((await repository.getById(newer.id))?.title, 'Newer');
  });

  test('watchAll emits updates after a write', () async {
    final letter = Letter.create(now: now, title: 'Watched', body: 'Body');
    final nextEmission = repository.watchAll().firstWhere(
      (letters) => letters.any((item) => item.id == letter.id),
    );
    await repository.upsert(letter);
    final letters = await nextEmission;
    expect(letters.single.title, 'Watched');
  });

  test('deletes one letter and all letters', () async {
    final letter = Letter.create(now: now, title: 'Gone', body: 'Body');
    await repository.upsert(letter);
    await repository.delete(letter.id);
    expect(await repository.getAll(), isEmpty);

    await repository.upsert(letter);
    await repository.deleteAll();
    expect(await repository.getAll(), isEmpty);
  });

  test('import merges by id and keeps the newest version', () async {
    final original = Letter.create(
      now: now,
      title: 'Original',
      body: 'First body',
    ).copyWith(isDraft: true, updatedAt: now);
    await repository.upsert(original);

    final newer = original.copyWith(
      body: 'Second body',
      updatedAt: now.add(const Duration(days: 1)),
    );
    final stale = original.copyWith(
      body: 'Stale body',
      updatedAt: now.subtract(const Duration(days: 1)),
    );
    final imported = Letter.create(
      now: now,
      title: 'Imported',
      body: 'Imported body',
    );

    final summary = await repository.importAll(<Letter>[
      newer,
      stale,
      imported,
    ]);
    expect(summary.imported, 1);
    expect(summary.updated, 1);
    expect(summary.skipped, 1);

    final all = await repository.getAll();
    expect(all.length, 2);
    final updated = all.firstWhere((letter) => letter.id == original.id);
    expect(updated.body, 'Second body');
  });

  test('a damaged record is skipped instead of failing the archive', () async {
    await database.lettersStore.record('broken').put(database.database, {
      'id': 'broken',
      'title': 'No dates',
    });
    final valid = Letter.create(now: now, title: 'Valid', body: 'Body');
    await repository.upsert(valid);

    final all = await repository.getAll();
    expect(all.length, 1);
    expect(all.single.id, valid.id);
  });
}
