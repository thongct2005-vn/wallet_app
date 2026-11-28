import 'dart:async';

import 'package:app/core/controller/user_controller.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/kyc/kyc_guide_screen.dart';
import 'package:app/src/services/app_data_service.dart';
import 'package:app/src/services/kyc.service.dart';
import 'package:app/src/services/notification_service.dart';
import 'package:app/src/services/socket_service.dart';
import 'package:app/src/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

class SplashBridge {
  static const MethodChannel _channel = MethodChannel('com.example.app/splash');

  static Future<void> hide() async {
    try {
      await _channel.invokeMethod<void>('hide');
    } catch (_) {}
  }
}

/// Kiểm tra phiên đăng nhập và nạp dữ liệu cần thiết ngay trong lúc Native Splash
/// đang hiển thị, sau đó trả về màn hình đích để vào thẳng app không qua SplashScreen Dart.
Future<Widget> resolveInitialScreen({
  FlutterSecureStorage storage = const FlutterSecureStorage(),
  UserService? userService,
  AppDataService? appDataService,
  KYCService? kycService,
  Future<void> Function(String accessToken)? onAuthenticated,
}) async {
  final userController = Get.isRegistered<UserController>()
      ? Get.find<UserController>()
      : Get.put(UserController(), permanent: true);

  final resolvedUserService = userService ?? UserService();
  final resolvedAppDataService = appDataService ?? AppDataService();
  final resolvedKycService = kycService ?? KYCService();

  try {
    final tokens = await Future.wait<String?>([
      storage.read(key: 'access_token'),
      storage.read(key: 'refresh_token'),
    ]);
    final accessToken = tokens[0];
    final refreshToken = tokens[1];

    if (accessToken == null || refreshToken == null) {
      return const LoginPhoneScreen();
    }

    final results = await Future.wait<Map<String, dynamic>>([
      resolvedUserService.getMe(),
      resolvedAppDataService.fetchHomeData(),
      resolvedKycService.checkUserKYC(),
    ]);

    final userResult = results[0];
    final homeData = results[1];
    final userKyc = results[2];

    if (userResult['is_success'] != true ||
        userResult['user_id'] == null ||
        userKyc['is_success'] != true ||
        userKyc['data'] == null) {
      final userCode = userResult['status_code'];
      final kycCode = userKyc['status_code'];
      if (userCode == 401 || userCode == 403 || kycCode == 401 || kycCode == 403) {
        await _clearAuthTokens(storage);
      }
      return const LoginPhoneScreen();
    }

    userController.setUserData(
      newId: userResult['user_id'].toString(),
      newPhone: (userResult['phone'] ?? '').toString(),
      newFullName: (userResult['full_name'] ?? '').toString(),
      newBalance: (homeData['balance'] ?? '0').toString(),
      newHasPin: homeData['has_pin'] == true,
    );

    // Đọc lại access_token mới nhất phòng trường hợp Future.wait vừa silent refresh token.
    final latestAccessToken =
        (await storage.read(key: 'access_token')) ?? accessToken;

    // Kích hoạt socket & FCM dưới nền để không chặn việc tắt Native Splash.
    final authHook =
        onAuthenticated ??
        (token) => _startBackgroundServices(token, resolvedUserService);
    unawaited(authHook(latestAccessToken));

    final isKyc = userKyc['data']['is_kyc'] == true;
    return isKyc ? const HomeScreen() : const KycGuideScreen();
  } catch (_) {
    return const LoginPhoneScreen();
  }
}

Future<void> _clearAuthTokens(FlutterSecureStorage storage) async {
  try {
    await Future.wait([
      storage.delete(key: 'access_token'),
      storage.delete(key: 'refresh_token'),
    ]);
  } catch (_) {}
}

Future<void> _startBackgroundServices(
  String accessToken,
  UserService userService,
) async {
  await Future.wait([
    SocketService().connect(accessToken: accessToken).catchError((_) {}),
    () async {
      try {
        final fcmToken = await NotificationService().init();
        if (fcmToken != null) {
          await userService.updateFcmToken(fcmToken);
        }
      } catch (_) {}
    }(),
  ]);
}

