import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = FlutterSecureStorage();
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.pinkAccent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("TEMO", style:
                 GoogleFonts.baloo2(
                  fontSize: 70,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1
                 )
              ,),
              Text("Moblie Money",
              style: GoogleFonts.baloo2(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 3
                 ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(Duration(milliseconds: 10000));
    String? accessToken = await _storage.read(key: 'access_token');
    String? refreshToken = await _storage.read(key: 'refresh_token');

    if (accessToken == null || refreshToken == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPhoneScreen()),
      );
      return;
    }

    try {
      final api = ApiClient().dio;
      await api.get(ApiConfig.getMe);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      await _storage.deleteAll();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPhoneScreen()),
      );
      return;
    }
  }
}
