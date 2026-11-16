import 'package:app/core/controller/user_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricAuthResult {
  final bool isSuccess;
  final String? message;

  const BiometricAuthResult({
    required this.isSuccess,
    this.message,
  });
}

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      storageNamespace: 'mio_biometric_secure_prefs',
    ),
    iOptions: IOSOptions(
      accountName: 'mio_biometric_secure_prefs',
    ),
  );

  List<String> _resolveUserKeys({String? phoneOverride}) {
    final keys = <String>{};
    if (phoneOverride != null && phoneOverride.trim().isNotEmpty) {
      keys.add(phoneOverride.trim());
    }
    if (Get.isRegistered<UserController>()) {
      final ctrl = Get.find<UserController>();
      if (ctrl.userId.value.trim().isNotEmpty) {
        keys.add(ctrl.userId.value.trim());
      }
      if (ctrl.phone.value.trim().isNotEmpty) {
        keys.add(ctrl.phone.value.trim());
      }
    }
    if (keys.isEmpty) {
      keys.add('default_user');
    }
    return keys.toList();
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck && !isSupported) return false;
      final available = await _localAuth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    try {
      final keys = _resolveUserKeys();
      for (final k in keys) {
        final enabled = await _storage.read(key: 'bio_enabled_$k');
        final pin = await _storage.read(key: 'bio_pin_$k');
        if (enabled == 'true' && pin != null && pin.length == 6) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getStoredPin() async {
    try {
      final keys = _resolveUserKeys();
      for (final k in keys) {
        final enabled = await _storage.read(key: 'bio_enabled_$k');
        final pin = await _storage.read(key: 'bio_pin_$k');
        if (enabled == 'true' && pin != null && pin.length == 6) {
          return pin;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> enableWithPin(String pin) async {
    final keys = _resolveUserKeys();
    for (final k in keys) {
      await _storage.write(key: 'bio_enabled_$k', value: 'true');
      await _storage.write(key: 'bio_pin_$k', value: pin);
    }
  }

  Future<void> updatePinIfEnabled(String newPin, {String? phoneOverride}) async {
    final keys = _resolveUserKeys(phoneOverride: phoneOverride);
    for (final k in keys) {
      final enabled = await _storage.read(key: 'bio_enabled_$k');
      if (enabled == 'true') {
        await _storage.write(key: 'bio_pin_$k', value: newPin);
      }
    }
  }

  Future<void> disableBiometric({String? phoneOverride}) async {
    final keys = _resolveUserKeys(phoneOverride: phoneOverride);
    for (final k in keys) {
      await _storage.delete(key: 'bio_enabled_$k');
      await _storage.delete(key: 'bio_pin_$k');
    }
  }

  Future<BiometricAuthResult> authenticate({
    required String reason,
  }) async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck && !isSupported) {
        return const BiometricAuthResult(
          isSuccess: false,
          message: 'Thiết bị của bạn không hỗ trợ xác thực vân tay',
        );
      }

      final available = await _localAuth.getAvailableBiometrics();
      if (available.isEmpty) {
        return const BiometricAuthResult(
          isSuccess: false,
          message:
              'Thiết bị chưa đăng ký vân tay. Vui lòng thêm vân tay trong Cài đặt thiết bị',
        );
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        return const BiometricAuthResult(isSuccess: true);
      }
      return const BiometricAuthResult(
        isSuccess: false,
        message: 'Xác thực vân tay không thành công',
      );
    } on PlatformException catch (e) {
      String msg = 'Xác thực vân tay thất bại';
      if (e.code == auth_error.notEnrolled) {
        msg =
            'Thiết bị chưa đăng ký vân tay. Vui lòng thêm vân tay trong Cài đặt';
      } else if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        msg =
            'Xác thực vân tay tạm khóa do thử sai nhiều lần. Vui lòng dùng mã PIN';
      } else if (e.code == auth_error.notAvailable) {
        msg = 'Cảm biến vân tay hiện không khả dụng trên thiết bị';
      } else if (e.code == auth_error.passcodeNotSet) {
        msg = 'Vui lòng thiết lập khóa màn hình trên thiết bị trước';
      }
      return BiometricAuthResult(isSuccess: false, message: msg);
    } catch (_) {
      return const BiometricAuthResult(
        isSuccess: false,
        message: 'Không thể thực hiện xác thực vân tay',
      );
    }
  }
}

