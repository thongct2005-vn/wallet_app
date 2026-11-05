import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/src/auth/forgot/forgot_new_secret_screen.dart';
import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/kyc/kyc_result.dart';
import 'package:app/src/kyc/kyc_ui.dart';
import 'package:app/src/services/forgot_service.dart';
import 'package:app/src/services/kyc.service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:iconsax/iconsax.dart';

class KycFaceScreen extends StatefulWidget {
  final File frontIdImage;
  final File backIdImage;
  final ForgotKycArgs? forgot;
  final bool isUpdate;
  const KycFaceScreen({
    super.key,
    required this.frontIdImage,
    required this.backIdImage,
    this.forgot,
    this.isUpdate = false,
  });

  @override
  State<KycFaceScreen> createState() => _KycFaceScreenState();
}

class _KycFaceScreenState extends State<KycFaceScreen> {
  final UserController _userController = Get.isRegistered<UserController>()
      ? Get.find<UserController>()
      : Get.put(UserController());
  final KYCService _kycService = KYCService();
  final ForgotService _forgotService = ForgotService();
  CameraController? _controller;
  Future<void>? _initFuture;
  File? _capturedImage;

  late final FaceDetector _faceDetector;
  bool _isDetecting = false;
  bool _isStreaming = false;
  bool _isCapturing = false;
  bool _isVerifying = false;

  bool _faceCentered = false;
  String _statusText = 'Đang tìm khuôn mặt...';

  Timer? _countdownTimer;
  int? _countdown;

  static const double _ovalWidthRatio = 0.7;
  static const double _ovalHeightRatio = 0.42;
  static const double _ovalCenterYRatio = 0.42;

  static const double _centerToleranceX = 0.1;
  static const double _centerToleranceY = 0.1;

