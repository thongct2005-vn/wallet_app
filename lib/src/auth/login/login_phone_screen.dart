
import 'package:app/src/auth/register/otp_screen.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_password_screen.dart';

class LoginPhoneScreen extends StatefulWidget {
  final String? initialPhoneNumber;
  const LoginPhoneScreen({super.key, this.initialPhoneNumber});

  @override
  State<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends State<LoginPhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AuthService _authService = AuthService();
  bool _hasError = false;
  bool _isPhoneExists = false;
  String _msg = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.initialPhoneNumber ?? "";
    _phoneController.addListener(() {
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
    _phoneController.dispose();
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
            title: Text("Nhập SĐT", style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w600)),
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
                                    text: "Số điện thoại",
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
                                  SizedBox(width: 10),
                                  SizedBox(
                                    width: 30,
                                    height: 20,
                                    child: CountryFlag.fromCountryCode('VN'),
                                  ),
                                  SizedBox(width: 10),
                                  SizedBox(
                                    width: 50,
                                    height: 30,
                                    child: Text(
                                      "+84",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    height: 35,
                                    width: 10,
                                    child: Text(
                                      "|",
                                      style: TextStyle(
                                        fontSize: 25,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        hintText: "Số điện thoại",
                                        border: InputBorder.none,
                                        counterText: "",
                                      ),
                                      style: TextStyle(fontSize: 20),
                                      cursorColor: Colors.pink,
                                      focusNode: _focusNode,
                                      maxLength: 10,
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
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.red,
                                    size: 15,
                                  ),
                                  SizedBox(width: 3),
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
                      padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (_phoneController.text.isEmpty) {
                                    setState(() {
                                      _hasError = true;
                                      _msg = "Vui lòng nhập số điện thoại";
                                    });
                                  } else if (!_isValidPhoneNumber(
                                    _phoneController.text,
                                  )) {
                                    setState(() {
                                      _hasError = true;
                                      _msg = "Số điện thoại không hợp lệ";
                                    });
                                  } else {
                                    setState(() {
                                      _hasError = false;
                                      _isLoading = true;
                                    });
                                    final result = await _authService
                                        .checkPhoneExist(_phoneController.text);

                                    if (!context.mounted) return;

                                    setState(() {
                                      _isLoading = false;
                                      _isPhoneExists =
                                          result['data']['is_phone_exists'];
                                    });

                                    setState(() {
                                      _isLoading = false;
                                    });

                                    if (!_isPhoneExists) {
                                      _showConfirmPhone(
                                        context,
                                        _phoneController.text,
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              LoginPasswordScreen(
                                                phoneNumber:
                                                    _phoneController.text,
                                              ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            disabledBackgroundColor: Colors.black.withValues(alpha: 0.1),
                            backgroundColor: Colors.pink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusGeometry.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
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

  void _showConfirmPhone(BuildContext context, String phone) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Thông báo"),
          content: Text(
            "Bạn có muốn dùng số điện thoại $phone để đăng ký tài khoản.",
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide.none,
              ),
              child: Text(
                "Đổi số điện thoại",
                style: GoogleFonts.roboto(color: Colors.pink),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _authService.sendOtp(phone);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OtpScreen(phoneNumber: phone),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
              child: Text(
                "Xác nhận",
                style: GoogleFonts.roboto(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isValidPhoneNumber(String phone) {
    if (phone.isEmpty) {
      return false;
    }
    final RegExp phoneRegex = RegExp(r'^(0|)[3|5|7|8|9][0-9]{8}$');
    return phoneRegex.hasMatch(phone);
  }
}
