import 'package:app/core/controller/user_controller.dart';
import 'package:app/src/services/user_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final UserService _userService = UserService();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<String?> init() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotificationsPlugin.initialize(settings: initSettings);

    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
      _handleDataUpdate(message.data);
    });

    _fcm.onTokenRefresh.listen((newToken) {
      _sendTokenToServer(newToken);
    });

    final token = await _fcm.getToken();
    return token;
  }

  Future<void> checkInitialMessage() async {
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleDataUpdate(initialMessage.data);
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    _localNotificationsPlugin.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'wallet_channel',
          'Thông báo ví',
          channelDescription: 'Thông báo giao dịch và cập nhật số dư',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  void _handleDataUpdate(Map<String, dynamic> data) {
    if ((data['type'] == 'RECEIVE_MONEY' || data['type'] == 'SEND_MONEY') &&
        data['balance'] != null) {
      final userController = Get.find<UserController>();
      userController.balance.value = data['balance'].toString();
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    await _userService.updateFcmToken(token);
  }
}