  CameraLensDirection _lensDirection = CameraLensDirection.front;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableTracking: false,
      ),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _lensDirection = frontCamera.lensDirection;

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _initFuture = _controller!.initialize();
    await _initFuture;
    if (!mounted) return;
    setState(() {});
    _startFaceStream();
  }

  void _startFaceStream() {
    if (_controller == null || _isStreaming) return;
    _isStreaming = true;
    _controller!.startImageStream(_onCameraImage);
  }

  Future<void> _stopFaceStream() async {
    if (_controller != null && _isStreaming) {
      _isStreaming = false;
      try {
        await _controller!.stopImageStream();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _stopFaceStream();
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _onCameraImage(CameraImage image) async {
    if (_isDetecting || _capturedImage != null) return;
    _isDetecting = true;
    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }
      final faces = await _faceDetector.processImage(inputImage);
      double imgWidth = image.width.toDouble();
      double imgHeight = image.height.toDouble();
      if (imgWidth > imgHeight) {
        final temp = imgWidth;
        imgWidth = imgHeight;
        imgHeight = temp;
      }
      _handleFaces(faces, Size(imgWidth, imgHeight));
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.failure(
        context,
        "Không nhận diện được khuôn mặt. Vui lòng thử lại",
      );
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;

    final rotation =
        InputImageRotationValue.fromRawValue(sensorOrientation) ??
        InputImageRotation.rotation0deg;

    final format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        (Platform.isAndroid
            ? InputImageFormat.nv21
            : InputImageFormat.bgra8888);

    final bytes = _concatenatePlanes(image.planes);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  void _handleFaces(List<Face> faces, Size imageSize) {
    if (!mounted) return;

    if (faces.isEmpty) {
      _updateStatus(centered: false, text: 'Không tìm thấy khuôn mặt');
      return;
    }
    if (faces.length > 1) {
      _updateStatus(
        centered: false,
        text: 'Chỉ được có một khuôn mặt trong khung hình',
      );
      return;
    }

    final face = faces.first;
    final box = face.boundingBox;

    double faceCenterX = (box.left + box.right) / 2 / imageSize.width;
    final faceCenterY = (box.top + box.bottom) / 2 / imageSize.height;

    if (_lensDirection == CameraLensDirection.front) {
      faceCenterX = 1 - faceCenterX;
    }

    final dx = (faceCenterX - 0.5).abs();
    final dy = (faceCenterY - _ovalCenterYRatio).abs();

    final faceWidthRatio = box.width / imageSize.width;

    const minRatio = 0.45;
    const maxRatio = 0.75;

    final tooSmall = faceWidthRatio < minRatio;
    final tooBig = faceWidthRatio > maxRatio;

    if (tooSmall) {
      _updateStatus(centered: false, text: 'Vui lòng lại gần camera hơn');
    } else if (tooBig) {
      _updateStatus(centered: false, text: 'Vui lòng lùi camera ra xa hơn');
    } else if (dx > _centerToleranceX || dy > _centerToleranceY) {
      _updateStatus(
        centered: false,
        text: 'Vui lòng đưa khuôn mặt vào giữa khung hình',
      );
    } else {
      _updateStatus(centered: true, text: 'Vui lòng giữ yên');
    }
  }

  void _updateStatus({required bool centered, required String text}) {
    final statusChanged = _statusText != text;

    if (centered && !_faceCentered) {
      _faceCentered = true;
      _statusText = text;
      _startCountdown();
    } else if (!centered && _faceCentered) {
      _faceCentered = false;
      _statusText = text;
      _cancelCountdown();
      if (statusChanged && mounted) setState(() {});
    } else if (statusChanged) {
      setState(() => _statusText = text);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = 3);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_faceCentered) {
        timer.cancel();
        return;
      }
      final next = (_countdown ?? 1) - 1;
      if (next <= 0) {
        timer.cancel();
        setState(() => _countdown = null);
        _capture();
      } else {
        setState(() => _countdown = next);
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (_countdown != null) {
      setState(() => _countdown = null);
    }
  }

  Future<void> _capture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }
    setState(() => _isCapturing = true);
    await _stopFaceStream();
    try {
      final file = await _controller!.takePicture();
      setState(() {
        _capturedImage = File(file.path);
        _isCapturing = false;
      });
    } catch (e) {
      setState(() => _isCapturing = false);
      _startFaceStream();
      if (mounted) {
        SnackbarUtils.failure(context, "Chụp ảnh thất bại. Vui lòng thử lại");
      }
    }
  }

  void _retake() {
    setState(() {
      _capturedImage = null;
      _faceCentered = false;
      _statusText = 'Đang tìm khuôn mặt...';
      _countdown = null;
    });
    _startFaceStream();
  }

  void _confirm() {
    if (_capturedImage == null) return;
    _verifyKYC();
  }

  @override
  Widget build(BuildContext context) {
    final isPreview = _capturedImage != null;

    return Scaffold(
      backgroundColor: kKycDarkBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              KycCameraTopBar(
                currentStep: 3,
                title: isPreview
                    ? 'Kiểm tra khuôn mặt'
                    : 'Xác thực khuôn mặt',
                onBack: () {
                  if (_isVerifying) return;
                  if (isPreview) {
                    _retake();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              Expanded(
                child: isPreview ? _buildPreview() : _buildCameraView(),
              ),
            ],
          ),
          if (_isVerifying) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // Luồng quên mật khẩu / PIN: gửi ảnh kèm kyc token, nhận reset token
  Future<void> _verifyForgotKyc() async {
    final forgot = widget.forgot!;
    try {
      setState(() => _isVerifying = true);
      final result = await _forgotService.verifyKyc(
        kycToken: forgot.kycToken,
        frontIdImage: widget.frontIdImage,
        backIdImage: widget.backIdImage,
        faceImage: _capturedImage!,
      );
      if (!mounted) return;

      if (result['is_success'] == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ForgotNewSecretScreen(
              type: forgot.type,
              resetToken: result['reset_token'],
              phone: forgot.phone,
            ),
          ),
          (r) => r.isFirst,
        );
        return;
      }

      // Token KYC hết hạn: làm lại từ đầu
      if (result['status_code'] == 401) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => LoginPhoneScreen(
              isForceLogout: true,
              msg: result['message'] ?? 'Phiên xác thực đã hết hạn',
            ),
          ),
          (r) => false,
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => KycResultScreen(
            isSuccess: false,
            msg: result['message'] ?? 'Xác minh thất bại',
            forgot: forgot,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.failure(context, '$e');
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  // Luồng cập nhật thông tin KYC từ trang profile
  Future<void> _updateKYC() async {
    try {
      setState(() => _isVerifying = true);
      final result = await _kycService.updateKYC(
        widget.frontIdImage,
        widget.backIdImage,
        _capturedImage!,
      );
      if (!mounted) return;
      final isSuccess = result['is_success'] == true;
      if (isSuccess) {
        final name = result['data']?['full_name'];
        if (name != null) _userController.setUserFullName(newFullName: name);
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => KycResultScreen(
            isSuccess: isSuccess,
            msg: result['message'] ?? 'Cập nhật thông tin thất bại',
            isUpdate: true,
          ),
        ),
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.failure(context, '$e');
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _verifyKYC() async {
    if (widget.forgot != null) return _verifyForgotKyc();
    if (widget.isUpdate) return _updateKYC();
    try {
      setState(() => _isVerifying = true);
      final result = await _kycService.verifyKYC(
        widget.frontIdImage,
        widget.backIdImage,
        _capturedImage!,
      );
      if (!mounted) return;
      if (result['is_success'] == true) {
        _userController.setUserFullName(
          newFullName: result['data']?['full_name'] ?? 'Không rõ tên',
        );
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => KycResultScreen(
            isSuccess: result['is_success'] == true,
            msg: result['message'] ?? '',
          ),
        ),
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.failure(context, '$e');
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: kKycPink.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: kKycPinkSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.scan_barcode,
                  color: kKycPinkDark,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Đang xác thực danh tính',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  color: kKycText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hệ thống đang đối chiếu giấy tờ và khuôn mặt.\nVui lòng giữ kết nối và không thoát ứng dụng.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  color: kKycMuted,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(
                  backgroundColor: kKycPinkSoft,
                  color: kKycPink,
                  minHeight: 7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCamera() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: kKycPinkLight,
            strokeWidth: 2.8,
          ),
          const SizedBox(height: 14),
          Text(
            'Đang khởi tạo camera trước...',
            style: GoogleFonts.roboto(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (_controller == null || _initFuture == null) {
      return _buildLoadingCamera();
    }
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLoadingCamera();
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final ovalTop =
                size.height * _ovalCenterYRatio -
                (size.height * _ovalHeightRatio) / 2;
            final ovalBottom =
                size.height * _ovalCenterYRatio +
                (size.height * _ovalHeightRatio) / 2;

            return Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: kKycDarkBg,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1 / _controller!.value.aspectRatio,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                ),
                _buildOvalOverlay(size),
                Positioned(
                  left: 24,
                  right: 24,
                  top: (ovalTop - 62).clamp(12.0, size.height),
                  child: _buildStatusBanner(),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  top: ovalBottom + 22,
                  child: _buildBottomGuidance(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBanner() {
    final accent = _faceCentered ? kKycSuccessBright : kKycPinkLight;
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: kKycDarkCard.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: accent.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.2),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Row(
            key: ValueKey('$_faceCentered-$_statusText'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _faceCentered ? Iconsax.tick_circle : Iconsax.scan,
                size: 17,
                color: accent,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    color: _faceCentered ? kKycSuccessBright : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGuidance() {
    if (_countdown != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Container(
              key: ValueKey(_countdown),
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kKycSuccessBright, kKycSuccess],
                ),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: kKycSuccessBright.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                '$_countdown',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Giữ nguyên tư thế để chụp tự động...',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Hệ thống sẽ tự động chụp khi khuôn mặt khớp khung hình',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            color: Colors.white.withValues(alpha: 0.76),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: const [
            _FaceHintChip(
              icon: Icons.visibility_outlined,
              label: 'Nhìn thẳng',
            ),
            _FaceHintChip(
              icon: Icons.wb_sunny_outlined,
              label: 'Đủ sáng',
            ),
            _FaceHintChip(
              icon: Iconsax.user,
              label: 'Không che mặt',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOvalOverlay(Size size) {
    final ovalWidth = size.width * _ovalWidthRatio;
    final ovalHeight = size.height * _ovalHeightRatio;
    final centerY = size.height * _ovalCenterYRatio;
    final borderColor = _faceCentered ? kKycSuccessBright : kKycPinkLight;

    return CustomPaint(
      size: size,
      painter: _OvalOverlayPainter(
        ovalWidth: ovalWidth,
        ovalHeight: ovalHeight,
        centerY: centerY,
        borderColor: borderColor,
        isCentered: _faceCentered,
      ),
    );
  }

  Widget _buildPreview() {
    return KycPhotoPreviewView(
      imageFile: _capturedImage!,
      mirrorHorizontal: true,
      previewLabel: 'Ảnh khuôn mặt',
      qualityHint:
          'Đảm bảo khuôn mặt rõ nét, mắt mở tự nhiên và không bị bóng tối che khuất trước khi gửi.',
      confirmLabel: 'Gửi xác thực',
      onRetake: _retake,
      onConfirm: _confirm,
    );
  }
}

class _FaceHintChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FaceHintChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: kKycPinkLight),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.roboto(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OvalOverlayPainter extends CustomPainter {
  final double ovalWidth;
  final double ovalHeight;
  final double centerY;
  final Color borderColor;
  final bool isCentered;

  _OvalOverlayPainter({
    required this.ovalWidth,
    required this.ovalHeight,
    required this.centerY,
    required this.borderColor,
    required this.isCentered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, centerY);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final ovalPath = Path()..addOval(ovalRect);
    final maskPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      ovalPath,
    );

    canvas.drawPath(
      maskPath,
      Paint()..color = kKycDarkBg.withValues(alpha: 0.78),
    );

    // Vầng sáng dịu quanh khung oval
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = borderColor.withValues(alpha: isCentered ? 0.45 : 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // Viền chính của khung oval
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2,
    );

    // 4 cung định vị bên ngoài tạo cảm giác quét sinh trắc học
    final outerArcRect = ovalRect.inflate(9);
    final arcPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const sweep = math.pi / 5;
    for (final startAngle in [
      -math.pi * 0.85,
      -math.pi * 0.35,
      math.pi * 0.15,
      math.pi * 0.65,
    ]) {
      canvas.drawArc(outerArcRect, startAngle, sweep, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OvalOverlayPainter oldDelegate) {
    return oldDelegate.ovalWidth != ovalWidth ||
        oldDelegate.ovalHeight != ovalHeight ||
        oldDelegate.centerY != centerY ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isCentered != isCentered;
  }
}
