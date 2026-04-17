import 'dart:developer' as developer;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum OtpNotificationPermissionState { granted, denied, unknown }

class NotificationInitializeResult {
  const NotificationInitializeResult({
    required this.initialized,
    required this.permissionState,
    this.reason,
  });

  final bool initialized;
  final OtpNotificationPermissionState permissionState;
  final String? reason;
}

class NotificationShowResult {
  const NotificationShowResult({
    required this.attempted,
    required this.shown,
    required this.copyActionAvailable,
    required this.permissionState,
    this.reason,
  });

  final bool attempted;
  final bool shown;
  final bool copyActionAvailable;
  final OtpNotificationPermissionState permissionState;
  final String? reason;
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const String _copyOtpActionId = 'copy_otp_action';
  static const String _iosCopyOtpActionId = 'copy_otp_action_ios';
  static const String _iosCopyOtpCategoryId = 'otp_copy_category';
  bool _initialized = false;
  OtpNotificationPermissionState _permissionState =
      OtpNotificationPermissionState.unknown;
  Future<NotificationInitializeResult>? _activeInitialization;

  Future<NotificationInitializeResult> initialize() async {
    if (_initialized) {
      return NotificationInitializeResult(
        initialized: true,
        permissionState: _permissionState,
      );
    }

    if (_activeInitialization != null) {
      return _activeInitialization!;
    }

    _activeInitialization = _initializeInternal();
    final result = await _activeInitialization!;
    _activeInitialization = null;
    return result;
  }

