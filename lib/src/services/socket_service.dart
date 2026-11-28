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
  Future<void>? _connectFuture;

  Future<void> connect({String? accessToken}) {
    if (socket != null && socket!.connected) {
      return Future.value();
    }
    return _connectFuture ??= _connectInternal(accessToken: accessToken)
        .whenComplete(() {
          _connectFuture = null;
        });
  }

  String? _currentAuthToken;

  Future<void> syncAuthToken(String accessToken) async {
    if (accessToken.isEmpty || socket == null) {
      return;
    }

    if (socket!.connected) {
      if (_currentAuthToken == accessToken) {
        return;
      }
      _currentAuthToken = accessToken;
      socket!.emit('refresh_auth', {'token': accessToken});
      final options = socket!.io.options;
      if (options is Map) {
        options['auth'] = {'token': accessToken};
      }
      return;
    }

    await _connectInternal(accessToken: accessToken);
  }

  Future<void> _connectInternal({String? accessToken}) async {
    final token = accessToken ?? await _storage.read(key: 'access_token');
    if (token == null) {
      return;
    }

    if (socket != null && socket!.connected) {
      await syncAuthToken(token);
      return;
    }

    if (socket != null) {
      socket!.dispose();
      socket = null;
    }

    _currentAuthToken = token;
    socket = sk.io(
      ApiConfig.socketUrl,
      sk.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .setExtraHeaders({'ngrok-skip-browser-warning': 'true'})
          .build(),
    );

    socket!.onConnect((_) {});

    socket!.onConnectError((err) {});

    socket!.onError((err) {});

    socket!.onDisconnect((_) {});
    _registerListeners();

    socket!.connect();
  }

  void _registerListeners() {
    socket!.on('wallet_balance_updated', (data) {
      if (!Get.isRegistered<UserController>() || data is! Map) return;
      final balance = data['balance'];
      if (balance == null) return;
      Get.find<UserController>().balance.value = balance.toString();
    });

    socket!.on('postpaid_wallet_updated', (data) {
      if (!Get.isRegistered<UserController>()) return;
      final userController = Get.find<UserController>();
      if (data is Map) {
        userController.notifyPostpaidUpdated(Map<String, dynamic>.from(data));
      } else {
        userController.postpaidRefreshTick.value++;
      }
    });

    socket!.on('token_expired', (_) => _reauthenticate());

    socket!.on('force_logout', (data) {
      final reason = data is Map
          ? (data['reason'] ?? 'Tài khoản của bạn đã đăng nhập ở thiết bị khác')
          : 'Tài khoản của bạn đã đăng nhập ở thiết bị khác';
      _handleForceLogout(reason);
    });
  }

  Future<void> _reauthenticate() async {
    try {
      await WalletService().getWalletBalance();
      final token = await _storage.read(key: 'access_token');
      if (token == null) return;
      socket?.emitWithAck('refresh_auth', {'token': token}, ack: (data) => {});
    } catch (e) {
      return;
    }
  }

  Future<void> _handleForceLogout(String reason) async {
    final deviceId = await _storage.read(key: 'device_id');
    await _storage.deleteAll();
    if (deviceId != null && deviceId.isNotEmpty) {
      await _storage.write(key: 'device_id', value: deviceId);
    }

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
