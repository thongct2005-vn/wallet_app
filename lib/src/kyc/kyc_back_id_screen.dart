import 'dart:io';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/src/kyc/kyc_face.screen.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class KycBackIdScreen extends StatefulWidget {
  final File frontIdImage;
  const KycBackIdScreen({super.key, required this.frontIdImage});

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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Chụp mặt sau CCCD',
          style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
        ),
      ),
      body: _capturedImage != null ? _buildPreview() : _buildCameraView(),
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

            _buildOverlayFrame(),
           
            Positioned(
              left: 0,
              right: 0,
              bottom: 50,
              child: _buildBottomControls(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverlayFrame() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.7),
            BlendMode.srcOut,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(color: Colors.transparent),
              ),
              Center(
                child: AspectRatio(
                  aspectRatio: 1.586,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: AspectRatio(
            aspectRatio: 1.586,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.pinkAccent, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Center(
      child: GestureDetector(
        onTap: _isCapturing ? null : _capture,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: _isCapturing
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Container(
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.pinkAccent,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Expanded(child: Image.file(_capturedImage!, fit: BoxFit.contain)),
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
        ),
      ),
    );
  }
}
