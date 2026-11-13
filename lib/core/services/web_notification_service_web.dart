import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import 'notification_service.dart';

NotificationService createWebNotificationService() {
  return WebPushNotificationService();
}

/// Real browser notifications and Web Push scheduling.
///
/// Browser notifications cannot be scheduled reliably by a page, so the
/// schedule is stored by the DearMe push backend and delivered by a service
/// worker. The client sends only the letter id, its opening instant, the locale
/// and the technical push subscription. Letter text never leaves the browser.
class WebPushNotificationService implements NotificationService {
  WebPushNotificationService({http.Client? client})
    : _client = client ?? http.Client();

  static const String _apiBase = String.fromEnvironment('DEARME_PUSH_API');
  static const String _tokenKey = 'dearme.push.token';
  static const String _endpointKey = 'dearme.push.endpoint';

  final http.Client _client;
  final Map<String, String> _headers = <String, String>{
    'content-type': 'application/json',
  };

  String? _vapidPublicKey;
  String _localeCode = 'ru';
  VoidCallback? _onSubscriptionChanged;
  bool _serverReachable = false;
  String? _deviceToken;
  String? _subscriptionEndpoint;
  bool _initialized = false;

  bool get _apiConfigured => _apiBase.trim().isNotEmpty;

  bool get _isSupported {
    try {
      // Accessing these members is the reliable capability check; some
      // browsers expose them as inherited globals that `hasProperty` misses.
      web.Notification.permission;
      web.window.navigator.serviceWorker;
      return web.window.getProperty<JSAny?>('PushManager'.toJS) != null;
    } on Object {
      return false;
    }
  }

  @override
  NotificationPlatformInfo get platformInfo {
    return NotificationPlatformInfo(
      isWeb: true,
      supportsNativeScheduling: false,
      requiresRunningApp: false,
      supportsSystemSettings: false,
      supportsWebPush: _isSupported,
      webPushConfigured: _apiConfigured,
      platformName: 'web',
    );
  }

