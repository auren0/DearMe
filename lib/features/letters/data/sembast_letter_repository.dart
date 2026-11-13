import 'dart:developer' as developer;

import 'package:sembast/sembast.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/letter.dart';

class ImportSummary {
  const ImportSummary({
    required this.imported,
    required this.updated,
    required this.skipped,
  });

  final int imported;
  final int updated;
  final int skipped;

  int get total => imported + updated + skipped;
}

abstract interface class LetterRepository {
  Future<List<Letter>> getAll();

  Stream<List<Letter>> watchAll();

  Future<Letter?> getById(String id);

  Future<void> upsert(Letter letter);

  Future<void> delete(String id);

  Future<void> deleteAll();

  /// Merges [letters] by id. A newer `updatedAt` wins; an identical or older
  /// version is skipped. The whole merge is transactional.
  Future<ImportSummary> importAll(List<Letter> letters);
}

/// Sembast-backed repository. Native storage is a file, web storage is
/// IndexedDB. Corrupt individual records are skipped instead of making the
/// complete archive unreadable.
class SembastLetterRepository implements LetterRepository {
  SembastLetterRepository(this._database);

  final AppDatabase _database;

  StoreRef<String, Map<String, Object?>> get _store => _database.lettersStore;

  @override
  Future<List<Letter>> getAll() async {
    final records = await _store.find(_database.database);
    final letters = <Letter>[];
    for (final record in records) {
      final letter = _decode(record.value);
      if (letter != null) {
        letters.add(letter);
      }
    }
    _sort(letters);
    return letters;
  }

  @override
  Stream<List<Letter>> watchAll() {
    return _store.query().onSnapshots(_database.database).map((snapshots) {
      final letters = <Letter>[];
      for (final snapshot in snapshots) {
        final letter = _decode(snapshot.value);
        if (letter != null) {
          letters.add(letter);
        }
      }
      _sort(letters);
      return letters;
    });
  }

  @override
  Future<Letter?> getById(String id) async {
    final record = await _store.record(id).get(_database.database);
    return record == null ? null : _decode(record);
  }

  @override
  Future<void> upsert(Letter letter) {
    return _store.record(letter.id).put(_database.database, letter.toJson());
  }

  @override
  Future<void> delete(String id) {
    return _store.record(id).delete(_database.database);
  }

  @override
  Future<void> deleteAll() {
    return _store.delete(_database.database);
  }

  @override
  Future<ImportSummary> importAll(List<Letter> letters) async {
    var imported = 0;
    var updated = 0;
    var skipped = 0;

    await _database.database.transaction((transaction) async {
      for (final letter in letters) {
        final record = _store.record(letter.id);
        final existingJson = await record.get(transaction);
        if (existingJson == null) {
          await record.put(transaction, letter.toJson());
          imported++;
          continue;
        }

        final existing = _decode(existingJson);
        if (existing == null || letter.updatedAt.isAfter(existing.updatedAt)) {
          await record.put(transaction, letter.toJson());
          updated++;
        } else {
          skipped++;
        }
      }
    });

    return ImportSummary(
      imported: imported,
      updated: updated,
      skipped: skipped,
    );
  }

  Letter? _decode(Map<String, Object?> json) {
    final letter = Letter.tryFromJson(json);
    if (letter == null) {
      developer.log('Skipped a damaged letter record.', name: 'dearme.storage');
    }
    return letter;
  }

  void _sort(List<Letter> letters) {
    letters.sort((a, b) {
      final byCreation = b.createdAt.compareTo(a.createdAt);
      return byCreation != 0 ? byCreation : b.id.compareTo(a.id);
    });
  }
}
