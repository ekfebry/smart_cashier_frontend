import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFirebaseInitialized = false;

  Future<void> initialize() async {
    // Skip Firebase initialization on web since it requires configuration
    if (!kIsWeb) {
      try {
        // Initialize Firebase (only if configured and not on web)
        await Firebase.initializeApp();
        _isFirebaseInitialized = true;
        _firebaseMessaging = FirebaseMessaging.instance;

        // Request permissions
        await _requestPermissions();

        // Get FCM token
        final token = await _firebaseMessaging!.getToken();
        // FCM Token: $token

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle when app is opened from notification
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      } catch (e) {
        _isFirebaseInitialized = false;
      }
    } else {
      _isFirebaseInitialized = false;
    }

    // Always initialize local notifications
    try {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(settings);
    } catch (localError) {
      // Handle local notification initialization error
    }
  }

  Future<void> _requestPermissions() async {
    if (!_isFirebaseInitialized || _firebaseMessaging == null) return;

    NotificationSettings settings = await _firebaseMessaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {

    // Show local notification
    await _showLocalNotification(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    // Handle navigation based on notification data
    _handleNotificationNavigation(message.data);
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'smart_cashier_channel',
      'Smart Cashier Notifications',
      channelDescription: 'Notifications for orders and promotions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Handle different types of notifications
    final type = data['type'];
    final orderId = data['order_id'];

    switch (type) {
      case 'order_status':
        // Navigate to order details
        break;
      case 'promotion':
        // Navigate to promotions
        break;
      default:
        // Unknown notification type
        break;
    }
  }

  Future<String?> getToken() async {
    if (!_isFirebaseInitialized || _firebaseMessaging == null) return null;
    return await _firebaseMessaging!.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    if (!_isFirebaseInitialized || _firebaseMessaging == null) return;
    await _firebaseMessaging!.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_isFirebaseInitialized || _firebaseMessaging == null) return;
    await _firebaseMessaging!.unsubscribeFromTopic(topic);
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Skip Firebase initialization on web
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }
}
