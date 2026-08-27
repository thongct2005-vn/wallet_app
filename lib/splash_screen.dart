import 'package:app/core/controller/user_controller.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/kyc/kyc_front_id_screen.dart';
import 'package:app/src/services/app_data_service.dart';
import 'package:app/src/services/kyc.service.dart';
import 'package:app/src/services/notification_service.dart';
import 'package:app/src/services/socket_service.dart';
import 'package:app/src/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = const FlutterSecureStorage();
  final UserService _userService = UserService();
  final AppDataService _appDataService = AppDataService();
  final KYCService _kycService = KYCService();
  final UserController _userController = Get.put(
    UserController(),
    permanent: true,
  );
  @override
  void initState() {
    super.initState();
    _initializeApp();
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
              Text(
                "Mio",
                style: GoogleFonts.baloo2(
                  fontSize: 70,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              Text(
                "Mobile Money",
                style: GoogleFonts.baloo2(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    String? accessToken = await _storage.read(key: 'access_token');
    String? refreshToken = await _storage.read(key: 'refresh_token');

    if (accessToken == null || refreshToken == null) {
      _navigateToLogin();
      return;
    }

    try {
      final result = await _userService.getMe();
      final homeData = await _appDataService.fetchHomeData();
      _userController.setUserData(
        newId: result['user_id'],
        newPhone: result['phone'],
        newFullName: result['full_name'],
        newBalance: homeData['balance'],
        newHasPin: homeData['has_pin'],
      );
      final userKYC = await _kycService.checkUserKYC();
      await SocketService().connect();
      final fcmToken = await NotificationService().init();

      if (fcmToken != null) {
        await _userService.updateFcmToken(fcmToken);
      }
      if (!mounted) return;
      if (!userKYC['data']['is_kyc']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => KycFrontIdScreen()),
        );
      }
      else {
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
      }
    } catch (e) {
      await _storage.deleteAll();
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPhoneScreen()),
    );
  }
}
