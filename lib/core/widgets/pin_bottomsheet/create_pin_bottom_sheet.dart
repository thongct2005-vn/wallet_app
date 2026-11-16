import 'package:app/core/widgets/pin_bottomsheet/pin_sheet_common.dart';
export 'package:app/core/widgets/pin_bottomsheet/pin_sheet_common.dart';
import 'package:flutter/material.dart';

Future<void> showCreatePinDialog({
  required BuildContext context,
  required Future<bool> Function(String pin) onCreatePin,
  required VoidCallback onSuccess,
}) {
  return showSmoothPinBottomSheet(
    context: context,
    builder: (context) => CreatePinBottomSheet(
      onCreatePin: onCreatePin,
      onSuccess: onSuccess,
    ),
  );
}

class CreatePinBottomSheet extends StatefulWidget {
  final Future<bool> Function(String pin) onCreatePin;
  final VoidCallback onSuccess;
  const CreatePinBottomSheet({
    super.key,
    required this.onCreatePin,
    required this.onSuccess,
  });
  @override
  State<CreatePinBottomSheet> createState() => _CreatePinBottomSheetState();
}

class _CreatePinBottomSheetState extends State<CreatePinBottomSheet> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final GlobalKey<PinCodeInputPillState> _pinInputKey =
      GlobalKey<PinCodeInputPillState>();

  bool _isConfirmStep = false;
  String _firstPin = '';
  String _errorMsg = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Đợi frame đầu tiên của sheet dựng & cache GPU xong mới gọi bàn phím để tránh giật frame 1
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pinInputKey.currentState?.requestKeyboard();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _onPinChanged(String value) {
    if (_errorMsg.isNotEmpty && value.isNotEmpty) {
      setState(() => _errorMsg = '');
    }
  }

  Future<void> _onPinCompleted(String pin) async {
    if (!_isConfirmStep) {
      setState(() {
        _firstPin = pin;
        _isConfirmStep = true;
        _errorMsg = '';
      });
      _pinController.clear();
      return;
    }

    if (pin != _firstPin) {
      setState(() {
        _errorMsg = 'Mã PIN không khớp. Vui lòng nhập lại!';
      });
      _pinController.clear();
      _pinInputKey.currentState?.requestKeyboard();
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _errorMsg = '';
      _isLoading = true;
    });
    final bool isSuccess = await widget.onCreatePin(_firstPin);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (isSuccess) {
      Navigator.pop(context);
      widget.onSuccess();
    } else {
      setState(() {
        _errorMsg = 'Có lỗi xảy ra, vui lòng thử lại!';
      });
      _pinController.clear();
      _pinInputKey.currentState?.requestKeyboard();
    }
  }

  void _resetState() {
    setState(() {
      _isConfirmStep = false;
      _errorMsg = '';
      _firstPin = '';
    });
    _pinController.clear();
    _pinInputKey.currentState?.requestKeyboard();
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
                              _isConfirmStep
                                  ? 'Xác nhận mã PIN'
                                  : 'Tạo mã PIN giao dịch',
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
                      const SizedBox(height: 5),
                      Text(
                        _isConfirmStep
                            ? 'Vui lòng nhập lại mã PIN để xác nhận.'
                            : 'Mã PIN gồm 6 số dùng để bảo mật.',
                        style: PinSheetStyles.subtitle,
                      ),
                      const SizedBox(height: 15),
                      Divider(
                        height: 0.5,
                        color: Colors.grey.withValues(alpha: 0.5),
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
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _resetState,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.refresh,
                                size: 18,
                                color: Colors.pink.shade600,
                              ),
                              const SizedBox(width: 5),
                              Text("Đặt lại", style: PinSheetStyles.reset),
                            ],
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
