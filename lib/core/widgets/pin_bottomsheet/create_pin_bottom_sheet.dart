import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

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
  bool _isConfirmStep = false;
  String _firstPin = '';
  String _errorMsg = '';
  bool _isLoading = false;
  bool _isShowPin = false;

  @override
  void dispose() {
    super.dispose();
    _pinController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 18,
      height: 18,

      margin: const EdgeInsets.symmetric(horizontal: 1),

      textStyle: GoogleFonts.roboto(
        fontSize: 15,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      textStyle: const TextStyle(color: Colors.transparent),
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
    );

    final visiblePinTheme = defaultPinTheme.copyWith(
      decoration: const BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
      ),
    );

    final isPinComplete = _pinController.text.length == 6;
    final effectiveFocusedPinTheme = isPinComplete
    ? (_isShowPin ? visiblePinTheme : submittedPinTheme)
    : defaultPinTheme;

    return PopScope(
      canPop: !_isLoading,
      child: Padding(
        padding: EdgeInsetsGeometry.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              ignoring: _isLoading,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(top: 6),
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
                            style: GoogleFonts.roboto(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Positioned(
                            right: 15,
                            child: IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: Icon(
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
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Divider(
                      height: 0.5,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    Padding(
                      padding: EdgeInsetsGeometry.fromLTRB(40, 10, 40, 5),
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.white,
                          border: Border.all(
                            width: 0.5,
                            color: _errorMsg.isEmpty
                                ? Colors.grey.withValues(alpha: 0.5)
                                : Colors.red,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Pinput(
                              closeKeyboardWhenCompleted: false,
                              showCursor: false,
                              controller: _pinController,
                              length: 6,
                              defaultPinTheme: defaultPinTheme,
                              focusedPinTheme: effectiveFocusedPinTheme,
                              submittedPinTheme: _isShowPin
                                  ? visiblePinTheme
                                  : submittedPinTheme,
                              obscureText: !_isShowPin,
                              obscuringCharacter: '●',
                              keyboardType: TextInputType.number,
                              autofocus: true,
                              onChanged: (value) {
                                setState(() {});
                              },
                              onCompleted: (pin) async {
                                
                                setState(() => _errorMsg = '');
                                if (!_isConfirmStep) {
                                  setState(() {
                                    _firstPin = pin;
                                    _isConfirmStep = true;
                                    _pinController.clear();
                                  });
                                } else {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  if (pin == _firstPin) {
                                    setState(() => _isLoading = true);
                            
                                    bool isSuccess = await widget.onCreatePin(
                                      _firstPin,
                                    );

                                    if (!context.mounted) return;

                                    setState(() => _isLoading = false);
                                    if (isSuccess) {
                                      Navigator.pop(context);
                                      widget.onSuccess();
                                    } else {
                                      setState(() {
                                        _errorMsg =
                                            'Có lỗi xảy ra, vui lòng thử lại!';
                                        _pinController.clear();
                                      });
                                    }
                                  } else {
                                    setState(() {
                                      _errorMsg =
                                          'Mã PIN không khớp. Vui lòng nhập lại!';
                                      _pinController.clear();
                                    });
                                  }
                                }
                              },
                            ),

                            Positioned(
                              right: 5,
                              child: _pinController.text.isEmpty
                                  ? const SizedBox.shrink()
                                  : IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _isShowPin = !_isShowPin;
                                        });
                                      },
                                      icon: Icon(
                                        _isShowPin
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 20,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      child: Text(
                        _errorMsg,
                        style: GoogleFonts.roboto(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _resetState();
                      },

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 18,
                            color: Colors.pink.shade600,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Đặt lại",
                            style: GoogleFonts.roboto(
                              fontSize: 15,
                              color: Colors.pink.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
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
              ),
          ],
        ),
      ),
    );
  }

  void _resetState() {
    setState(() {
      _isConfirmStep = false;
      _errorMsg = '';
      _firstPin = '';
      _pinController.clear();
    });
  }
}
