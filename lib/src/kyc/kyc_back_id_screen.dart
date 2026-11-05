import 'dart:io';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:app/src/kyc/kyc_face.screen.dart';
import 'package:app/src/kyc/kyc_ui.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class KycBackIdScreen extends StatefulWidget {
  final File frontIdImage;
  final ForgotKycArgs? forgot;
  final bool isUpdate;
  const KycBackIdScreen({
    super.key,
    required this.frontIdImage,
    this.forgot,
    this.isUpdate = false,
  });

  @override
  State<KycBackIdScreen> createState() => _KycBackIdScreenState();
}

class _KycBackIdScreenState extends State<KycBackIdScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  File? _capturedImage;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initFuture = _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPreview = _capturedImage != null;

    return Scaffold(
      backgroundColor: kKycDarkBg,
      body: Column(
        children: [
          KycCameraTopBar(
            currentStep: 2,
            title: isPreview ? 'Kiểm tra mặt sau' : 'Chụp mặt sau CCCD',
            onBack: () {
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
            'Đang khởi tạo máy ảnh...',
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
            const KycIdScannerOverlay(
              badgeIcon: Iconsax.card_send,
              badgeLabel: 'Mặt sau CCCD / CMND',
              instruction: 'Đặt mặt sau giấy tờ nằm gọn trong khung',
              subInstruction:
                  'Đảm bảo rõ nét vùng chip điện tử, mã MRZ và ngày cấp',
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      kKycDarkBg.withValues(alpha: 0.9),
                      kKycDarkBg.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: KycShutterButton(
                    isCapturing: _isCapturing,
                    onTap: _capture,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreview() {
    return KycPhotoPreviewView(
      imageFile: _capturedImage!,
      previewLabel: 'Mặt sau CCCD',
      qualityHint:
          'Kiểm tra vùng chip điện tử, dòng mã nhận dạng và ngày cấp hiển thị sắc nét, không bị mờ.',
      confirmLabel: 'Tiếp tục',
      onRetake: _retake,
      onConfirm: _confirm,
    );
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() => _isCapturing = true);
    try {
      final file = await _controller!.takePicture();
      setState(() {
        _capturedImage = File(file.path);
        _isCapturing = false;
      });
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) {
        SnackbarUtils.failure(context, "Chụp ảnh thất bại. Vui lòng thử lại");
      }
    }
  }

  void _retake() {
    setState(() => _capturedImage = null);
  }

  void _confirm() {
    if (_capturedImage == null) return;

    final frontIdImage = widget.frontIdImage;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KycFaceScreen(
          frontIdImage: frontIdImage,
          backIdImage: _capturedImage!,
          forgot: widget.forgot,
          isUpdate: widget.isUpdate,
        ),
      ),
    );
  }
}