  Future<NotificationInitializeResult> _initializeInternal() async {
    if (_initialized) {
      return NotificationInitializeResult(
        initialized: true,
        permissionState: _permissionState,
      );
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          _iosCopyOtpCategoryId,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(_iosCopyOtpActionId, 'Copy OTP'),
          ],
        ),
      ],
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      _permissionState = await _resolvePermissionState();
      _initialized = true;
      developer.log(
        'Notification service initialized',
        name: 'NotificationService',
      );
      return NotificationInitializeResult(
        initialized: true,
        permissionState: _permissionState,
      );
    } catch (e, stack) {
      developer.log(
        'Failed to initialize notifications',
        name: 'NotificationService',
        error: e,
        stackTrace: stack,
      );
      return NotificationInitializeResult(
        initialized: false,
        permissionState: OtpNotificationPermissionState.unknown,
        reason: 'init_failed',
      );
    }
  }

  Future<OtpNotificationPermissionState> _resolvePermissionState() async {
    if (kIsWeb) {
      return OtpNotificationPermissionState.denied;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidEnabled = await _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled();
        return (androidEnabled ?? false)
            ? OtpNotificationPermissionState.granted
            : OtpNotificationPermissionState.denied;
      case TargetPlatform.iOS:
        final iosGranted = await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: false, badge: false, sound: false);
        return (iosGranted ?? false)
            ? OtpNotificationPermissionState.granted
            : OtpNotificationPermissionState.denied;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return OtpNotificationPermissionState.unknown;
    }
  }

  Future<OtpNotificationPermissionState> _requestPermissions() async {
    if (kIsWeb) {
      return OtpNotificationPermissionState.denied;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        bool androidGranted =
            await androidPlugin?.areNotificationsEnabled() ?? false;
        if (!androidGranted) {
          await androidPlugin?.requestNotificationsPermission();
          androidGranted =
              await androidPlugin?.areNotificationsEnabled() ?? false;
        }
        return androidGranted
            ? OtpNotificationPermissionState.granted
            : OtpNotificationPermissionState.denied;
      case TargetPlatform.iOS:
        final iosGranted = await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return (iosGranted ?? false)
            ? OtpNotificationPermissionState.granted
            : OtpNotificationPermissionState.denied;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return OtpNotificationPermissionState.unknown;
    }
  }

  Future<OtpNotificationPermissionState> ensureNotificationPermission({
    bool requestIfNeeded = true,
  }) async {
    if (!_initialized) {
      final initResult = await initialize();
      _permissionState = initResult.permissionState;
      if (!initResult.initialized) {
        return _permissionState;
      }
    }

    _permissionState = await _resolvePermissionState();
    if (_permissionState == OtpNotificationPermissionState.granted) {
      return _permissionState;
    }

    if (!requestIfNeeded) {
      return _permissionState;
    }

    _permissionState = await _requestPermissions();
    return _permissionState;
  }

  bool _canDisplayNotifications() {
    if (kIsWeb) {
      return false;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return _permissionState == OtpNotificationPermissionState.granted;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        // Desktop platforms do not require runtime prompt in this flow.
        return true;
    }
  }

  Future<NotificationShowResult> showOtpDispatchNotification({
    required String phone,
  }) async {
    if (!_initialized) {
      final initResult = await initialize();
      if (!initResult.initialized) {
        return NotificationShowResult(
          attempted: false,
          shown: false,
          copyActionAvailable: false,
          permissionState: initResult.permissionState,
          reason: initResult.reason ?? 'init_failed',
        );
      }
    }

    await ensureNotificationPermission(requestIfNeeded: true);
    if (!_canDisplayNotifications()) {
      return NotificationShowResult(
        attempted: false,
        shown: false,
        copyActionAvailable: false,
        permissionState: _permissionState,
        reason: 'permission_denied',
      );
    }

    final androidDetails = AndroidNotificationDetails(
      'otp_channel',
      'OTP Notifications',
      channelDescription: 'Secure verification updates for Carbon',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xff2d2c2d),
      timeoutAfter: 120000,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: 'OTP request confirmed',
      interruptionLevel: InterruptionLevel.active,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'OTP Sent',
        'A verification code was sent to ${phone.trim()}. Enter it in the app to continue.',
        details,
      );
      return NotificationShowResult(
        attempted: true,
        shown: true,
        copyActionAvailable: false,
        permissionState: _permissionState,
      );
    } catch (e, stack) {
      developer.log(
        'Failed to show OTP dispatch notification',
        name: 'NotificationService',
        error: e,
        stackTrace: stack,
      );
      return NotificationShowResult(
        attempted: true,
        shown: false,
        copyActionAvailable: false,
        permissionState: _permissionState,
        reason: 'show_failed',
      );
    }
  }

  Future<NotificationShowResult> showOtpNotification({
    required String otp,
    required String phone,
    bool isMock = false,
  }) async {
    final normalizedOtp = otp.trim();
    if (normalizedOtp.isEmpty) {
      return NotificationShowResult(
        attempted: false,
        shown: false,
        copyActionAvailable: false,
        permissionState: _permissionState,
        reason: 'missing_otp',
      );
    }

    if (!_initialized) {
      final initResult = await initialize();
      if (!initResult.initialized) {
        return NotificationShowResult(
          attempted: false,
          shown: false,
          copyActionAvailable: false,
          permissionState: initResult.permissionState,
          reason: initResult.reason ?? 'init_failed',
        );
      }
    }

    await ensureNotificationPermission(requestIfNeeded: true);
    if (!_canDisplayNotifications()) {
      return NotificationShowResult(
        attempted: false,
        shown: false,
        copyActionAvailable: false,
        permissionState: _permissionState,
        reason: 'permission_denied',
      );
    }

    final androidDetails = AndroidNotificationDetails(
      'otp_channel',
      'OTP Notifications',
      channelDescription: 'Secure verification codes for Carbon',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      visibility: NotificationVisibility.public,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          _copyOtpActionId,
          'Copy OTP',
          cancelNotification: false,
        ),
      ],
      styleInformation: BigTextStyleInformation(
        'Your verification code is: $normalizedOtp\n\nCopy the code and paste it into the OTP field. ${isMock ? 'This is a mock OTP flow.' : 'This code will expire in 5 minutes. Do not share with anyone.'}',
        contentTitle: isMock ? '🔐 Carbon Mock OTP' : '🔐 Carbon Security Code',
        summaryText: 'Use Copy OTP action',
      ),
      icon: '@mipmap/ic_launcher',
      color: const Color(0xff2d2c2d),
      timeoutAfter: 300000,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: 'Your verification code',
      categoryIdentifier: _iosCopyOtpCategoryId,
      interruptionLevel: InterruptionLevel.active,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isMock ? '🔐 Carbon Mock OTP' : '🔐 Carbon Security Code',
        'Your verification code is: $normalizedOtp. Tap Copy OTP to copy it.',
        details,
        payload: 'otp:$normalizedOtp;phone:${phone.trim()}',
      );
      developer.log(
        'OTP notification sent successfully',
        name: 'NotificationService',
      );
      return NotificationShowResult(
        attempted: true,
        shown: true,
        copyActionAvailable: true,
        permissionState: _permissionState,
      );
    } catch (e, stack) {
      developer.log(
        'Failed to show OTP notification',
        name: 'NotificationService',
        error: e,
        stackTrace: stack,
      );
      return NotificationShowResult(
        attempted: true,
        shown: false,
        copyActionAvailable: false,
        permissionState: _permissionState,
        reason: 'show_failed',
      );
    }
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  void _onNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    if (actionId != _copyOtpActionId && actionId != _iosCopyOtpActionId) {
      return;
    }

    final otp = _extractOtp(response.payload);
    if (otp == null) {
      developer.log(
        'OTP copy requested without valid payload',
        name: 'NotificationService',
      );
      return;
    }

    unawaited(_copyOtpToClipboard(otp));
  }

  Future<void> _copyOtpToClipboard(String otp) async {
    try {
      await Clipboard.setData(ClipboardData(text: otp));
      developer.log(
        'OTP copied to clipboard from notification action',
        name: 'NotificationService',
      );
    } on PlatformException catch (error, stackTrace) {
      developer.log(
        'Clipboard write failed for OTP copy action',
        name: 'NotificationService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String? _extractOtp(String? payload) {
    final text = (payload ?? '').trim();
    if (text.isEmpty) {
      return null;
    }

    final match = RegExp(r'\b\d{6}\b').firstMatch(text);
    return match?.group(0);
  }
}
