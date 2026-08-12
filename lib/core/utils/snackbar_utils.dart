import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SnackbarType { success, failure, info }

class SnackbarUtils {
  SnackbarUtils._();

  static void success(BuildContext context, String message, {String? title}) {
    _show(context, title: title ?? 'Thành công', message: message, type: SnackbarType.success);
  }

  static void failure(BuildContext context, String message, {String? title}) {
    _show(context, title: title ?? 'Thất bại', message: message, type: SnackbarType.failure);
  }

  static void info(BuildContext context, String message, {String? title}) {
    _show(context, title: title ?? 'Thông báo', message: message, type: SnackbarType.info);
  }

  static void _show(
    BuildContext context, {
    required String title,
    required String message,
    required SnackbarType type,
  }) {
    final config = _configFor(type);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: config.background,
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: config.accent, width: 0),
        ),
        duration: const Duration(seconds: 3),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: config.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(config.icon, color: config.foreground, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      color: config.foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: GoogleFonts.roboto(
                      color: config.foreground.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _SnackConfig _configFor(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return _SnackConfig(
          background: const Color(0xFFE9F9EE),
          foreground: const Color(0xFF1B7A3D),
          accent: const Color(0xFF22C55E),
          icon: Icons.check_circle_rounded,
        );
      case SnackbarType.failure:
        return _SnackConfig(
          background: const Color(0xFFFDECEC),
          foreground: const Color(0xFFB3261E),
          accent: const Color(0xFFEF4444),
          icon: Icons.cancel_rounded,
        );
      case SnackbarType.info:
        return _SnackConfig(
          background: const Color(0xFFEAF2FE),
          foreground: const Color(0xFF1D4ED8),
          accent: const Color(0xFF3B82F6),
          icon: Icons.info_rounded,
        );
    }
  }
}

class _SnackConfig {
  final Color background;
  final Color foreground;
  final Color accent;
  final IconData icon;

  const _SnackConfig({
    required this.background,
    required this.foreground,
    required this.accent,
    required this.icon,
  });
}