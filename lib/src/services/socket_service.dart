import 'package:app/core/network/api_config.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as sk;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:app/core/controller/user_controller.dart';
import 'package:app/main.dart';
import 'package:app/src/services/wallet_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  sk.Socket? socket;
  final _storage = const FlutterSecureStorage();

  Future<void> connect() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      return;
    }

    if (socket != null && socket!.connected) {
      return;
    }

    socket = sk.io(
      ApiConfig.socketUrl,
      sk.OptionBuilder()
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

    // Server báo access token của socket đã hết hạn (server cho ~60s để gia hạn)
    socket!.on('token_expired', (_) => _reauthenticate());

    socket!.on('force_logout', (data) {
      debugPrint('[Socket] Nhận force_logout: $data');
      final reason = data is Map
          ? (data['reason'] ?? 'Tài khoản của bạn đã đăng nhập ở thiết bị khác')
          : 'Tài khoản của bạn đã đăng nhập ở thiết bị khác';
      _handleForceLogout(reason);
    });
  }

  // Gọi 1 API có xác thực để interceptor của Dio tự refresh access token nếu đã hết hạn,
  // rồi gửi token mới cho server. Không kịp gia hạn thì server sẽ ngắt socket.
  Future<void> _reauthenticate() async {
    try {
      await WalletService().getWalletBalance();
      final token = await _storage.read(key: 'access_token');
      if (token == null) return;
      socket?.emitWithAck(
        'refresh_auth',
        {'token': token},
        ack: (data) => debugPrint('[Socket] refresh_auth: $data'),
      );
    } catch (e) {
      debugPrint('[Socket] Không gia hạn được token cho socket: $e');
    }
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