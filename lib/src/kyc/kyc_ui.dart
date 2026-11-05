import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// Bảng màu đồng bộ với hệ thống thiết kế Ví Mio (transfer_ui / topup_withdraw).
const Color kKycPink = Color(0xFFEC407A);
const Color kKycPinkDark = Color(0xFFD81B60);
const Color kKycPinkLight = Color(0xFFF48FB1);
const Color kKycPinkSoft = Color(0xFFFCE4EC);
const Color kKycBg = Color(0xFFFAF6F8);
const Color kKycText = Color(0xFF1F1B24);
const Color kKycMuted = Color(0xFF8A8590);
const Color kKycSuccess = Color(0xFF2E9E5B);
const Color kKycSuccessBright = Color(0xFF34D399);
const Color kKycError = Color(0xFFE53935);
const Color kKycDarkBg = Color(0xFF121016);
const Color kKycDarkCard = Color(0xFF1D1924);

/// Thẻ trắng bo góc kèm bóng hồng dịu cho các màn sáng (Guide / Result).
BoxDecoration kycCardDeco({double radius = 22}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: [
    BoxShadow(
      color: kKycPink.withValues(alpha: 0.08),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ],
);

/// Dải nền chuyển sắc hồng dịu phía đầu màn hình sáng.
class KycHeaderGradient extends StatelessWidget {
  final double height;
  const KycHeaderGradient({super.key, this.height = 360});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            kKycPink.withValues(alpha: 0.24),
            kKycPinkLight.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

/// Nút tròn điều hướng trên AppBar (hỗ trợ cả nền sáng và nền tối camera).
class KycCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isDark;
  final Color? iconColor;
  final String? tooltip;
  final EdgeInsetsGeometry padding;

  const KycCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isDark = false,
    this.iconColor,
    this.tooltip,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
        shape: BoxShape.circle,
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.16))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: kKycPink.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 19,
          color: iconColor ?? (isDark ? Colors.white : kKycText),
        ),
      ),
    );

    if (padding == EdgeInsets.zero) return button;
    return Padding(padding: padding, child: button);
  }
}

