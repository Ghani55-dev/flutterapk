import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../routes/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/core_providers.dart';
import '../../features/notifications/notification_deep_link_parser.dart';

// Background message handler must be a top-level function
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Optionally handle background message analytics here
}

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init(WidgetRef ref) async {
    if (_initialized) return;
    _initialized = true;
    // Android initialization for local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _local.initialize(settings: initSettings, onDidReceiveNotificationResponse: (details) {
      final payload = details.payload;
      if (payload != null && payload.isNotEmpty) {
        _handleTap(payload, ref);
      }
    });

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permissions (iOS)
    if (Platform.isIOS) {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
    }

    // Foreground message handling
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      _showLocalNotification(msg);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      _handleTapFromMessage(msg, ref);
    });

    // Token handling
    _fcm.getToken().then((token) async {
      if (token != null) await _uploadToken(token, ref);
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await _uploadToken(token, ref);
    });

    // Handle when app opened from terminated state
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _handleTapFromMessage(initialMessage, ref);
  }

  Future<void> _showLocalNotification(RemoteMessage msg) async {
    final notification = msg.notification;
    if (notification == null) return;
    final title = notification.title ?? '';
    final body = notification.body ?? '';
    final payload = msg.data['route'] ?? msg.data['payload'] ?? '';

    const androidDetails = AndroidNotificationDetails('incite_channel', 'Incite Notifications', importance: Importance.max, priority: Priority.high);
    const details = NotificationDetails(android: androidDetails);
    await _local.show(id: 0, title: title, body: body, notificationDetails: details, payload: payload);
  }

  void _handleTapFromMessage(RemoteMessage msg, WidgetRef ref) {
    final payload = msg.data['route'] ?? msg.data['payload'] ?? '';
    if (payload.isNotEmpty) _handleTap(payload, ref);
  }

  void _handleTap(String payload, WidgetRef ref) {
    final route = NotificationDeepLinkParser.routeFor(payload);
    if (route == null) return;
    try {
      final router = ref.read(appRouterProvider);
      router.go(route);
    } catch (_) {}
  }

  Future<void> _uploadToken(String token, WidgetRef ref) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('/devices/register/', data: {'token': token, 'platform': Platform.operatingSystem});
    } catch (_) {}
  }
}
