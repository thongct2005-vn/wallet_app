import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreatePasswordScreen extends StatefulWidget {
  final String? phoneNumber;
  const CreatePasswordScreen({super.key, this.phoneNumber});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  final AuthService _authService = AuthService();
  final FocusNode _focusPassword = FocusNode();
  final FocusNode _focusConfirm = FocusNode();
  bool _hasError = false;
  bool _isHidePassword = true;
  bool _isHidePasswordConfirm = true;
  bool _isSuccess = false;
  bool _isLoading = false;
  String _msg = "";

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_clearError);
    _passwordConfirmController.addListener(_clearError);
    _focusPassword.addListener(() => setState(() {}));
    _focusConfirm.addListener(() => setState(() {}));
  }

  void _clearError() {
    if (_hasError) {
      setState(() {
        _hasError = false;
        _msg = "";
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _focusPassword.dispose();
    _focusConfirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.white.withValues(alpha: 0.95),
          appBar: AppBar(
            title: Text(
              "Tạo mật khẩu",
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back, size: 20),
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              Container(
                width: double.infinity,
                height: 500,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Tạo mật khẩu",
                                    style: GoogleFonts.dancingScript(
                                      color: Colors.pink,
                                      fontSize: 35,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: " của bạn",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 25,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Column(
                              children: [
                                _buildPasswordField(
                                  hint: "Mật khẩu 6 số",
                                  controller: _passwordController,
                                  focusNode: _focusPassword,
                                  isHidden: _isHidePassword,
                                  onToggleVisibility: () {
                                    setState(() {
                                      _isHidePassword = !_isHidePassword;
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildPasswordField(
                                  hint: "Xác nhận lại mật khẩu",
                                  controller: _passwordConfirmController,
                                  focusNode: _focusConfirm,
                                  isHidden: _isHidePasswordConfirm,
                                  onToggleVisibility: () {
                                    setState(() {
                                      _isHidePasswordConfirm =
                                          !_isHidePasswordConfirm;
                                    });
                                  },
                                ),
                                if (_hasError) ...[
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: Colors.red,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        _msg,
                                        style: GoogleFonts.roboto(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (_passwordController.text.isEmpty) {
                                    setState(() {
                                      _hasError = true;
                                      _msg = "Vui lòng nhập mật khẩu";
                                    });
                                  } else if (_passwordConfirmController
                                      .text
                                      .isEmpty) {
                                    setState(() {
                                      _hasError = true;
                                      _msg = "Vui lòng nhập xác nhận mật khẩu";
                                    });
                                  } else if (!isValidPassword(
                                    _passwordController.text,
                                  )) {
                                    setState(() {
                                      _hasError = true;
                                      _msg = "Mật khẩu phải có đúng 6 số";
                                    });
                                  } else if (_passwordConfirmController.text !=
                                      _passwordController.text) {
                                    setState(() {
                                      _hasError = true;
                                      _msg =
                                          "Mật khẩu và mật khẩu xác nhận không khớp";
                                    });
                                  } else {
                                    setState(() {
                                      _hasError = false;
                                      _isLoading = true;
                                    });

                                    final result = await _authService.register(
                                      widget.phoneNumber ?? "",
                                      _passwordController.text,
                                    );

                                    if (!context.mounted) return;

                                    setState(() {
                                      _isSuccess = result['is_success'];
                                      _msg = result['message'];
                                      _isLoading = false;
                                      _hasError = !_isSuccess;
                                    });
                                    if (_isSuccess) {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              LoginPhoneScreen(
                                                isRegisterSucess: true,
                                                initialPhoneNumber:
                                                    widget.phoneNumber,
                                              ),
                                        ),
                                        (r) => false,
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            disabledBackgroundColor: Colors.black.withValues(
                              alpha: 0.1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 25,
                                  height: 25,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Xác nhận",
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 25,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isHidden,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      height: 55,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: _hasError
              ? Colors.red
              : focusNode.hasFocus
              ? Colors.pink
              : Colors.grey,
          width: _hasError
              ? 1
              : focusNode.hasFocus
              ? 1
              : 0.5,
        ),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              textAlign: TextAlign.start,
              focusNode: focusNode,
              controller: controller,
              maxLength: 6,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.roboto(color: Colors.grey),
                border: InputBorder.none,
                counterText: "",
                contentPadding: const EdgeInsets.only(left: 10, top: 8),
                suffixIcon: IconButton(
                  onPressed: onToggleVisibility,
                  icon: Icon(
                    isHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              obscureText: isHidden,
              cursorColor: Colors.pink,
            ),
          ),
        ],
      ),
    );
  }
}

bool isValidPassword(String password) {
  if (password.isEmpty) {
    return false;
  }
  final RegExp phoneRegex = RegExp(r'^\d{6}$');
  return phoneRegex.hasMatch(password);
}
