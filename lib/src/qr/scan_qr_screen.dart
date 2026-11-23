import 'dart:async';
import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:app/src/services/bank_service.dart';
import 'package:app/src/services/payment_service.dart';
import 'package:app/src/services/wallet_service.dart';
import 'package:app/src/transfer/amount_input_screen.dart';
import 'package:app/src/transfer/confirm_tranfer_screen.dart';
import 'package:app/src/transfer/transfer_funding_helper.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});
  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen>
    with WidgetsBindingObserver {
  final PaymentService _paymentService = PaymentService();
  final WalletService _walletService = WalletService();
  final BankService _bankService = BankService();

  // normal + detectionTimeoutMs: mỗi lần đọc cách nhau 1 giây
  // (detectionTimeoutMs chỉ có tác dụng khi detectionSpeed = normal)
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    cameraResolution: const Size(1280, 720),
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 1000,
  );

  static final RegExp _staticQrPattern = RegExp(
    r'^(?:LumaPay|Mio):[A-Za-z0-9]{8,64}$',
  );
  static final RegExp _dynamicQrPattern = RegExp(r'^[A-Za-z0-9]{8,64}$');

  // Chặn xử lý trùng trong lúc đang gọi API / đang mở màn hình khác
  bool _isProcessing = false;
  bool _isDialogOpen = false;
  bool _isDisposed = false;
  Future<void>? _pauseFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        unawaited(_pauseCamera());
        break;
      case AppLifecycleState.resumed:
        if (!_isProcessing && !_isDialogOpen) {
          unawaited(_resumeScan());
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pauseCamera() {
    if (_isDisposed) return Future.value();
    final existing = _pauseFuture;
    if (existing != null) return existing;

    final future = () async {
      try {
        await _controller.pause();
      } catch (_) {
        // Bỏ qua lỗi khi camera đang dừng hoặc chưa khởi tạo xong
      } finally {
        _pauseFuture = null;
      }
    }();
    _pauseFuture = future;
    return future;
  }

  // Cho phép quét lại. Dùng thay cho mọi chỗ gọi _controller.start().
  Future<void> _resumeScan() async {
    _isDialogOpen = false;
    final pendingPause = _pauseFuture;
    if (pendingPause != null) {
      try {
        await pendingPause;
      } catch (_) {}
    }
    if (!mounted || _isDisposed) {
      _isProcessing = false;
      return;
    }
    try {
      await _controller.start();
    } catch (_) {
      // Camera có thể chưa sẵn sàng hoặc đang bị đóng
    } finally {
      _isProcessing = false;
    }
  }

  void _showError(String message) {
    if (!mounted || _isDisposed) {
      _isProcessing = false;
      return;
    }
    if (_isDialogOpen) return;
    _isDialogOpen = true;
    DialogUtils.showNotification(
      context,
      title: "Thông báo",
      message: message,
      onClose: _resumeScan,
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _isDisposed || !mounted) return;
    if (capture.barcodes.isEmpty) return;
    final String? qrData = capture.barcodes.first.rawValue?.trim();
    if (qrData == null || qrData.isEmpty) return;

    _isProcessing = true;
    await _pauseCamera();
    if (!mounted || _isDisposed) return;

    try {
      if (_staticQrPattern.hasMatch(qrData)) {
        await _handleStaticQr(qrData);
      } else if (_dynamicQrPattern.hasMatch(qrData)) {
        await _handleDynamicQr(qrData);
      } else {
        _showError("Mã QR không hợp lệ hoặc không thuộc hệ thống LumaPay");
      }
    } catch (_) {
      if (!mounted || _isDisposed) return;
      _showError("Không đọc được mã QR. Vui lòng thử lại");
    }
  }

  Future<void> _handleStaticQr(String qrData) async {
    final result = await _paymentService.getUserInfoByStaticQR(qrData);
    if (!mounted) return;

    if (result['is_success'] != true) {
      _showError(result['message'] ?? "Mã QR không hợp lệ");
      return;
    }

    final rawInfo = result['user_info'];
    if (rawInfo is! Map || rawInfo['role'] != 'USER') {
      _showError("Mã QR không hợp lệ");
      return;
    }
    final info = rawInfo;

    final receiverId = info['user_id']?.toString();
    final receiverFullName = info['full_name']?.toString();
    final receiverPhone = info['phone']?.toString();
    if (receiverId == null ||
        receiverFullName == null ||
        receiverPhone == null) {
      _showError("Mã QR không hợp lệ");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AmountInputScreen(
          receiverId: receiverId,
          receiverFullName: receiverFullName,
          receiverPhone: receiverPhone,
        ),
      ),
    ).then((_) => _resumeScan());
  }

  Future<void> _handleDynamicQr(String qrData) async {
    final result = await _paymentService.getUserInfoByDynamicQR(qrData);
    if (!mounted || _isDisposed) return;

    if (result['is_success'] != true) {
      _showError(result['message']?.toString() ?? "Mã QR không hợp lệ");
      return;
    }

    final rawInfo = result['user_info'];
    if (rawInfo is! Map) {
      _showError("Mã QR không hợp lệ");
      return;
    }
    final info = rawInfo;
    final role = info['role'];
    if (role != 'USER' && role != 'MERCHANT') {
      _showError("Mã QR không hợp lệ");
      return;
    }

    final receiverPhone = info['destination_phone']?.toString();
    final receiverId = info['destination_user_id']?.toString();
    final receiverFullName = info['destination_name']?.toString();
    if (receiverPhone == null ||
        receiverId == null ||
        receiverFullName == null) {
      _showError("Mã QR không hợp lệ");
      return;
    }
    final String? amount = info['amount']?.toString();
    final String? description = info['description']?.toString();
    final bool isMerchant = role == 'MERCHANT';
    final String? orderId = info['order_id']?.toString();

    // QR đã có sẵn số tiền và nội dung: bỏ qua màn nhập tiền
    final bool hasFixedInfo =
        (amount ?? '').isNotEmpty && (description ?? '').isNotEmpty;

    if (!hasFixedInfo) {
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
            isMerchant: isMerchant,
            orderId: orderId,
          ),
        ),
      ).then((_) => _resumeScan());
      return;
    }

    final needed = FormatUtils.formatAmountToNum(amount!);
    final resolution = await evaluateTransferFundingBeforeConfirm(
      walletService: _walletService,
      bankService: _bankService,
      rawAmount: amount,
      neededAmount: needed,
      isQrPayment: true,
      isMerchant: isMerchant,
    );
    if (!mounted || _isDisposed) return;

    if (!resolution.canProceed) {
      _showError(resolution.errorMessage ?? "Số dư trong ví không đủ");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmTranferScreen(
          receiverId: receiverId,
          receiverName: receiverFullName,
          receiverPhone: receiverPhone,
          amount: FormatUtils.formatDisplayNumber(needed),
          description: description,
          walletBalance: resolution.walletBalance,
          referenceCode: qrData,
          isMerchant: isMerchant,
          orderId: orderId,
          initialFundingSource: resolution.initialFundingSource,
          initialLinkedBankAccountId: resolution.initialLinkedBankAccountId,
          initialLinkedBanks: resolution.linkedBanks,
        ),
      ),
    ).then((_) => _resumeScan());
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
        elevation: 0,
        centerTitle: true,
        leading: TransferCircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Quét mã",
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            onDetectError: (error, stackTrace) {},
            errorBuilder: (context, error) {
              return Container(
                color: Colors.black,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam_off_outlined,
                      color: Colors.white70,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Không thể khởi động camera. Vui lòng kiểm tra quyền truy cập và thử lại.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _resumeScan,
                      child: const Text("Thử lại"),
                    ),
                  ],
                ),
              );
            },
          ),

          // Lớp phủ tối, khoét lỗ vuông ở giữa
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScanOverlayPainter(
                  boxSize: scanBoxSize,
                  radius: 24,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),

          Center(
            child: SizedBox(
              width: scanBoxSize,
              height: scanBoxSize,
              child: CustomPaint(
                painter: _CornerPainter(
                  cornerLength: scanBoxSize * 0.12,
                  cornerWidth: 5,
                  color: kTfPink,
                  radius: 24,
                ),
              ),
            ),
          ),

          Positioned(
            top: size.height / 2 + scanBoxSize / 2 + 24,
            left: 24,
            right: 24,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Đưa mã QR vào khung để quét",
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Lớp phủ tối với ô vuông bo góc được khoét ở giữa màn hình
class _ScanOverlayPainter extends CustomPainter {
  final double boxSize;
  final double radius;
  final Color color;

  _ScanOverlayPainter({
    required this.boxSize,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: size.center(Offset.zero),
            width: boxSize,
            height: boxSize,
          ),
          Radius.circular(radius),
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, hole),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) {
    return oldDelegate.boxSize != boxSize ||
        oldDelegate.radius != radius ||
        oldDelegate.color != color;
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