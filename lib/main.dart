import 'dart:async';

import 'package:app/core/services/app_bootstrap.dart';
import 'package:app/core/services/connectivity_service.dart';
import 'package:app/core/services/firebase_bootstrap.dart';
import 'package:app/core/widgets/network_status_banner.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GestureBinding.instance.resamplingEnabled = true;
  // Khởi tạo Firebase song song thay vì chờ tuần tự với các API khởi động.
  unawaited(ensureFirebaseInitialized().catchError((_) {}));
  final initialScreen = await resolveInitialScreen();
  runApp(MainApp(initialScreen: initialScreen));
}

class MainApp extends StatefulWidget {
  final Widget initialScreen;

  const MainApp({super.key, required this.initialScreen});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  static final ThemeData _lightTheme = _buildLightTheme();

  @override
  void initState() {
    super.initState();
    unawaited(ConnectivityService.instance.initialize());
    // Gỡ Native Splash ngay sau khi frame đầu tiên của màn hình đích vẽ xong.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SplashBridge.hide();
    });
  }

  static const Color _kAppBg = Color(0xFFFAF6F8);

  static ThemeData _buildLightTheme() {
    final robotoTextTheme = GoogleFonts.robotoTextTheme(
      ThemeData.light().textTheme,
    );

    return ThemeData(
      // Nền đặc 100% (không dùng alpha < 1) để tránh lộ nền đen gốc của RenderView
      // làm màn Home bị giảm độ sáng sau khi transition quay lại kết thúc.
      scaffoldBackgroundColor: _kAppBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFEC407A),
        surface: _kAppBg,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(
            fallbackColor: _kAppBg,
          ),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(
            backgroundColor: _kAppBg,
          ),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(
            backgroundColor: _kAppBg,
          ),
        },
      ),
      textTheme: robotoTextTheme,
      primaryTextTheme: robotoTextTheme,
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: GoogleFonts.roboto(),
        floatingLabelStyle: GoogleFonts.roboto(),
        hintStyle: GoogleFonts.roboto(),
        errorStyle: GoogleFonts.roboto(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: GoogleFonts.roboto(),
        suffixStyle: GoogleFonts.roboto(),
        prefixStyle: GoogleFonts.roboto(),
      ),
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: GoogleFonts.roboto(fontSize: 14),
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
        contentTextStyle: GoogleFonts.roboto(
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('vi', 'VN'),
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: _lightTheme,
      builder: (context, child) {
        return NetworkStatusOverlay(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: widget.initialScreen,
    );
  }
}
