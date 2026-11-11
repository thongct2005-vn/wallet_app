import 'dart:async';
import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/core/widgets/pin_bottomsheet/pin_sheet_common.dart';
export 'package:app/core/widgets/pin_bottomsheet/pin_sheet_common.dart';
import 'package:app/main.dart';
import 'package:app/src/auth/forgot/forgot_phone_screen.dart';
import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:app/src/services/socket_service.dart';
import 'package:app/src/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

Future<void> showCheckPinDialog({
  required BuildContext context,
  required Future<Map<String, dynamic>> Function(String pin) onCheckPin,
  required Future<void> Function(String pinToken) onSuccess,
}) {
  return showSmoothPinBottomSheet(
    context: context,
    builder: (context) => CheckPinBottomSheet(
      onCheckPin: onCheckPin,
      onSuccess: onSuccess,
    ),
  );
}

class CheckPinBottomSheet extends StatefulWidget {
  final Future<Map<String, dynamic>> Function(String pin) onCheckPin;
  final Future<void> Function(String pinToken) onSuccess;
  const CheckPinBottomSheet({
    super.key,
    required this.onCheckPin,
    required this.onSuccess,
  });
  @override
  State<CheckPinBottomSheet> createState() => _CheckPinBottomSheetState();
}

class _CheckPinBottomSheetState extends State<CheckPinBottomSheet> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final GlobalKey<PinCodeInputPillState> _pinInputKey =
      GlobalKey<PinCodeInputPillState>();

  String _errorMsg = '';
  bool _isLoading = false;

  // Trạng thái thử thách bảo mật bổ sung (Step-Up OTP Challenge) khi điểm rủi ro cao
  bool _isChallengeStep = false;
  String _challengeToken = '';
  String _otpMethod = 'email';
  String _maskedEmail = '';
  int _resendCountdown = 0;
  Timer? _resendTimer;
  final WalletService _walletService = WalletService();

  @override
  void initState() {
    super.initState();
    // Đợi frame đầu tiên của sheet dựng & cache GPU xong mới mở bàn phím để không bị khựng frame đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pinInputKey.currentState?.requestKeyboard();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _startResendTimer([int seconds = 60]) {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      } else {
        setState(() => _resendCountdown -= 1);
      }
    });
  }

  Future<void> _onResendChallengeOtp() async {
    if (_isLoading || _resendCountdown > 0 || _challengeToken.isEmpty) return;
    setState(() {
      _errorMsg = '';
      _isLoading = true;
    });
    final res = await _walletService.resendPinChallenge(
      challengeToken: _challengeToken,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (res['is_success'] == true) {
      _startResendTimer(60);
    } else {
      setState(() {
        _errorMsg =
            res['message']?.toString() ?? 'Không thể gửi lại mã xác thực.';
      });
    }
    _pinInputKey.currentState?.requestKeyboard();
  }

  Future<bool> _logoutForResetPin() async {
    final result = await AuthService().logout();
    if (result['is_success'] != true) return false;
    await const FlutterSecureStorage().deleteAll();
    SocketService().disconnect();
    return true;
  }

  Future<void> _onForgotPin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final phone = Get.isRegistered<UserController>()
        ? Get.find<UserController>().phone.value
        : '';
    final confirmed = await DialogUtils.showConfirmationAsync(
      context,
      title: 'Xác nhận',
      message: 'Bạn có chắc chắn muốn đăng xuất để đặt lại mã PIN không?',
      cancelText: 'Hủy',
      confirmText: 'Xác nhận',
      errorMessage: 'Có lỗi khi đăng xuất. Vui lòng thử lại',
      onConfirm: _logoutForResetPin,
    );
    if (confirmed != true) {
      if (mounted) {
        _pinInputKey.currentState?.requestKeyboard();
      }
      return;
    }

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ForgotPhoneScreen(
          type: ForgotType.pin,
          initialPhone: phone,
          lockPhone: phone.isNotEmpty,
        ),
      ),
      (r) => false,
    );
  }

  void _onPinChanged(String value) {
    if (_errorMsg.isNotEmpty && value.isNotEmpty) {
      setState(() => _errorMsg = '');
    }
  }

  Future<void> _onPinCompleted(String pin) async {
    setState(() {
      _errorMsg = '';
      _isLoading = true;
    });

    if (_isChallengeStep) {
      final challengeRes = await _walletService.verifyPinChallenge(
        challengeToken: _challengeToken,
        otp: pin,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (challengeRes['is_success'] == true &&
          challengeRes['is_correct'] == true) {
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.pop(context);
        widget.onSuccess(challengeRes['pin_token']?.toString() ?? '');
      } else {
        setState(() {
          _errorMsg =
              challengeRes['message']?.toString() ??
              'Mã xác thực không chính xác. Vui lòng thử lại.';
        });
        _pinController.clear();
        _pinInputKey.currentState?.requestKeyboard();
      }
      return;
    }

    final result = await widget.onCheckPin(pin);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    if (result['is_success'] == true) {
      if (result['is_correct'] == true) {
        if (result['challenge_required'] == true) {
          setState(() {
            _isChallengeStep = true;
            _challengeToken = result['challenge_token']?.toString() ?? '';
            _otpMethod = result['otp_method']?.toString() ?? 'email';
            _maskedEmail = result['masked_email']?.toString() ?? '';
            _errorMsg = '';
          });
          _pinController.clear();
          if (_otpMethod == 'email') {
            _startResendTimer(60);
          }
          _pinInputKey.currentState?.requestKeyboard();
          return;
        }
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.pop(context);
        widget.onSuccess(result['pin_token']?.toString() ?? '');
      } else {
        final remaining = result['remaining_attempts'];
        setState(() {
          _errorMsg = remaining != null
              ? 'Mã PIN không chính xác. Còn $remaining lần thử.'
              : 'Mã PIN không chính xác. Vui lòng thử lại.';
        });
        _pinController.clear();
        _pinInputKey.currentState?.requestKeyboard();
      }
    } else {
      setState(() {
        _errorMsg =
            result['message']?.toString() ??
            'Đã có lỗi xảy ra. Vui lòng thử lại.';
      });
      _pinController.clear();
      _pinInputKey.currentState?.requestKeyboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PinKeyboardInsetPadding(
      child: PopScope(
        canPop: !_isLoading,
        child: Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              ignoring: _isLoading,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              _isChallengeStep
                                  ? 'Xác thực bảo mật bổ sung'
                                  : 'Nhập mã PIN xác thực',
                              textAlign: TextAlign.center,
                              style: PinSheetStyles.title,
                            ),
                            Positioned(
                              right: 15,
                              child: IconButton(
                                onPressed: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  Navigator.pop(context);
                                },
                                icon: const Icon(
                                  Icons.close,
                                  size: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Divider(
                        height: 0.5,
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                      if (_isChallengeStep)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              _otpMethod == 'totp'
                                  ? 'Phát hiện dấu hiệu bất thường. Vui lòng nhập mã 6 số từ ứng dụng Google Authenticator.'
                                  : 'Phát hiện dấu hiệu bất thường. Vui lòng nhập mã OTP 6 số đã gửi tới email $_maskedEmail.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8D4E00),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 10, 40, 5),
                        child: PinCodeInputPill(
                          key: _pinInputKey,
                          controller: _pinController,
                          focusNode: _pinFocusNode,
                          hasError: _errorMsg.isNotEmpty,
                          onChanged: _onPinChanged,
                          onCompleted: _onPinCompleted,
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        child: Text(_errorMsg, style: PinSheetStyles.error),
                      ),
                      if (!_isChallengeStep)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _isLoading ? null : _onForgotPin,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Text(
                              "Quên mã PIN?",
                              style: PinSheetStyles.forgot,
                            ),
                          ),
                        )
                      else if (_otpMethod == 'email')
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: (_isLoading || _resendCountdown > 0)
                              ? null
                              : _onResendChallengeOtp,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Text(
                              _resendCountdown > 0
                                  ? "Gửi lại mã OTP (${_resendCountdown}s)"
                                  : "Gửi lại mã OTP",
                              style: PinSheetStyles.forgot.copyWith(
                                color: _resendCountdown > 0
                                    ? Colors.grey
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
