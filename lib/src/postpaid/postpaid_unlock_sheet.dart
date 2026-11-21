import 'dart:io';
import 'dart:math' as math;

import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/core/widgets/pin_bottomsheet/pin_sheet_common.dart';
import 'package:app/src/postpaid/postpaid_entry_widgets.dart';
import 'package:app/src/services/postpaid_service.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:permission_handler/permission_handler.dart';

class PostpaidUnlockRequestSheet extends StatefulWidget {
  final PostpaidService service;
  final Map<String, dynamic>? previousRejectedRequest;

  const PostpaidUnlockRequestSheet({
    super.key,
    required this.service,
    this.previousRejectedRequest,
  });

  @override
  State<PostpaidUnlockRequestSheet> createState() =>
      _PostpaidUnlockRequestSheetState();
}

class _PostpaidUnlockRequestSheetState
    extends State<PostpaidUnlockRequestSheet> {
  static const MethodChannel _galleryChannel = MethodChannel(
    'com.example.app/gallery',
  );
  static const int _maxImages = 3;

  final TextEditingController _noteCtrl = TextEditingController();
  final List<File> _selectedImages = [];
  bool _isPicking = false;
  bool _isSubmitting = false;
  String? _inlineError;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    if (_isPicking || _isSubmitting) return;
    final remaining = _maxImages - _selectedImages.length;
    if (remaining <= 0) {
      setState(() => _inlineError = 'Chỉ được chọn tối đa $_maxImages ảnh');
      return;
    }

    setState(() {
      _isPicking = true;
      _inlineError = null;
    });

    try {
      final paths = await _galleryChannel.invokeListMethod<String>(
        'pickProofImages',
        {'maxCount': remaining},
      );
      if (!mounted) return;
      if (paths != null && paths.isNotEmpty) {
        final existingPaths = _selectedImages.map((e) => e.path).toSet();
        final nextFiles = <File>[];
        for (final path in paths) {
          if (existingPaths.contains(path)) continue;
          final file = File(path);
          if (file.existsSync()) {
            nextFiles.add(file);
          }
          if (_selectedImages.length + nextFiles.length >= _maxImages) break;
        }
        if (nextFiles.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(nextFiles);
          });
        }
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _inlineError = e.message ?? 'Không thể mở thư viện ảnh';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _inlineError = 'Không thể đọc ảnh đã chọn, vui lòng thử lại';
      });
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _captureWithCamera() async {
    if (_isPicking || _isSubmitting) return;
    if (_selectedImages.length >= _maxImages) {
      setState(() => _inlineError = 'Chỉ được chọn tối đa $_maxImages ảnh');
      return;
    }

    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() {
        _inlineError = 'Cần quyền camera để chụp ảnh chứng minh thu nhập';
      });
      return;
    }

    setState(() {
      _isPicking = true;
      _inlineError = null;
    });

    try {
      final captured = await Navigator.push<File>(
        context,
        MaterialPageRoute(builder: (_) => const _ProofCameraCaptureScreen()),
      );
      if (!mounted) return;
      if (captured != null && captured.existsSync()) {
        setState(() {
          if (_selectedImages.length < _maxImages) {
            _selectedImages.add(captured);
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || _isPicking) return;
    if (_selectedImages.isEmpty) {
      setState(() {
        _inlineError = 'Vui lòng chọn hoặc chụp từ 1 đến 3 ảnh chứng minh thu nhập';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    final res = await widget.service.submitUnlockRequest(
      proofImages: _selectedImages,
      userNote: _noteCtrl.text.trim(),
    );
    if (!mounted) return;

    if (res['is_success'] == true) {
      Navigator.pop(context, res);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _inlineError =
          res['message']?.toString() ??
          'Không thể gửi yêu cầu mở khóa, vui lòng thử lại';
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = math.max(
      320.0,
      media.size.height - media.viewPadding.top - 24,
    );
    final rejectedNote = widget.previousRejectedRequest?['admin_note']
        ?.toString()
        .trim();

    return SmoothKeyboardSheet(
      child: PopScope(
        canPop: !_isSubmitting,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gửi yêu cầu mở khóa Ví trả sau',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kTfText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tải lên 1–3 ảnh chứng minh thu nhập (bảng lương, sao kê ngân hàng, hợp đồng lao động...) để Quản trị viên xét duyệt mở lại ví.',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        height: 1.4,
                        color: kTfMuted,
                      ),
                    ),
                    if (rejectedNote != null && rejectedNote.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          'Lý do từ chối lần trước: $rejectedNote',
                          style: GoogleFonts.roboto(
                            fontSize: 12.5,
                            height: 1.38,
                            color: const Color(0xFF991B1B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ảnh chứng minh thu nhập (${_selectedImages.length}/$_maxImages)',
                          style: GoogleFonts.roboto(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: kTfText,
                          ),
                        ),
                        Text(
                          'JPG/PNG • tối đa 8MB/ảnh',
                          style: GoogleFonts.roboto(
                            fontSize: 11.5,
                            color: kTfMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_selectedImages.isNotEmpty) ...[
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(_selectedImages.length, (index) {
                          final file = _selectedImages[index];
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  file,
                                  width: 88,
                                  height: 88,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 88,
                                    height: 88,
                                    color: kTfBg,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: kTfMuted,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: GestureDetector(
                                  onTap: _isSubmitting
                                      ? null
                                      : () {
                                          setState(() {
                                            _selectedImages.removeAt(index);
                                            _inlineError = null;
                                          });
                                        },
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.72),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_selectedImages.length < _maxImages)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isPicking || _isSubmitting
                                  ? null
                                  : _pickFromGallery,
                              icon: const Icon(Iconsax.gallery, size: 18),
                              label: Text(
                                'Chọn từ thư viện',
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kTfPinkDark,
                                side: BorderSide(
                                  color: kTfPink.withValues(alpha: 0.45),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isPicking || _isSubmitting
                                  ? null
                                  : _captureWithCamera,
                              icon: const Icon(Iconsax.camera, size: 18),
                              label: Text(
                                'Chụp ảnh',
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kTfText,
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),
                    Text(
                      'Ghi chú bổ sung (không bắt buộc)',
                      style: GoogleFonts.roboto(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: kTfText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      maxLength: 500,
                      maxLines: 3,
                      enabled: !_isSubmitting,
                      decoration: InputDecoration(
                        hintText:
                            'Ví dụ: Đính kèm bảng lương và sao kê tài khoản ngân hàng 3 tháng gần nhất...',
                        hintStyle: GoogleFonts.roboto(
                          fontSize: 13,
                          color: kTfMuted,
                        ),
                        filled: true,
                        fillColor: kTfBg,
                        counterStyle: GoogleFonts.roboto(
                          fontSize: 11,
                          color: kTfMuted,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: kTfPink),
                        ),
                      ),
                    ),
                    if (_inlineError != null && _inlineError!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.error_outline_rounded,
                              size: 15,
                              color: kPostpaidExpense,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _inlineError!,
                              style: GoogleFonts.roboto(
                                fontSize: 12.5,
                                color: kPostpaidExpense,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            (_isSubmitting ||
                                _isPicking ||
                                _selectedImages.isEmpty)
                            ? null
                            : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kTfPink,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade200,
                          disabledForegroundColor: Colors.grey.shade500,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.3,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Gửi hồ sơ mở khóa',
                                style: GoogleFonts.roboto(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProofCameraCaptureScreen extends StatefulWidget {
  const _ProofCameraCaptureScreen();

  @override
  State<_ProofCameraCaptureScreen> createState() =>
      _ProofCameraCaptureScreenState();
}

class _ProofCameraCaptureScreenState extends State<_ProofCameraCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  File? _capturedFile;
  bool _isCapturing = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'Không tìm thấy camera trên thiết bị');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      final initFuture = controller.initialize();
      _initFuture = initFuture;
      await initFuture;
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(
          () => _cameraError = 'Không thể khởi động camera, vui lòng thử lại',
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (_isCapturing ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }
    setState(() => _isCapturing = true);
    try {
      final xFile = await controller.takePicture();
      if (!mounted) return;
      setState(() => _capturedFile = File(xFile.path));
    } catch (_) {
      if (!mounted) return;
      SnackbarUtils.failure(context, 'Chụp ảnh thất bại, vui lòng thử lại');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewFile = _capturedFile;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          previewFile != null ? 'Kiểm tra ảnh chụp' : 'Chụp ảnh chứng từ',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: previewFile != null
          ? Column(
              children: [
                Expanded(
                  child: Center(
                    child: Image.file(previewFile, fit: BoxFit.contain),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () =>
                                  setState(() => _capturedFile = null),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Chụp lại',
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context, previewFile),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kTfPink,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Dùng ảnh này',
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : _cameraError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _cameraError!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(color: Colors.white, fontSize: 15),
                ),
              ),
            )
          : FutureBuilder<void>(
              future: _initFuture,
              builder: (context, snapshot) {
                final controller = _controller;
                if (snapshot.connectionState != ConnectionState.done ||
                    controller == null ||
                    !controller.value.isInitialized) {
                  return const Center(
                    child: CircularProgressIndicator(color: kTfPink),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: Center(child: CameraPreview(controller)),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: GestureDetector(
                          onTap: _isCapturing ? null : _takePicture,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: kTfPink,
                            ),
                            child: _isCapturing
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Icon(
                                    Iconsax.camera,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
