import 'package:app/core/controller/user_controller.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/kyc/kyc_front_id_screen.dart';
import 'package:app/src/services/app_data_service.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:app/src/services/kyc.service.dart';
import 'package:app/src/services/notification_service.dart';
import 'package:app/src/services/socket_service.dart';
import 'package:app/src/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class LoginPasswordScreen extends StatefulWidget {
  final String? phoneNumber;
  const LoginPasswordScreen({super.key, this.phoneNumber});

  @override
  State<LoginPasswordScreen> createState() => _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends State<LoginPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final AppDataService _appDataService = AppDataService();
  final KYCService _kycService = KYCService();
  final UserController _userController = Get.put(
    UserController(),
    permanent: true,
  );
  bool _hasError = false;
  bool _isHidePassword = true;
  bool _isLoading = false;
  String _msg = "";

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
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
    _passwordController.dispose();
    _focusNode.dispose();
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
              "Nhập mật khẩu",
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.transparent,
            leading: Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 0, 10),
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
                  icon: Icon(Icons.arrow_back, size: 20),
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
                                    text: "Mật khẩu",
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
                              width: double.infinity,
                              decoration: BoxDecoration(
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
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      textAlign: TextAlign.start,

                                      focusNode: _focusNode,
                                      controller: _passwordController,
                                      maxLength: 6,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(fontSize: 20),
                                      decoration: InputDecoration(
                                        hintText: "Mật khẩu 6 số",
                                        hintStyle: GoogleFonts.roboto(
                                          color: Colors.grey,
                                        ),

                                        border: InputBorder.none,
                                        counterText: "",
                                        contentPadding: EdgeInsets.only(
                                          left: 10,
                                          top: 8,
                                        ),
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _isHidePassword =
                                                  !_isHidePassword;
                                            });
                                          },
                                          icon: Icon(
                                            _isHidePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                          ),
                                        ),
                                      ),
                                      obscureText: _isHidePassword,
                                      cursorColor: Colors.pink,
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
                                  if (_passwordController.text.isEmpty) {
                                    setState(() {
                                      _hasError = true;
                                      _msg = "Vui lòng nhập mật khẩu";
                                    });
                                  } else if (!isValidPassword(
                                    _passwordController.text,
                                  )) {
                                    setState(() {
                                      _hasError = true;
                                      _msg = "Mật khẩu phải có đúng 6 số";
                                    });
                                  } else {
                                    setState(() {
                                      _hasError = false;
                                      _isLoading = true;
                                    });

                                    final result = await _authService
                                        .loginWithPhoneAndPassword(
                                          widget.phoneNumber ?? "",
                                          _passwordController.text,
                                        );

                                    if (result['is_success']) {
                                      final homeData = await _appDataService
                                          .fetchHomeData();

                                      _userController.setUserData(
                                        newId: result['user_id'],
                                        newPhone: result['phone'],
                                        newFullName:
                                            result['full_name'] ??
                                            "Không rõ tên",
                                        newBalance: homeData['balance'],
                                        newHasPin: homeData['has_pin'],
                                      );
                                      final userKYC = await _kycService
                                          .checkUserKYC();

                                      await SocketService().connect();
                                      final fcmToken =
                                          await NotificationService().init();

                                      if (fcmToken != null) {
                                        await _userService.updateFcmToken(
                                          fcmToken,
                                        );
                                      }
                                      if (!context.mounted) return;

                                      if (!userKYC['data']['is_kyc']) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                KycFrontIdScreen(),
                                          ),
                                        );
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => HomeScreen(),
                                          ),
                                        );
                                      }
                                    } else {
                                      setState(() {
                                        _isLoading = false;
                                        _msg = result['message'];
                                        _hasError = !result['is_success'];
                                      });
                                    }
                                  }
                                },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            disabledBackgroundColor: Colors.black.withValues(
                              alpha: 0.1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusGeometry.circular(10),
                            ),
                          ),

                          child: _isLoading
                              ? SizedBox(
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
}

bool isValidPassword(String password) {
  if (password.isEmpty) {
    return false;
  }
  final RegExp phoneRegex = RegExp(r'^\d{6}$');
  return phoneRegex.hasMatch(password);
}
