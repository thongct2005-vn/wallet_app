import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/src/auth/register/create_password.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterEmailScreen extends StatefulWidget {
  final String? initialEmail;
  final String? phone;
  const RegisterEmailScreen({
    super.key,
    this.initialEmail,
    this.phone,
  });

  @override
  State<RegisterEmailScreen> createState() => _RegisterEmailScreenState();
}

class _RegisterEmailScreenState extends State<RegisterEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AuthService _authService = AuthService();
  bool _hasError = false;
  bool _isEmailExists = false;
  String _msg = '';
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail ?? "";
    _emailController.addListener(() {
      setState(() {
        if (_hasError) {
          _hasError = false;
        }
      });
    });
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          backgroundColor: Colors.white.withValues(alpha: 0.95),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(
              "Nhập Email",
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.transparent,
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
                                    text: "Email",
                                    style: GoogleFonts.dancingScript(
                                      color: Colors.pink,
                                      fontSize: 35,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
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
                            child: Container(
                              height: 55,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: _hasError
                                      ? Colors.red
                                      : _focusNode.hasFocus
                                      ? Colors.pink
                                      : Colors.grey,
                                  width: _hasError
                                      ? 1
                                      : _focusNode.hasFocus
                                      ? 1
                                      : 0.5,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 15),
                                  const Icon(
                                    Icons.email_outlined,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        hintText: "Nhập địa chỉ email",
                                        border: InputBorder.none,
                                        counterText: "",
                                      ),
                                      style: const TextStyle(fontSize: 18),
                                      cursorColor: Colors.pink,
                                      focusNode: _focusNode,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_hasError) ...[
                            const SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: Row(
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
                            ),
                          ],
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
                                  if (_emailController.text.isEmpty) {
                                    setState(() {
                                      _hasError = true;
                                      _msg = "Vui lòng nhập email";
                                    });
                                  } else if (!_isValidEmail(
                                    _emailController.text,
                                  )) {
                                    setState(() {
                                      _hasError = true;
                                      _msg = "Email không hợp lệ";
                                    });
                                  } else {
                                    setState(() {
                                      _hasError = false;
                                      _isLoading = true;
                                    });

                                    final result = await _authService
                                        .checkEmailExist(_emailController.text);

                                    if (!context.mounted) return;

                                    setState(() {
                                      _isLoading = false;
                                      if (result['is_success'] == true) {
                                        _isEmailExists =
                                            result['data']['is_email_exists'];
                                        if (!_isEmailExists) {
                                          DialogUtils.showConfirmation(
                                            context,
                                            title: "Thông báo",
                                            message:
                                                "Bạn có muốn dùng email ${_emailController.text} để đăng ký tài khoản.",
                                            cancelText: "Đổi Email",
                                            confirmText: "Xác nhận",
                                            onConfirm: () {
                                              // Chuyển thẳng sang màn hình Tạo mật khẩu sau khi xác nhận email
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      CreatePasswordScreen(
                                                        phoneNumber: widget.phone,
                                                        email: _emailController.text,
                                                      ),
                                                ),
                                              );
                                            },
                                          );
                                        } else {
                                          SnackbarUtils.failure(
                                            context,
                                            "Email này đã được sử dụng",
                                          );
                                        }
                                      } else {
                                        SnackbarUtils.failure(
                                          context,
                                          result['message'],
                                        );
                                      }
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            disabledBackgroundColor: Colors.black.withValues(
                              alpha: 0.1,
                            ),
                            backgroundColor: Colors.pink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 25,
                                  width: 25,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Tiếp tục",
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

  bool _isValidEmail(String email) {
    if (email.isEmpty) {
      return false;
    }
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}