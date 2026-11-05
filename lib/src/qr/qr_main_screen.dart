import 'package:app/src/qr/create_qr_screen.dart';
import 'package:app/src/qr/scan_qr_screen.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QrMainScreen extends StatefulWidget {
  const QrMainScreen({super.key});
  @override
  State<QrMainScreen> createState() => _QrMainScreenState();
}

class _QrMainScreenState extends State<QrMainScreen> {
  static final TextStyle _selectedLabelStyle = GoogleFonts.roboto(
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle _unselectedLabelStyle = GoogleFonts.roboto(
    fontSize: 13,
  );

  int _selectedIndex = 0;
  final List<Widget> _screens = const [ScanQRScreen(), CreateQRScreen()];

  @override
  Widget build(BuildContext context) {
    return FreezeKeyboardMediaQuery(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: _screens[_selectedIndex],
        bottomNavigationBar: RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                backgroundColor: Colors.white,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: kTfPink,
                unselectedItemColor: kTfMuted,
                selectedLabelStyle: _selectedLabelStyle,
                unselectedLabelStyle: _unselectedLabelStyle,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.qr_code_scanner),
                    label: "Quét mã QR",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.qr_code),
                    label: "QR nhận tiền",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
