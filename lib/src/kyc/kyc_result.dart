import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/kyc/kyc_front_id_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KycResultScreen extends StatelessWidget {
  final bool isSuccess;
  final String msg;
  final ForgotKycArgs? forgot;
  const KycResultScreen({
    super.key,
    required this.isSuccess,
    required this.msg,
    this.forgot,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = isSuccess ? Colors.lightGreen : Colors.redAccent;
    final titleText = isSuccess ? 'Xác minh thành công' : 'Xác minh thất bại';
    final subtitleText = msg;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      titleText,
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitleText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Luồng quên mật khẩu/PIN: thử lại về màn nhập OTP rồi chụp lại từ đầu
                    if (forgot != null) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KycFrontIdScreen(forgot: forgot),
                        ),
                        (r) => r.settings.name == kForgotOtpRoute || r.isFirst,
                      );
                      return;
                    }
                    isSuccess? Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>HomeScreen()))
                    : Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>KycFrontIdScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isSuccess ? 'VỀ TRANG CHỦ' : 'THỬ LẠI',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}