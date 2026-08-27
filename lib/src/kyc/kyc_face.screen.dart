import 'dart:async';
import 'dart:io';
import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/src/kyc/kyc_result.dart';
import 'package:app/src/services/kyc.service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:iconsax/iconsax.dart';

class KycFaceScreen extends StatefulWidget {
  final File frontIdImage;
  final File backIdImage;
  const KycFaceScreen({
    super.key,
    required this.frontIdImage,
    required this.backIdImage,
  });

  @override
  State<KycFaceScreen> createState() => _KycFaceScreenState();
}

class _KycFaceScreenState extends State<KycFaceScreen> {
  final UserController _userController = UserController();
  final KYCService _kycService = KYCService();
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

    final minRatio = 0.45;
    final maxRatio = 0.75;

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
    if (_statusText != text) {
      setState(() => _statusText = text);
    }

    if (centered && !_faceCentered) {
      _faceCentered = true;
      _startCountdown();
    } else if (!centered && _faceCentered) {
      _faceCentered = false;
      _cancelCountdown();
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Chụp ảnh khuôn mặt',
          style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _capturedImage != null ? _buildPreview() : _buildCameraView(),

          if (_isVerifying) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Future<void> _verifyKYC() async {
    try {
      setState(() => _isVerifying = true);
      final result = await _kycService.verifyKYC(
        widget.frontIdImage,
        widget.backIdImage,
        _capturedImage!,
      );
      if (!mounted) return;
      if(result['is_success']){
        _userController.setUserFullName(newFullName: result['data']['full_name']?? 'Không rõ tên');
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => KycResultScreen(
            isSuccess: result['is_success'],
            msg: result['message'],
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
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.pinkAccent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Iconsax.scan_barcode,
                color: Colors.pinkAccent,
                size: 40,
              ),
              const SizedBox(height: 16),

              Text(
                'ĐANG XÁC THỰC',
                style: GoogleFonts.roboto(
                  color: Colors.pinkAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.black,
                  color: Colors.pinkAccent,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Hệ thống đang đồng bộ dữ liệu...\nVui lòng không thoát ứng dụng.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (_controller == null || _initFuture == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.pink));
    }
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.pink),
          );
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
                  color: Colors.black,
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
                  top: (ovalTop - 64).clamp(16, size.height),
                  child: _buildStatusBanner(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: ovalBottom + 16,
                  child: _buildCountdown(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBanner() {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Container(
          key: ValueKey(_statusText),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _statusText,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              color: _faceCentered ? Colors.greenAccent : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    if (_countdown == null) return const SizedBox.shrink();
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Container(
          key: ValueKey(_countdown),
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.pinkAccent,
          ),
          child: Text(
            '$_countdown',
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOvalOverlay(Size size) {
    final ovalWidth = size.width * _ovalWidthRatio;
    final ovalHeight = size.height * _ovalHeightRatio;
    final centerY = size.height * _ovalCenterYRatio;
    final borderColor = _faceCentered ? Colors.greenAccent : Colors.pinkAccent;

    return CustomPaint(
      size: size,
      painter: _OvalOverlayPainter(
        ovalWidth: ovalWidth,
        ovalHeight: ovalHeight,
        centerY: centerY,
        borderColor: borderColor,
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Expanded(
          child: Transform.scale(
            scaleX: -1,
            child: Image.file(_capturedImage!, fit: BoxFit.contain),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retake,
                  icon: const Icon(Iconsax.refresh, color: Colors.white),
                  label: Text(
                    'Chụp lại',
                    style: GoogleFonts.roboto(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirm,
                  icon: const Icon(Iconsax.tick_circle),
                  label: Text('Xác nhận', style: GoogleFonts.roboto()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OvalOverlayPainter extends CustomPainter {
  final double ovalWidth;
  final double ovalHeight;
  final double centerY;
  final Color borderColor;

  _OvalOverlayPainter({
    required this.ovalWidth,
    required this.ovalHeight,
    required this.centerY,
    required this.borderColor,
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
      Paint()..color = Colors.black.withValues(alpha: 0.7),
    );

    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _OvalOverlayPainter oldDelegate) {
    return oldDelegate.ovalWidth != ovalWidth ||
        oldDelegate.ovalHeight != ovalHeight ||
        oldDelegate.centerY != centerY ||
        oldDelegate.borderColor != borderColor;
  }
}
