import 'dart:convert';

import 'package:app/core/api/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:http/http.dart' as http;
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
        onTap: (){
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
                                  contentPadding: EdgeInsets.only(left: 10)
                                ),
                                obscureText: _isHidePassword,
                                cursorColor: Colors.pink,
                              ),
                            ),
                            if (!_isPasswordEmpty) ...[
                              Padding(
                                padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                child: GestureDetector(
                                  onTap: (){
                                    setState(() {
                                      _isHidePassword = !_isHidePassword;
                                    });
                                  },
                                  child: Icon(
                                  _isHidePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                    color: Colors.grey
                                ),
                                )
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
                              _isPasswordEmpty
                                  ? "Vui lòng nhập mật khẩu"
                                  : "Mật khẩu không hợp lệ",
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
                    onPressed: () async{
                      if (_passwordController.text.isEmpty) {
                        setState(() {
                          _isPasswordEmpty = true;
                          _hasError = true;
                        });
                      } else if (!isValidPassword(
                        _passwordController.text,
                      )) {
                        setState(() {
                          _hasError = true;
                          _isPasswordEmpty = false;
                        });
                      } else {
                        _hasError = false;
                        bool isSuccess = await _loginWithPhoneAndPassword(
                          widget.phoneNumber ?? "", 
                          _passwordController.text
                        );
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
}

bool isValidPassword(String psssword) {
  if (psssword.isEmpty) {
    return false;
  }
  final RegExp phoneRegex = RegExp(r'^\d{6}$');
  return phoneRegex.hasMatch(psssword);
}

Future<bool> _loginWithPhoneAndPassword(String phone, String password) async {
  try{
  final String url = ApiConfig.login;
  final res = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(
    {
      'phone': phone,
      'password': password
    }
  )
  );

  if(res.statusCode == 200){
    print(res.body);
    return true;
  }
  print(res.body);
  return false;
  }
  catch(e){
    print(e);
    return false;
  }
}

void _showDialog(BuildContext context, String msg){
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context){
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: const Text("Thông báo"),
        content: Text(msg, style: GoogleFonts.roboto(),),
        actions: [
          TextButton(onPressed: (){
            Navigator.pop(context);
          },
          child: Text("Đóng", style: TextStyle(color: Colors.pink))
          )
        ],
      );
    },
  );
}
