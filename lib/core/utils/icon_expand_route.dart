import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

/// Route tạo hiệu ứng phóng to màn hình từ đúng vị trí ô Icon được nhấn
/// và thu nhỏ trở lại đúng ô Icon đó khi thoát màn hình (pop).
class IconExpandRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;
  final GlobalKey iconKey;
  final IconData icon;

  IconExpandRoute({
    required this.builder,
    required this.iconKey,
    required this.icon,
    super.settings,
  }) : super(
         opaque: true,
         barrierColor: Colors.transparent,
         transitionDuration: const Duration(milliseconds: 400),
         reverseTransitionDuration: const Duration(milliseconds: 340),
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
       );

  Rect? _cachedOriginRect;

  Rect _resolveOriginRect(Size screenSize) {
    final context = iconKey.currentContext;
    if (context != null) {
      final renderObject = context.findRenderObject();
      if (renderObject is RenderBox && renderObject.hasSize) {
        final offset = renderObject.localToGlobal(Offset.zero);
        _cachedOriginRect = offset & renderObject.size;
        return _cachedOriginRect!;
      }
    }
    return _cachedOriginRect ??
        Rect.fromCenter(
          center: Offset(screenSize.width / 2, screenSize.height / 3),
          width: 56,
          height: 56,
        );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final screenSize = MediaQuery.sizeOf(context);
    final originRect = _resolveOriginRect(screenSize);
    final fullRect = Offset.zero & screenSize;

    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return AnimatedBuilder(
      animation: curvedAnimation,
      child: RepaintBoundary(child: child),
      builder: (context, cachedChild) {
        final t = curvedAnimation.value;
        if (t >= 0.999) {
          return cachedChild!;
        }

        final currentRect = Rect.lerp(originRect, fullRect, t)!;
        // Bo góc 18px ở trạng thái icon, bo nhẹ như viền điện thoại khi đang bung, và 0px khi mở hẳn
        final cornerRadius =
            lerpDouble(18.0, 0.0, t)! + (24.0 * 4.0 * t * (1.0 - t));

        // Tỉ lệ thu phóng đồng nhất theo chiều ngang để nội dung màn hình không bị méo
        final scale = currentRect.width / screenSize.width;

        // Độ mờ của lớp phủ icon màu hồng (hiện rõ ở đầu/cuối hiệu ứng, mờ dần khi màn hình mở ra)
        final iconOverlayOpacity = (1.0 - (t / 0.38)).clamp(0.0, 1.0);
        // Độ mờ của nội dung màn hình đích
        final contentOpacity = ((t - 0.08) / 0.35).clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Lớp nền mờ phía sau khi màn hình đang phóng to / thu nhỏ
            IgnorePointer(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.25 * t),
              ),
            ),
            // Khung cắt bo góc di chuyển từ vị trí icon ra toàn màn hình
            ClipPath(
              clipper: _RRectRevealClipper(
                rect: currentRect,
                radius: cornerRadius,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Nền hồng đồng bộ khi bắt đầu bung
                  if (contentOpacity < 1.0)
                    const ColoredBox(color: Color(0xFFFAF6F8)),
                  // Nội dung màn hình đích được scale & dịch chuyển theo tâm của khung cắt
                  if (contentOpacity > 0.0)
                    Opacity(
                      opacity: contentOpacity,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..translateByDouble(
                            currentRect.center.dx - screenSize.width / 2,
                            currentRect.center.dy - screenSize.height / 2,
                            0.0,
                            1.0,
                          )
                          ..scaleByDouble(scale, scale, 1.0, 1.0),
                        child: cachedChild,
                      ),
                    ),
                  // Lớp phủ ô Icon màu hồng lúc bắt đầu phóng to và lúc kết thúc thu nhỏ
                  if (iconOverlayOpacity > 0.0)
                    Positioned.fromRect(
                      rect: currentRect,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: iconOverlayOpacity,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFF06292), Color(0xFFD81B60)],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                icon,
                                color: Colors.white,
                                size: lerpDouble(26.0, 44.0, t)!,
                              ),
                            ),
                          ),
                        ),
                      ),
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

class _RRectRevealClipper extends CustomClipper<Path> {
  final Rect rect;
  final double radius;

  const _RRectRevealClipper({required this.rect, required this.radius});

  @override
  Path getClip(Size size) {
    return Path()..addRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
    );
  }

  @override
  bool shouldReclip(covariant _RRectRevealClipper oldClipper) {
    return oldClipper.rect != rect || oldClipper.radius != radius;
  }
}

