import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/src/services/payment_service.dart';
import 'package:app/src/transfer/amount_input_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});
  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  final PaymentService _paymentService = PaymentService();
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    cameraResolution: const Size(1280, 720),
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanBoxSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              border: Border.all(
                width: 1,
                color: Colors.black.withValues(alpha: 0.8),
              ),
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.8),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
            ),
          ),
        ),
        title: Text(
          "Quét mã",
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture capture) async {
              final List<Barcode> barCodes = capture.barcodes;
              if (barCodes.isNotEmpty) {
                final String? qrData = barCodes.first.rawValue;
                if (qrData != null) {
                  _controller.stop();
                  if (qrData.startsWith('Mio')) {
                    final result = await _paymentService.getUserInfoByStaticQR(
                      qrData,
                    );
                    if (!context.mounted) return;
                    if (result['is_success']) {
                      if (result['user_info']['role'] == 'USER') {
                        final receiverPhone = result['user_info']['phone'];
                        final receiverId = result['user_info']['user_id'];
                        final receiverFullName =
                            result['user_info']['full_name'];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AmountInputScreen(
                              receiverId: receiverId,
                              receiverFullName: receiverFullName,
                              receiverPhone: receiverPhone,
                            ),
                          ),
                        ).then((value) {
                          _controller.start();
                        });
                      }
                    } else {
                      DialogUtils.showNotification(
                        context,
                        title: "Thông báo",
                        message: result['message'] ?? "Mã QR không hợp lệ",
                        onClose: () => _controller.start(),
                      );
                    }
                  }
                  /*------------------------------------*/
                  else {
                    final result = await _paymentService.getUserInfoByDynamicQR(
                      qrData,
                    );
                    if (!context.mounted) return;
                    if (result['is_success']) {
                      if (result['user_info']['role'] == 'USER') {
                        final receiverPhone =
                            result['user_info']['destination_phone'];
                        final receiverId =
                            result['user_info']['destination_user_id'];
                        final receiverFullName =
                            result['user_info']['destination_name'];
                        final amount = result['user_info']['amount'];
                        final description = result['user_info']['description'];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AmountInputScreen(
                              receiverId: receiverId,
                              receiverFullName: receiverFullName,
                              receiverPhone: receiverPhone,
                              amount: amount,
                              description: description,
                              referenceCode: qrData,
                            ),
                          ),
                        ).then((value) {
                          _controller.start();
                        });
                      }
                    } else {
                      DialogUtils.showNotification(
                        context,
                        title: "Thông báo",
                        message: result['message'] ?? "Mã QR không hợp lệ",
                        onClose: () => _controller.start(),
                      );
                    }
                  }
                }
              }
            },
          ),

          Center(
            child: SizedBox(
              width: scanBoxSize,
              height: scanBoxSize,
              child: CustomPaint(
                painter: _CornerPainter(
                  cornerLength: scanBoxSize * 0.1,
                  cornerWidth: 6,
                  color: Colors.pinkAccent,
                  radius: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double cornerLength;
  final double cornerWidth;
  final Color color;
  final double radius;

  _CornerPainter({
    required this.cornerLength,
    required this.cornerWidth,
    required this.color,
    this.radius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = cornerWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = radius;
    final l = cornerLength;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, l)
        ..lineTo(0, r)
        ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
        ..lineTo(l, 0),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(w - l, 0)
        ..lineTo(w - r, 0)
        ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
        ..lineTo(w, l),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(w, h - l)
        ..lineTo(w, h - r)
        ..arcToPoint(Offset(w - r, h), radius: Radius.circular(r))
        ..lineTo(w - l, h),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(l, h)
        ..lineTo(r, h)
        ..arcToPoint(Offset(0, h - r), radius: Radius.circular(r))
        ..lineTo(0, h - l),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) {
    return oldDelegate.cornerLength != cornerLength ||
        oldDelegate.cornerWidth != cornerWidth ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius;
  }
}
