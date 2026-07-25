import 'dart:async';

import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/src/auth/register/create_password.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpScreen extends StatefulWidget {
  final String? phoneNumber;
  const OtpScreen({super.key, this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _numberA = TextEditingController();
  final TextEditingController _numberB = TextEditingController();
  final TextEditingController _numberC = TextEditingController();
  final TextEditingController _numberD = TextEditingController();
  bool _isLoading = false;
  int _countdown = 0;
  String _msg = "";
  Timer? _timer;
  @override
  void dispose() {
    _timer?.cancel();
    _numberA.dispose();
    _numberB.dispose();
    _numberC.dispose();
    _numberD.dispose();
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
          appBar: AppBar(title: Text("Nhập mã xác thực")),
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(height: 20),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        "Mã xác thực sẽ được gửi đến số điện thoại ${widget.phoneNumber}.\nNếu không nhận được mã vui lòng bấm gửi lại mã.",
                        style: GoogleFonts.roboto(fontSize: 15),
                      ),
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildOtpBox(
                            context,
                            _numberA,
                            first: true,
                            last: false,
                          ),
                          const SizedBox(width: 10),
                          _buildOtpBox(
                            context,
                            _numberB,
                            first: false,
                            last: false,
                          ),
                          const SizedBox(width: 10),
                          _buildOtpBox(
                            context,
                            _numberC,
                            first: false,
                            last: false,
                          ),
                          const SizedBox(width: 10),
                          _buildOtpBox(
                            context,
                            _numberD,
                            first: false,
                            last: true,
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _countdown > 0
                            ? null
                            : () {
                                _startCountdown();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: Text(
                          _countdown > 0
                              ? "Gửi lại mã ($_countdown s)"
                              : "Gửi lại mã",
                          style: GoogleFonts.roboto(color: Colors.white),
                        ),
                      ),
                      if (_msg != "") ...[
                        const SizedBox(height: 10),
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
                  padding: EdgeInsetsGeometry.fromLTRB(10, 0, 10, 15),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() {
                                _isLoading = true;
                              });
                              final code = _formattCode(
                                _numberA.text,
                                _numberB.text,
                                _numberC.text,
                                _numberD.text,
                              );
                              final result = await _verifyOtp(
                                widget.phoneNumber ?? "",
                                code,
                              );
                              setState(() {
                                _isLoading = false;
                              });
                              if (result['statusCode'] == 200) {
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreatePasswordScreen(
                                      phoneNumber: widget.phoneNumber,
                                    ),
                                  ),
                                );
                              } else {
                                setState(() {
                                  _msg = "OTP không chính xác";
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(10),
                        ),
                      ),

                      child: Text(
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

  Widget _buildOtpBox(
    BuildContext context,
    TextEditingController controller, {
    required bool first,
    required bool last,
  }) {
    return Container(
      height: 60,
      width: 40,
      decoration: BoxDecoration(
        border: Border.all(width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          autofocus: first,
          maxLength: 1,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          onTap: (){
            setState(() {
              _msg = "";
            });
          },
          onChanged: (value) {
            if (value.isNotEmpty && !last) {
              FocusScope.of(context).nextFocus();
            } else if (value.isEmpty && !first) {
              FocusScope.of(context).previousFocus();
            }
            setState(() {
              _msg = "";
            });
          },

          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: "",
          ),
          style: const TextStyle(fontSize: 20),
          cursorColor: Colors.pink,
        ),
      ),
    );
  }

  void _startCountdown() {
    setState(() {
      _countdown = 30;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formattCode(String a, String b, String c, String d) {
    String code =
        a.replaceAll(' ', '') +
        b.replaceAll(' ', '') +
        c.replaceAll(' ', '') +
        d.replaceAll(' ', '');
    return code;
  }

  Future<Map<String, dynamic>> _verifyOtp(String phone, String code) async {
    try {
      final api = ApiClient().dio;
      final result = await api.post(
        ApiConfig.verifyOtp,
        data: {'phone': phone, 'code': code},
      );
      return result.data;
    } catch (e) {
      return {};
    }
  }
}