/// Nút chính gradient hồng đặc trưng của Ví Mio.
class KycPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool loading;
  final IconData? icon;
  final IconData? trailingIcon;
  final double height;

  const KycPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.loading = false,
    this.icon,
    this.trailingIcon,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = enabled && !loading;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: active ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFFF06292), kKycPinkDark],
                  )
                : null,
            color: active ? null : Colors.black.withValues(alpha: 0.1),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: kKycPink.withValues(alpha: 0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                )
              else if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],
              if (!loading)
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? Colors.white
                        : Colors.grey.withValues(alpha: 0.7),
                    letterSpacing: 0.2,
                  ),
                ),
              if (!loading && trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, color: Colors.white, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Đường kẻ nét đứt màu hồng nhạt trong các thẻ kết quả / hướng dẫn.
class KycDashedDivider extends StatelessWidget {
  const KycDashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: kKycPink.withValues(alpha: 0.16),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Thanh tiêu đề kèm tiến trình 3 bước trên các màn camera & xem trước ảnh.
class KycCameraTopBar extends StatelessWidget {
  final int currentStep;
  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  const KycCameraTopBar({
    super.key,
    required this.currentStep,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  String get _stepSubtitle {
    switch (currentStep) {
      case 1:
        return 'Bước 1/3 • Mặt trước giấy tờ';
      case 2:
        return 'Bước 2/3 • Mặt sau giấy tờ';
      default:
        return 'Bước 3/3 • Xác thực khuôn mặt';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kKycDarkBg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  KycCircleButton(
                    isDark: true,
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: onBack,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _stepSubtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            color: kKycPinkLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing ?? const SizedBox(width: 40, height: 40),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(3, (index) {
                  final step = index + 1;
                  final isCompletedOrCurrent = step <= currentStep;
                  final isCurrent = step == currentStep;
                  return Expanded(
                    child: Container(
                      height: 4.5,
                      margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: isCompletedOrCurrent
                            ? const LinearGradient(
                                colors: [kKycPinkLight, kKycPink],
                              )
                            : null,
                        color: isCompletedOrCurrent
                            ? null
                            : Colors.white.withValues(alpha: 0.16),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: kKycPink.withValues(alpha: 0.45),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Khung quét thẻ CCCD/CMND có góc bo phát sáng và nhãn hướng dẫn trực quan.
class KycIdScannerOverlay extends StatelessWidget {
  final IconData badgeIcon;
  final String badgeLabel;
  final String instruction;
  final String subInstruction;

  const KycIdScannerOverlay({
    super.key,
    required this.badgeIcon,
    required this.badgeLabel,
    required this.instruction,
    required this.subInstruction,
  });

  static const double _cardAspectRatio = 1.586;
  static const double _horizontalMargin = 22.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final cardWidth = (size.width - _horizontalMargin * 2).clamp(
          200.0,
          500.0,
        );
        final cardHeight = cardWidth / _cardAspectRatio;
        final centerY = (size.height * 0.39).clamp(
          cardHeight / 2 + 58,
          size.height - cardHeight / 2 - 150,
        );
        final cardRect = Rect.fromCenter(
          center: Offset(size.width / 2, centerY),
          width: cardWidth,
          height: cardHeight,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              size: size,
              painter: _KycIdCutoutPainter(cardRect: cardRect),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: (cardRect.top - 48).clamp(12.0, size.height),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: kKycDarkCard.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: kKycPinkLight.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 16, color: kKycPinkLight),
                      const SizedBox(width: 7),
                      Text(
                        badgeLabel,
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: cardRect.bottom + 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    instruction,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subInstruction,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _KycCameraTipChip(
                        icon: Icons.wb_sunny_outlined,
                        label: 'Đủ sáng',
                      ),
                      _KycCameraTipChip(
                        icon: Icons.flare_rounded,
                        label: 'Không chói',
                      ),
                      _KycCameraTipChip(
                        icon: Icons.crop_free_rounded,
                        label: 'Rõ 4 góc',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KycCameraTipChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _KycCameraTipChip({required this.icon, required this.label});

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

class _KycIdCutoutPainter extends CustomPainter {
  final Rect cardRect;
  static const double _radius = 18.0;

  const _KycIdCutoutPainter({required this.cardRect});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      cardRect,
      const Radius.circular(_radius),
    );

    final bgPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addRRect(rrect);
    final maskPath = Path.combine(PathOperation.difference, bgPath, holePath);

    canvas.drawPath(
      maskPath,
      Paint()..color = kKycDarkBg.withValues(alpha: 0.76),
    );

    // Viền mảnh toàn khung thẻ
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Hiệu ứng phát sáng nhẹ tại 4 góc định vị
    final cornerGlowPaint = Paint()
      ..color = kKycPink.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final cornerPaint = Paint()
      ..color = kKycPinkLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final cornerPath = _buildCornerBrackets(cardRect, _radius, 28.0);
    canvas.drawPath(cornerPath, cornerGlowPaint);
    canvas.drawPath(cornerPath, cornerPaint);
  }

  Path _buildCornerBrackets(Rect rect, double r, double arm) {
    final path = Path();

    // Góc trên trái
    path.moveTo(rect.left, rect.top + arm);
    path.lineTo(rect.left, rect.top + r);
    path.arcToPoint(
      Offset(rect.left + r, rect.top),
      radius: Radius.circular(r),
    );
    path.lineTo(rect.left + arm, rect.top);

    // Góc trên phải
    path.moveTo(rect.right - arm, rect.top);
    path.lineTo(rect.right - r, rect.top);
    path.arcToPoint(
      Offset(rect.right, rect.top + r),
      radius: Radius.circular(r),
    );
    path.lineTo(rect.right, rect.top + arm);

    // Góc dưới phải
    path.moveTo(rect.right, rect.bottom - arm);
    path.lineTo(rect.right, rect.bottom - r);
    path.arcToPoint(
      Offset(rect.right - r, rect.bottom),
      radius: Radius.circular(r),
    );
    path.lineTo(rect.right - arm, rect.bottom);

    // Góc dưới trái
    path.moveTo(rect.left + arm, rect.bottom);
    path.lineTo(rect.left + r, rect.bottom);
    path.arcToPoint(
      Offset(rect.left, rect.bottom - r),
      radius: Radius.circular(r),
    );
    path.lineTo(rect.left, rect.bottom - arm);

    return path;
  }

  @override
  bool shouldRepaint(covariant _KycIdCutoutPainter oldDelegate) {
    return oldDelegate.cardRect != cardRect;
  }
}

/// Nút bấm chụp ảnh tròn nổi bật cho màn chụp CCCD.
class KycShutterButton extends StatelessWidget {
  final bool isCapturing;
  final VoidCallback onTap;

  const KycShutterButton({
    super.key,
    required this.isCapturing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: isCapturing ? null : onTap,
              child: Container(
                width: 78,
                height: 78,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: kKycPink.withValues(alpha: 0.38),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF48FB1), kKycPinkDark],
                    ),
                  ),
                  child: Center(
                    child: isCapturing
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCapturing ? 'Đang xử lý ảnh...' : 'Nhấn để chụp ảnh',
              style: GoogleFonts.roboto(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Giao diện xem lại ảnh chụp đồng bộ cho cả 3 bước (Mặt trước, Mặt sau, Khuôn mặt).
class KycPhotoPreviewView extends StatelessWidget {
  final File imageFile;
  final String previewLabel;
  final String qualityHint;
  final String confirmLabel;
  final VoidCallback onRetake;
  final VoidCallback onConfirm;
  final bool mirrorHorizontal;

  const KycPhotoPreviewView({
    super.key,
    required this.imageFile,
    required this.previewLabel,
    required this.qualityHint,
    required this.confirmLabel,
    required this.onRetake,
    required this.onConfirm,
    this.mirrorHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget photo = Image.file(imageFile, fit: BoxFit.contain);
    if (mirrorHorizontal) {
      photo = Transform.scale(scaleX: -1, child: photo);
    }

    return Container(
      color: kKycDarkBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kKycDarkCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: photo,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.62),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: kKycSuccessBright.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Iconsax.tick_circle,
                                  size: 15,
                                  color: kKycSuccessBright,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  previewLabel,
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: kKycDarkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kKycPinkLight.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: kKycPink.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Iconsax.shield_tick,
                        size: 18,
                        color: kKycPinkLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        qualityHint,
                        style: GoogleFonts.roboto(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onRetake,
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Iconsax.refresh,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Chụp lại',
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: KycPrimaryButton(
                      height: 52,
                      label: confirmLabel,
                      icon: Iconsax.tick_circle,
                      onTap: onConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

