import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../../core/models/letter.dart';

class InvalidBackupException implements Exception {
  const InvalidBackupException([this.message = 'Invalid backup file']);

  final String message;
}

class NoLettersToExportException implements Exception {
  const NoLettersToExportException();
}

/// File-system boundary for import/export. Abstracting it keeps the transfer
/// logic testable without touching native dialogs.
abstract interface class TransferFileGateway {
  Future<Uint8List?> pickJsonFile();

  /// Returns false when the user cancels the save dialog.
  Future<bool> saveJsonFile({
    required String fileName,
    required Uint8List bytes,
  });
}

class FilePickerTransferGateway implements TransferFileGateway {
  const FilePickerTransferGateway();

  @override
  Future<Uint8List?> pickJsonFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
    );
    if (file == null) {
      return null;
    }
    return file.readAsBytes();
  }

  @override
  Future<bool> saveJsonFile({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/json',
      dialogTitle: 'DearMe',
    );
    return uri != null;
  }
}

/// JSON archive codec and transport orchestration.
///
/// The archive deliberately contains the user's letters. It is written only to
/// a location the user chooses and is never uploaded automatically.
class LetterTransferService {
  LetterTransferService(this._gateway);

  static const int formatVersion = 1;
  static const String appIdentifier = 'DearMe';

  final TransferFileGateway _gateway;

  String encode(List<Letter> letters) {
    if (letters.isEmpty) {
      throw const NoLettersToExportException();
    }
    final payload = <String, Object?>{
      'app': appIdentifier,
      'formatVersion': formatVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'letters': letters.map((letter) => letter.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<bool> exportLetters(List<Letter> letters) async {
    final content = encode(letters);
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return _gateway.saveJsonFile(
      fileName: 'DearMe-backup-$date.json',
      bytes: Uint8List.fromList(utf8.encode(content)),
    );
  }

  /// Returns null when the picker was cancelled and throws
  /// [InvalidBackupException] for malformed archives.
  Future<List<Letter>?> pickForImport() async {
    final bytes = await _gateway.pickJsonFile();
    if (bytes == null) {
      return null;
    }
    return decode(bytes);
  }

  List<Letter> decode(Uint8List bytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on Object {
      throw const InvalidBackupException('File is not valid JSON.');
    }

    if (decoded is! Map) {
      throw const InvalidBackupException('Root must be an object.');
    }
    final map = decoded.map<String, Object?>(
      (key, value) => MapEntry(key.toString(), value),
    );
    // Accept the old lowercase format identifier so backups made before the
    // brand casing changed remain importable.
    if (map['app'] != appIdentifier && map['app'] != 'dearme') {
      throw const InvalidBackupException('Not a DearMe archive.');
    }
    final version = map['formatVersion'];
    if (version is! int || version > formatVersion) {
      throw const InvalidBackupException('Unsupported archive version.');
    }
    final rawLetters = map['letters'];
    if (rawLetters is! List) {
      throw const InvalidBackupException('Missing letters array.');
    }

    final letters = <Letter>[];
    for (final raw in rawLetters) {
      final letter = Letter.tryFromJson(raw);
      if (letter != null) {
        letters.add(letter);
      }
    }
    if (letters.isEmpty && rawLetters.isNotEmpty) {
      throw const InvalidBackupException('No valid letters found.');
    }
    return letters;
  }
}
