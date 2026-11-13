import 'dart:math';

import 'package:uuid/uuid.dart';

import 'letter_status.dart';

/// Immutable letter domain object.
///
/// All instants are stored in UTC. Conversion to the user's local time happens
/// only at the presentation and notification-scheduling boundaries.
class Letter {
  const Letter({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    required this.notificationId,
    required this.isDraft,
    this.openAt,
    this.openedAt,
  });

  static const int schemaVersion = 1;
  static const int maxTitleLength = 120;
  static const int maxBodyLength = 20000;

  final String id;
  final String title;
  final String body;

  /// When the letter was written (UTC).
  final DateTime createdAt;

  /// Last edit time (UTC).
  final DateTime updatedAt;

  /// When the letter may be opened (UTC). Null while an incomplete draft has
  /// no chosen date.
  final DateTime? openAt;

  /// When the user actually opened the letter (UTC). Null means not opened.
  final DateTime? openedAt;

  /// Stable 31-bit identifier used by platform notification schedulers.
  final int notificationId;

  final bool isDraft;

  static const Uuid _uuid = Uuid();
  static final Random _random = Random.secure();

  factory Letter.create({
    required DateTime now,
    String title = '',
    String body = '',
    DateTime? openAt,
    bool isDraft = true,
  }) {
    final createdAt = now.toUtc();
    return Letter(
      id: _uuid.v4(),
      title: title,
      body: body,
      createdAt: createdAt,
      updatedAt: createdAt,
      openAt: openAt?.toUtc(),
      notificationId: _newNotificationId(),
      isDraft: isDraft,
    );
  }

  static int _newNotificationId() => _random.nextInt(0x7fffffff) + 1;

  LetterStatus statusAt(DateTime now) {
    if (isDraft) {
      return LetterStatus.draft;
    }
    if (openedAt != null) {
      return LetterStatus.opened;
    }
    final opening = openAt;
    if (opening == null) {
      return LetterStatus.draft;
    }
    return now.toUtc().isBefore(opening)
        ? LetterStatus.sealed
        : LetterStatus.ready;
  }

  bool canOpenAt(DateTime now) => statusAt(now) == LetterStatus.ready;

  bool get isSealed => !isDraft && openedAt == null;

  bool get isOpened => openedAt != null;

  Letter copyWith({
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? openAt = _unset,
    Object? openedAt = _unset,
    bool? isDraft,
    int? notificationId,
  }) {
    return Letter(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      openAt: identical(openAt, _unset) ? this.openAt : openAt as DateTime?,
      openedAt: identical(openedAt, _unset)
          ? this.openedAt
          : openedAt as DateTime?,
      notificationId: notificationId ?? this.notificationId,
      isDraft: isDraft ?? this.isDraft,
    );
  }

  static const Object _unset = Object();

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'openAt': openAt?.toUtc().toIso8601String(),
      'openedAt': openedAt?.toUtc().toIso8601String(),
      'notificationId': notificationId,
      'isDraft': isDraft,
    };
  }

  /// Tolerant, explicit JSON decoder.
  ///
  /// Returns `null` for records that cannot be understood so that one damaged
  /// record does not make the whole archive unreadable. New fields are ignored
  /// and missing optional fields receive safe defaults.
  static Letter? tryFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = raw.map<String, Object?>(
      (key, value) => MapEntry(key.toString(), value),
    );

    final id = map['id'];
    final title = map['title'];
    final body = map['body'];
    final createdAt = _parseDate(map['createdAt']);
    final updatedAt = _parseDate(map['updatedAt']);

    if (id is! String ||
        id.isEmpty ||
        title is! String ||
        body is! String ||
        createdAt == null ||
        updatedAt == null) {
      return null;
    }

    final openAt = _parseDate(map['openAt']);
    final openedAt = _parseDate(map['openedAt']);
    final rawNotificationId = map['notificationId'];
    final parsedNotificationId = rawNotificationId is int
        ? rawNotificationId & 0x7fffffff
        : 0;
    final notificationId = parsedNotificationId == 0
        ? _newNotificationId()
        : parsedNotificationId;
    final isDraft = map['isDraft'] is bool
        ? map['isDraft']! as bool
        : openAt == null;

    // A draft without a date is valid; anything else must have an opening time.
    if (openAt == null && !isDraft) {
      return null;
    }

    return Letter(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt.toUtc(),
      updatedAt: updatedAt.toUtc(),
      openAt: openAt?.toUtc(),
      openedAt: openedAt?.toUtc(),
      notificationId: notificationId,
      isDraft: isDraft,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    }
    return null;
  }

  int get wordCount {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return 0;
    }
    return trimmed.split(RegExp(r'\s+')).length;
  }

  @override
  String toString() => 'Letter(id: $id, isDraft: $isDraft)';
}
