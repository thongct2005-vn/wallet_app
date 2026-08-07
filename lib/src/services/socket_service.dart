import 'package:app/core/network/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:app/core/controller/user_controller.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;
  final _storage = const FlutterSecureStorage();

  Future<void> connect() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;

    if (socket != null && socket!.connected) return;

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

    socket!.onConnect((_) {
    });

    socket!.onConnectError((err) {
      debugPrint('$err');
    });

    socket!.onDisconnect((_) {});

    _registerListeners();
  }

  void _registerListeners() {
    socket!.on('wallet_balance_updated', (data) {
      final userController = Get.find<UserController>();
      userController.balance.value = data['balance'].toString();

  
    });
  }

  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
  }
}
