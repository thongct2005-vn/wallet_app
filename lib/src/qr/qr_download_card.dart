import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app/core/utils/format_utils.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Che chữ số đầu của SĐT, giữ 3 số cuối (vd: 0912345437 -> *******437).
String maskQrPhoneNumber(String? rawPhone) {
  final phone = (rawPhone ?? '').trim();
  if (phone.isEmpty) return '';
  if (phone.length <= 3) return '*' * phone.length;
  return '${'*' * (phone.length - 3)}${phone.substring(phone.length - 3)}';
}

/// Template ảnh QR dùng khi tải về máy (không kèm VietQR / Napas).
class QrDownloadCard extends StatelessWidget {
  final String qrData;
  final String fullName;
  final String phone;
  final String avatarText;
  final int? amount;
  final String? description;

  const QrDownloadCard({
    super.key,
    required this.qrData,
    required this.fullName,
    required this.phone,
    required this.avatarText,
    this.amount,
    this.description,
  });

  static const Color _bgPink = Color(0xFFFCEEF5);
  static const Color _cardBorderPink = Color(0xFFF3BBD4);
  static const Color _dividerColor = Color(0xFFEAECEF);
  static const Color _amountBlue = Color(0xFF2176E8);
  static const Color _nameColor = Color(0xFF33333A);
  static const Color _mutedTextColor = Color(0xFF55555E);

  @override
  Widget build(BuildContext context) {
    final trimmedName = fullName.trim().toUpperCase();
    final maskedPhone = maskQrPhoneNumber(phone);
    final trimmedNote = (description ?? '').trim();
    final bool hasAmount = amount != null && amount! > 0;
    final bool hasNote = trimmedNote.isNotEmpty;
    final bool hasBottomSection = hasAmount || hasNote;

    final double topPad = hasBottomSection ? 28 : 38;
    final double logoToCardGap = hasBottomSection ? 24 : 32;
    final double cardToNameGap = hasBottomSection ? 24 : 34;
    final double bottomPad = hasBottomSection ? 26 : 34;

    return Container(
      width: 420,
      color: _bgPink,
      padding: EdgeInsets.fromLTRB(24, topPad, 24, bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mio',
            style: GoogleFonts.roboto(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: kTfPinkDark,
              height: 1.0,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: logoToCardGap),
          Container(
            width: 224,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cardBorderPink, width: 1.4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 192,
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                      ),
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _bgPink,
                          ),
                          child: Text(
                            avatarText,
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kTfPinkDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasBottomSection) ...[
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: _dividerColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasAmount)
                          Text(
                            '${FormatUtils.formatDisplayNumber(amount!)}đ',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: _amountBlue,
                              height: 1.2,
                            ),
                          ),
                        if (hasAmount && hasNote) const SizedBox(height: 4),
                        if (hasNote)
                          Text(
                            trimmedNote,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              color: _mutedTextColor,
                              height: 1.25,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trimmedName.isNotEmpty || maskedPhone.isNotEmpty) ...[
            SizedBox(height: cardToNameGap),
            if (trimmedName.isNotEmpty)
              Text(
                trimmedName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: _nameColor,
                  letterSpacing: 0.6,
                  height: 1.2,
                ),
              ),
            if (trimmedName.isNotEmpty && maskedPhone.isNotEmpty)
              const SizedBox(height: 6),
            if (maskedPhone.isNotEmpty)
              Text(
                maskedPhone,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _mutedTextColor,
                  letterSpacing: 1.2,
                  height: 1.2,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Render một widget ngoài khung hình thông qua Overlay và xuất ra PNG bytes.
Future<Uint8List?> captureQrExportPng(
  BuildContext context,
  Widget widget, {
  double pixelRatio = 3.0,
}) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return null;

  final captureKey = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => IgnorePointer(
      child: ExcludeSemantics(
        child: Transform.translate(
          offset: const Offset(-10000, -10000),
          child: Align(
            alignment: Alignment.topLeft,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: 0,
              maxWidth: double.infinity,
              minHeight: 0,
              maxHeight: double.infinity,
              child: Material(
                type: MaterialType.transparency,
                child: RepaintBoundary(key: captureKey, child: widget),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  try {
    await WidgetsBinding.instance.endOfFrame;
    await GoogleFonts.pendingFonts();
    await WidgetsBinding.instance.endOfFrame;

    final boundary =
        captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    if (boundary.debugNeedsPaint) {
      await WidgetsBinding.instance.endOfFrame;
    }

    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    entry.remove();
  }
}

