import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
final _storage = FlutterSecureStorage();

class LoginPasswordScreen extends StatefulWidget {
  final String? phoneNumber;
  const LoginPasswordScreen({super.key, this.phoneNumber});

  @override
  State<LoginPasswordScreen> createState() => _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends State<LoginPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasError = false;
  bool _isPasswordEmpty = true;
  bool _isHidePassword = true;
  bool _isloginSuccess = false;
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
        _isPasswordEmpty = _passwordController.text.isEmpty;
      });
    });
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
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
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text("Nhập mật khẩu", style: TextStyle(fontSize: 20)),
            backgroundColor: Colors.white,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Container(
                          height: 55,
                          width: 500,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _hasError
                                  ? const Color.fromARGB(255, 253, 51, 36)
                                  : _focusNode.hasFocus
                                  ? Colors.pink
                                  : Colors.grey,
                              width: _hasError
                                  ? 2
                                  : _focusNode.hasFocus
                                  ? 2
                                  : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  focusNode: _focusNode,
                                  controller: _passwordController,
                                  maxLength: 6,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(fontSize: 20),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    counterText: "",
                                    contentPadding: EdgeInsets.only(left: 10),
                                  ),
                                  obscureText: _isHidePassword,
                                  cursorColor: Colors.pink,
                                ),
                              ),
                              if (!_isPasswordEmpty) ...[
                                Padding(
                                  padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isHidePassword = !_isHidePassword;
                                      });
                                    },
                                    child: Icon(
                                      _isHidePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (_hasError) ...[
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                                style: GoogleFonts.roboto(color: Colors.red),
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
                                  _isPasswordEmpty = true;
                                  _hasError = true;
                                  _msg = "Vui lòng nhập mật khẩu";
                                });
                              } else if (!isValidPassword(
                                _passwordController.text,
                              )) {
                                setState(() {
                                  _hasError = true;
                                  _isPasswordEmpty = false;
                                  _msg = "Mật khẩu phải có đúng 6 số";
                                });
                              } else {
                                setState(() {
                                  _hasError = false;
                                  _isLoading = true;
                                });

                                final result = await _loginWithPhoneAndPassword(
                                  widget.phoneNumber ?? "",
                                  _passwordController.text,
                                );

                                if (!context.mounted) return;

                                setState(() {
                                  _isloginSuccess = result['is_success'];
                                  _msg = result['message'];
                                  _isLoading = false;
                                  _hasError = !_isloginSuccess;
                                });
                              }

                              setState(() {
                                _isLoading = false;
                              });
                              if (_isloginSuccess) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomeScreen(token: ""),
                                  ),
                                );
                              }
                            },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        disabledBackgroundColor: const Color.fromARGB(
                          255,
                          177,
                          174,
                          174,
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
                                strokeWidth: 3,
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
        ),
      ),
    );
  }
}

bool isValidPassword(String psssword) {
  if (psssword.isEmpty) {
    return false;
  }
  final RegExp phoneRegex = RegExp(r'^\d{6}$');
  return phoneRegex.hasMatch(psssword);
}

Future<Map<String, dynamic>> _loginWithPhoneAndPassword(
  String phone,
  String password,
) async {
  try {
    
    final api = ApiClient().dio;
    final result = await api.post(
      ApiConfig.login,
      data: {'phone': phone, 'password': password},
    );
    
    final data = result.data;
    final accessToken = data['data']['token']['access_token'];
    final refreshToken =data['data']['token']['refresh_token'];

    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);

    return {'is_success': true, 'message': data['message']};
  } on DioException catch (e) {
    if (e.response != null && e.response?.data['message'] != null) {
       return {'is_success': false, 'message': e.response?.data['message']?? 'Máy chủ đang bảo trì'};
    }
     return {'is_success': false, 'message':'Lỗi kết nối'};
    
  } catch (e) {
    return {'is_success': false, 'message': 'Hệ thống đang bảo trì'};
  }
}
