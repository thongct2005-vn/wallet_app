import 'package:app/src/qr/create_qr_screen.dart';
import 'package:app/src/qr/scan_qr_screen.dart';
import 'package:flutter/material.dart';

class QrMainScreen extends StatefulWidget {
  const QrMainScreen({super.key});
  @override
  State<QrMainScreen> createState() => _QrMainScreenState();
}

class _QrMainScreenState extends State<QrMainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [const ScanQRScreen(), const CreateQRScreen()];

  @override
  void initState() {
    super.initState();
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.black.withValues(alpha: 0.5),
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
    );
  }
}