import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

final _storage = FlutterSecureStorage();

class CreatePasswordScreen extends StatefulWidget {
  final String? phoneNumber;
  const CreatePasswordScreen({super.key, this.phoneNumber});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final FocusNode _focusPassword = FocusNode();
  final FocusNode _focusConfirm = FocusNode();
  bool _hasError = false;
  bool _isHidePassword = true;
  bool _isHidePasswordConfirm = true;
  bool _isloginSuccess = false;
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
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Tạo mật khẩu", style: TextStyle(fontSize: 20)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            _buildPasswordField(
                              hint: "Tạo mật khẩu",
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
                                  _isHidePasswordConfirm = !_isHidePasswordConfirm;
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
                                    style: GoogleFonts.roboto(color: Colors.red),
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
                              } else if (_passwordConfirmController.text.isEmpty) {
                                setState(() {
                                  _hasError = true;
                                  _msg = "Vui lòng nhập xác nhận mật khẩu";
                                });
                              } else if (!isValidPassword(_passwordController.text)) {
                                setState(() {
                                  _hasError = true;
                                  _msg = "Mật khẩu phải có đúng 6 số";
                                });
                              } else if (_passwordConfirmController.text != _passwordController.text) {
                                setState(() {
                                  _hasError = true;
                                  _msg = "Mật khẩu và mật khẩu xác nhận không khớp";
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

                                // if (_isloginSuccess) {
                                //   Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (context) => const HomeScreen(phone: ,),
                                //     ),
                                //   );
                                // }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        disabledBackgroundColor: const Color.fromARGB(255, 177, 174, 174),
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

  Widget _buildPasswordField({
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isHidden,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        border: Border.all(
          color: _hasError
              ? Colors.red
              : focusNode.hasFocus
                  ? Colors.pink
                  : Colors.grey,
          width: focusNode.hasFocus || _hasError ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        textAlign: TextAlign.left,
        focusNode: focusNode,
        controller: controller,
        maxLength: 6,
        keyboardType: TextInputType.number,
        obscureText: isHidden,
        style: const TextStyle(fontSize: 25),
        cursorColor: Colors.pink,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.roboto(fontSize: 10),
          border: InputBorder.none,
          counterText: "",
          contentPadding: const EdgeInsets.only(left: 15, top: 15),
          suffixIcon: IconButton(
            icon: Icon(
              isHidden ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: onToggleVisibility,
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
    final refreshToken = data['data']['token']['refresh_token'];

    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);

    return {'is_success': true, 'message': data['message']};
  } on DioException catch (e) {
    if (e.response != null && e.response?.data['message'] != null) {
      return {
        'is_success': false,
        'message': e.response?.data['message'] ?? 'Máy chủ đang bảo trì',
      };
    }
    return {'is_success': false, 'message': 'Lỗi kết nối'};
  } catch (e) {
    return {'is_success': false, 'message': 'Hệ thống đang bảo trì'};
  }
}