  @override
  Future<void> initialize({
    required ValueChanged<String> onTap,
    VoidCallback? onSubscriptionChanged,
  }) async {
    _onSubscriptionChanged = onSubscriptionChanged;
    if (_initialized) {
      return;
    }
    try {
      web.window.navigator.serviceWorker.addEventListener(
        'message',
        ((web.MessageEvent event) {
          final data = event.data;
          if (data == null || !data.isA<JSObject>()) {
            return;
          }
          final type = (data as JSObject)
              .getProperty<JSString?>('type'.toJS)
              ?.toDart;
          if (type == 'dearme-push-subscription-changed') {
            _onSubscriptionChanged?.call();
          }
        }).toJS,
      );
    } on Object {
      // The subscription will still be refreshed on the next successful sync.
    }
    _deviceToken = web.window.localStorage.getItem(_tokenKey);
    _subscriptionEndpoint = web.window.localStorage.getItem(_endpointKey);

    if (_apiConfigured) {
      try {
        final config = await _fetchJson('GET', '/api/config');
        _vapidPublicKey = config['vapidPublicKey'] as String?;
        _serverReachable =
            _vapidPublicKey != null && _vapidPublicKey!.isNotEmpty;
      } on Object {
        _serverReachable = false;
      }
    }
    _initialized = true;
  }

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    if (!_isSupported) {
      return NotificationPermissionStatus.unsupported;
    }
    try {
      return switch (web.Notification.permission) {
        'granted' => NotificationPermissionStatus.granted,
        'denied' => NotificationPermissionStatus.denied,
        _ => NotificationPermissionStatus.notDetermined,
      };
    } on Object {
      return NotificationPermissionStatus.unsupported;
    }
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    if (!_isSupported) {
      return NotificationPermissionStatus.unsupported;
    }
    try {
      final result = await web.Notification.requestPermission().toDart;
      return switch (result.toDart) {
        'granted' => NotificationPermissionStatus.granted,
        'denied' => NotificationPermissionStatus.denied,
        _ => NotificationPermissionStatus.notDetermined,
      };
    } on Object {
      return NotificationPermissionStatus.denied;
    }
  }

  @override
  Future<void> synchronize({
    required List<ScheduledLetter> letters,
    required String localeCode,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    _localeCode = localeCode;
    if (!_isSupported) {
      throw const NotificationException('Web Push is not supported.');
    }
    if (!_apiConfigured) {
      throw const NotificationException(
        'The Web Push backend is not configured.',
      );
    }
    if (!(await permissionStatus()).isGranted) {
      throw const NotificationException('Notification permission is missing.');
    }

    await _ensureConfiguration();
    final token = await _ensureSubscription();
    final payload = <String, Object?>{
      'locale': localeCode,
      'clickBaseUrl': _clickBaseUrl(),
      'userAgent': web.window.navigator.userAgent,
      'letters': [
        for (final letter in letters)
          <String, Object?>{
            'id': letter.letterId,
            'openAt': letter.openAt.toUtc().toIso8601String(),
          },
      ],
    };
    await _authorizedRequest(
      method: 'PUT',
      path: '/api/schedule',
      token: token,
      body: payload,
    );
    _serverReachable = true;
  }

  @override
  Future<void> cancelAllScheduled() async {
    final token = _deviceToken;
    if (!_apiConfigured || token == null || !_isSupported) {
      return;
    }
    try {
      await _authorizedRequest(
        method: 'PUT',
        path: '/api/schedule',
        token: token,
        body: <String, Object?>{
          'locale': _localeCode,
          'clickBaseUrl': _clickBaseUrl(),
          'letters': const <Object?>[],
        },
      );
    } on Object {
      // Turning notifications off must never fail because the server is
      // temporarily unavailable. The stale server schedule will be replaced on
      // the next successful sync.
    }
  }

  @override
  Future<bool> showTest({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    if (!_isSupported) {
      return false;
    }
    if (!(await permissionStatus()).isGranted) {
      return false;
    }

    final token = _deviceToken;
    if (_apiConfigured && token != null) {
      try {
        await _ensureConfiguration();
        await _authorizedRequest(
          method: 'POST',
          path: '/api/test',
          token: token,
          body: <String, Object?>{'locale': _localeCode},
        );
        return true;
      } on Object {
        // Fall through to an immediate, local browser notification.
      }
    }

    try {
      final registration = await _ensureServiceWorker();
      await registration
          .showNotification(
            title,
            web.NotificationOptions(
              body: body,
              tag: 'dearme-test',
              renotify: true,
              icon: Uri.base.resolve('icons/Icon-192.png').toString(),
            ),
          )
          .toDart;
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> openSystemSettings() async {
    // Browsers intentionally do not expose a deep link to their notification
    // permission UI. The user changes it in site settings.
    return false;
  }

  @override
  Future<PushServerStatus> pushServerStatus() async {
    if (!_apiConfigured) {
      return PushServerStatus.notConfigured;
    }
    try {
      await _ensureConfiguration();
      return _serverReachable
          ? PushServerStatus.connected
          : PushServerStatus.unreachable;
    } on Object {
      return PushServerStatus.unreachable;
    }
  }

  @override
  Future<String?> takeLaunchPayload() async {
    try {
      final letter = Uri.base.queryParameters['letter'];
      if (letter == null || letter.isEmpty) {
        return null;
      }
      final query = Map<String, String>.from(Uri.base.queryParameters)
        ..remove('letter');
      final cleaned = Uri.base.replace(
        queryParameters: query.isEmpty ? null : query,
      );
      web.window.history.replaceState(null, '', cleaned.toString());
      return 'letter:$letter';
    } on Object {
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    _client.close();
  }

  Future<void> _ensureConfiguration() async {
    if (!_apiConfigured) {
      throw const NotificationException('Push backend is not configured.');
    }
    if (_vapidPublicKey != null && _vapidPublicKey!.isNotEmpty) {
      _serverReachable = true;
      return;
    }
    try {
      final config = await _fetchJson('GET', '/api/config');
      _vapidPublicKey = config['vapidPublicKey'] as String?;
      if (_vapidPublicKey == null || _vapidPublicKey!.isEmpty) {
        throw const NotificationException('VAPID public key is missing.');
      }
      _serverReachable = true;
    } on Object catch (error) {
      _serverReachable = false;
      throw NotificationException('Push server is unreachable.', error);
    }
  }

  Future<String> _ensureSubscription() async {
    final permission = await permissionStatus();
    if (!permission.isGranted) {
      throw const NotificationException('Notification permission is missing.');
    }

    final registration = await _ensureServiceWorker();
    var subscription = await registration.pushManager
        .getSubscription()
        .toDart
        .timeout(const Duration(seconds: 12));
    if (subscription == null) {
      final key = _decodeBase64Url(_vapidPublicKey!);
      subscription = await registration.pushManager
          .subscribe(
            web.PushSubscriptionOptionsInit(
              userVisibleOnly: true,
              applicationServerKey: key.toJS,
            ),
          )
          .toDart
          .timeout(const Duration(seconds: 25));
    }

    final endpoint = subscription.endpoint;
    if (_deviceToken != null && _subscriptionEndpoint == endpoint) {
      return _deviceToken!;
    }

    final p256dh = subscription.getKey('p256dh');
    final auth = subscription.getKey('auth');
    if (p256dh == null || auth == null) {
      throw const NotificationException(
        'The browser returned an incomplete push subscription.',
      );
    }

    final response = await _fetchJson(
      'POST',
      '/api/subscriptions',
      body: <String, Object?>{
        'subscription': <String, Object?>{
          'endpoint': endpoint,
          'keys': <String, Object?>{
            'p256dh': _encodeBase64Url(p256dh.toDart.asUint8List()),
            'auth': _encodeBase64Url(auth.toDart.asUint8List()),
          },
        },
        'locale': _localeCode,
        'clickBaseUrl': _clickBaseUrl(),
        'userAgent': web.window.navigator.userAgent,
      },
    );

    final token = response['deviceToken'] as String?;
    if (token == null || token.isEmpty) {
      throw const NotificationException(
        'The push server did not issue a token.',
      );
    }

    _deviceToken = token;
    _subscriptionEndpoint = endpoint;
    web.window.localStorage.setItem(_tokenKey, token);
    web.window.localStorage.setItem(_endpointKey, endpoint);
    return token;
  }

  Future<web.ServiceWorkerRegistration> _ensureServiceWorker() async {
    final container = web.window.navigator.serviceWorker;
    final scriptUrl = Uri.base.resolve('push_service_worker.js').toString();
    final scopeUrl = Uri.base.resolve('push-scope/').toString();

    var registration = await container
        .register(
          scriptUrl.toJS,
          web.RegistrationOptions(scope: scopeUrl, updateViaCache: 'none'),
        )
        .toDart
        .timeout(const Duration(seconds: 15));

    // `navigator.serviceWorker.ready` resolves for a worker that controls the
    // current page. Our push worker intentionally has a narrow scope and does
    // not control the page, so wait for *this registration's* activation.
    if (registration.active == null) {
      for (var attempt = 0; attempt < 60; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final latest = await container
            .getRegistration(scopeUrl)
            .toDart
            .timeout(const Duration(seconds: 4));
        if (latest?.active != null) {
          registration = latest!;
          break;
        }
      }
    }
    return registration;
  }

  Future<String> _authorizedRequest({
    required String method,
    required String path,
    required String token,
    required Map<String, Object?> body,
    bool allowRetry = true,
  }) async {
    try {
      final uri = Uri.parse(
        '${_apiBase.replaceFirst(RegExp(r'/+$'), '')}$path',
      );
      final request = http.Request(method, uri)
        ..headers.addAll(_headers)
        ..headers['authorization'] = 'Bearer $token'
        ..body = jsonEncode(body);
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 401 || response.statusCode == 404) {
        if (!allowRetry) {
          throw NotificationException(
            'Push server rejected the subscription (${response.statusCode}).',
          );
        }
        // The server lost the subscription or token. Re-register once.
        _deviceToken = null;
        _subscriptionEndpoint = null;
        web.window.localStorage.removeItem(_tokenKey);
        web.window.localStorage.removeItem(_endpointKey);
        final newToken = await _ensureSubscription();
        return await _authorizedRequest(
          method: method,
          path: path,
          token: newToken,
          body: body,
          allowRetry: false,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw NotificationException(
          'Push server returned ${response.statusCode}.',
        );
      }
      return response.body;
    } on NotificationException {
      rethrow;
    } on Object catch (error) {
      _serverReachable = false;
      throw NotificationException('Push request failed.', error);
    }
  }

  Future<Map<String, Object?>> _fetchJson(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final uri = Uri.parse('${_apiBase.replaceFirst(RegExp(r'/+$'), '')}$path');
    final request = http.Request(method, uri)..headers.addAll(_headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }
    final streamed = await _client
        .send(request)
        .timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NotificationException(
        'Push server returned ${response.statusCode}.',
      );
    }
    if (response.body.isEmpty) {
      return const <String, Object?>{};
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const NotificationException('Unexpected push server response.');
    }
    return decoded.map<String, Object?>(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  Uint8List _decodeBase64Url(String value) {
    final normalized = base64Url.normalize(value);
    return base64Url.decode(normalized);
  }

  String _encodeBase64Url(Uint8List bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _clickBaseUrl() {
    final base = Uri.base;
    final path = base.path.isEmpty ? '/' : base.path;
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: path,
    ).toString();
  }
}
