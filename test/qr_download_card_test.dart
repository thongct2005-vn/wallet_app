import 'dart:io';

import 'package:app/src/qr/qr_download_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('maskQrPhoneNumber keeps last 3 digits', () {
    expect(maskQrPhoneNumber('0912345437'), '*******437');
    expect(maskQrPhoneNumber('0388112233'), '*******233');
    expect(maskQrPhoneNumber('437'), '***');
    expect(maskQrPhoneNumber(''), '');
    expect(maskQrPhoneNumber(null), '');
  });

  testWidgets('QrDownloadCard renders static QR without VietQR or Napas', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QrDownloadCard(
              qrData: 'STATIC_MIO_QR_TOKEN_SAMPLE',
              fullName: 'Phan Văn Thông',
              phone: '0912345437',
              avatarText: 'VT',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Mio'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('VT'), findsOneWidget);
    expect(find.text('PHAN VĂN THÔNG'), findsOneWidget);
    expect(find.text('*******437'), findsOneWidget);
    expect(find.textContaining('VIETQR'), findsNothing);
    expect(find.textContaining('napas'), findsNothing);
  });

  testWidgets('QrDownloadCard renders dynamic QR with amount and note', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QrDownloadCard(
              qrData: 'DYNAMIC_MIO_QR_TOKEN_SAMPLE',
              fullName: 'Phan Văn Thông',
              phone: '0912345437',
              avatarText: 'VT',
              amount: 66666,
              description: 'Tiền nước',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Mio'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('66.666đ'), findsOneWidget);
    expect(find.text('Tiền nước'), findsOneWidget);
    expect(find.text('PHAN VĂN THÔNG'), findsOneWidget);
    expect(find.text('*******437'), findsOneWidget);
  });

  testWidgets('captureQrExportPng captures offscreen Overlay card to PNG', (
    tester,
  ) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox(width: 300, height: 600);
            },
          ),
        ),
      ),
    );

    final captureFuture = captureQrExportPng(
      capturedContext,
      const QrDownloadCard(
        qrData: 'STATIC_MIO_QR_TOKEN_SAMPLE',
        fullName: 'Phan Văn Thông',
        phone: '0912345437',
        avatarText: 'VT',
        amount: 66666,
        description: 'Tiền nước',
      ),
      pixelRatio: 2.0,
    );

    // Pump frames so endOfFrame inside captureQrExportPng resolves.
    await tester.pump();
    await tester.pump();
    await tester.pump();

    final pngBytes = await tester.runAsync(() => captureFuture);
    expect(pngBytes, isNotNull);
    expect(pngBytes!.length, greaterThan(1000));
    // PNG magic header: 89 50 4E 47 0D 0A 1A 0A
    expect(pngBytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);

    // Write preview PNG to scratch so we can verify layout/rendering.
    final previewFile = File(
      r'C:\Users\ADMIN\.gemini\antigravity\brain\fe6a8078-8bc4-4c8d-9893-18eb46f0c535\scratch\qr_preview.png',
    );
    await tester.runAsync(() async {
      await previewFile.parent.create(recursive: true);
      await previewFile.writeAsBytes(pngBytes, flush: true);
    });
  });
}

