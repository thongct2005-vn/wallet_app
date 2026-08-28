import 'package:app/core/network/api_config.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:app/core/controller/user_controller.dart';
import 'package:app/main.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;
  final _storage = const FlutterSecureStorage();

  Future<void> connect() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      return;
    }

    if (socket != null && socket!.connected) {
      return;
    }

    socket = IO.io(
      ApiConfig.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .setExtraHeaders({'ngrok-skip-browser-warning': 'true'})
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {});

    socket!.onConnectError((err) {});

    socket!.onError((err) {});

    socket!.onDisconnect((_) {});
    _registerListeners();
  }

  void _registerListeners() {
    socket!.on('wallet_balance_updated', (data) {
      final userController = Get.find<UserController>();
      userController.balance.value = data['balance'].toString();
    });

    socket!.on('force_logout', (data) {
      debugPrint('[Socket] Nhận force_logout: $data');
      final reason = data is Map
          ? (data['reason'] ?? 'Tài khoản của bạn đã đăng nhập ở thiết bị khác')
          : 'Tài khoản của bạn đã đăng nhập ở thiết bị khác';
      _handleForceLogout(reason);
    });
  }

  Future<void> _handleForceLogout(String reason) async {
    await _storage.deleteAll();

    Future.microtask(() => disconnect());

    if (Get.isRegistered<UserController>()) {
      Get.find<UserController>().clearData();
    }

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPhoneScreen(isForceLogout: true, msg: reason),
      ),
      (route) => false,
    );
  }

  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
  }
}
