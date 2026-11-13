import 'dart:async';

import 'package:dearme/core/models/letter.dart';
import 'package:dearme/features/letters/data/sembast_letter_repository.dart';

class FakeLetterRepository implements LetterRepository {
  FakeLetterRepository([List<Letter>? initial])
    : _letters = <String, Letter>{
        for (final letter in initial ?? const <Letter>[]) letter.id: letter,
      };

  final Map<String, Letter> _letters;
  final StreamController<List<Letter>> _controller =
      StreamController<List<Letter>>.broadcast();

  bool failWrites = false;
  int upsertCount = 0;

  List<Letter> _sorted() {
    final list = _letters.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(_sorted());
    }
  }

  @override
  Future<List<Letter>> getAll() async => _sorted();

  @override
  Stream<List<Letter>> watchAll() async* {
    yield _sorted();
    yield* _controller.stream;
  }

  @override
  Future<Letter?> getById(String id) async => _letters[id];

  @override
  Future<void> upsert(Letter letter) async {
    if (failWrites) {
      throw StateError('write failed');
    }
    upsertCount++;
    _letters[letter.id] = letter;
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    if (failWrites) {
      throw StateError('write failed');
    }
    _letters.remove(id);
    _emit();
  }

  @override
  Future<void> deleteAll() async {
    if (failWrites) {
      throw StateError('write failed');
    }
    _letters.clear();
    _emit();
  }

  @override
  Future<ImportSummary> importAll(List<Letter> letters) async {
    if (failWrites) {
      throw StateError('write failed');
    }
    var imported = 0;
    var updated = 0;
    var skipped = 0;
    for (final letter in letters) {
      final existing = _letters[letter.id];
      if (existing == null) {
        _letters[letter.id] = letter;
        imported++;
      } else if (letter.updatedAt.isAfter(existing.updatedAt)) {
        _letters[letter.id] = letter;
        updated++;
      } else {
        skipped++;
      }
    }
    _emit();
    return ImportSummary(
      imported: imported,
      updated: updated,
      skipped: skipped,
    );
  }

  void dispose() {
    _controller.close();
  }
}
