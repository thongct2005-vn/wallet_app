import 'dart:io';
import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/kyc/kyc_back_id_screen.dart';
import 'package:app/src/kyc/kyc_ui.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:app/src/services/socket_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class KycFrontIdScreen extends StatefulWidget {
  /// Khác null khi màn KYC được dùng cho luồng quên mật khẩu / quên PIN
  final ForgotKycArgs? forgot;
  // true: người dùng đã KYC, đang cập nhật lại thông tin
  final bool isUpdate;
  const KycFrontIdScreen({super.key, this.forgot, this.isUpdate = false});

  @override
  State<KycFrontIdScreen> createState() => _KycFrontIdScreenState();
}

class _KycFrontIdScreenState extends State<KycFrontIdScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  File? _capturedImage;
  bool _isCapturing = false;
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
            currentStep: 1,
            title: isPreview ? 'Kiểm tra mặt trước' : 'Chụp mặt trước CCCD',
            onBack: () {
              if (isPreview) {
                _retake();
              } else {
                Navigator.pop(context);
              }
            },
            // Luồng quên mật khẩu/PIN: người dùng đã đăng xuất sẵn nên không cần nút này
            trailing: (widget.forgot == null && !widget.isUpdate)
                ? KycCircleButton(
                    isDark: true,
                    tooltip: 'Đăng xuất',
                    icon: Iconsax.logout,
                    onPressed: () => _showConfirmLogout(context),
                  )
                : null,
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
              badgeIcon: Iconsax.card,
              badgeLabel: 'Mặt trước CCCD / CMND',
              instruction: 'Đặt mặt trước giấy tờ nằm gọn trong khung',
              subInstruction:
                  'Hiển thị rõ nét ảnh chân dung, họ tên và số định danh',
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
      previewLabel: 'Mặt trước CCCD',
      qualityHint:
          'Đảm bảo chữ và số rõ nét, không bị chói sáng hay mất góc trước khi chuyển sang mặt sau.',
      confirmLabel: 'Dùng ảnh này',
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KycBackIdScreen(
          frontIdImage: _capturedImage!,
          forgot: widget.forgot,
          isUpdate: widget.isUpdate,
        ),
      ),
    );
  }

  Future<void> _showConfirmLogout(BuildContext context) async {
    final isSuccess = await DialogUtils.showConfirmationAsync(
      context,
      title: "Xác nhận",
      message: "Bạn có chắc chắn muốn đăng xuất",
      cancelText: "Đóng",
      confirmText: "Đồng ý",
      errorMessage: "Có lỗi khi đăng xuất. Vui lòng thử lại",
      onConfirm: () => _logout(),
    );

    if (isSuccess == true && context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPhoneScreen()),
        (routes) => false,
      );
    }
  }

  Future<bool> _logout() async {
    final result = await _authService.logout();
    SocketService().disconnect();
    await _storage.deleteAll();
    return result['is_success'] == true;
  }
}
