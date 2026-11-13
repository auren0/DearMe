import 'dart:convert';
import 'dart:typed_data';

import 'package:dearme/core/models/letter.dart';
import 'package:dearme/features/letters/data/letter_transfer_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTransferGateway implements TransferFileGateway {
  FakeTransferGateway({this.pickResult});

  Uint8List? pickResult;
  String? savedName;
  Uint8List? savedBytes;
  bool saveResult = true;

  @override
  Future<Uint8List?> pickJsonFile() async => pickResult;

  @override
  Future<bool> saveJsonFile({
    required String fileName,
    required Uint8List bytes,
  }) async {
    savedName = fileName;
    savedBytes = bytes;
    return saveResult;
  }
}

void main() {
  final now = DateTime.utc(2026, 6, 1, 12);

  test('encodes and decodes a lossless archive', () {
    final letter = Letter.create(
      now: now,
      title: 'Backup',
      body: 'A long private letter.\nWith two lines.',
      openAt: now.add(const Duration(days: 30)),
      isDraft: false,
    );
    final gateway = FakeTransferGateway();
    final service = LetterTransferService(gateway);

    final encoded = service.encode(<Letter>[letter]);
    final decoded = service.decode(Uint8List.fromList(utf8.encode(encoded)));

    expect(decoded.length, 1);
    expect(decoded.single.id, letter.id);
    expect(decoded.single.title, letter.title);
    expect(decoded.single.body, letter.body);
    expect(decoded.single.openAt, letter.openAt);
    expect(decoded.single.notificationId, letter.notificationId);
  });

  test('export writes bytes through the file gateway', () async {
    final letter = Letter.create(now: now, title: 'Export', body: 'Body');
    final gateway = FakeTransferGateway();
    final service = LetterTransferService(gateway);

    final saved = await service.exportLetters(<Letter>[letter]);
    expect(saved, isTrue);
    expect(gateway.savedName, startsWith('DearMe-backup-'));
    expect(gateway.savedName, endsWith('.json'));
    expect(gateway.savedBytes, isNotNull);
  });

  test('imports a legacy lowercase archive identifier', () {
    final letter = Letter.create(now: now, title: 'Legacy', body: 'Body');
    final legacy = jsonEncode(<String, Object?>{
      'app': 'dearme',
      'formatVersion': 1,
      'letters': <Object?>[letter.toJson()],
    });
    final service = LetterTransferService(FakeTransferGateway());
    final decoded = service.decode(Uint8List.fromList(utf8.encode(legacy)));
    expect(decoded.single.id, letter.id);
  });

  test('export refuses an empty archive', () async {
    final service = LetterTransferService(FakeTransferGateway());
    expect(
      () => service.encode(<Letter>[]),
      throwsA(isA<NoLettersToExportException>()),
    );
  });

  test('import cancellation returns null', () async {
    final service = LetterTransferService(FakeTransferGateway());
    expect(await service.pickForImport(), isNull);
  });

  test('rejects a foreign or damaged backup', () {
    final service = LetterTransferService(FakeTransferGateway());
    expect(
      () => service.decode(Uint8List.fromList(utf8.encode('not json'))),
      throwsA(isA<InvalidBackupException>()),
    );
    expect(
      () => service.decode(
        Uint8List.fromList(
          utf8.encode('{"app":"other","formatVersion":1,"letters":[]}'),
        ),
      ),
      throwsA(isA<InvalidBackupException>()),
    );
    expect(
      () => service.decode(
        Uint8List.fromList(
          utf8.encode('{"app":"dearme","formatVersion":99,"letters":[]}'),
        ),
      ),
      throwsA(isA<InvalidBackupException>()),
    );
  });
}
