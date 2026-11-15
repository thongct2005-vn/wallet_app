import 'package:app/firebase_options.dart';
import 'package:app/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _fireBaseMessagingBackgroundHandler(RemoteMessage msg) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GestureBinding.instance.resamplingEnabled = true;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_fireBaseMessagingBackgroundHandler);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final robotoTextTheme = GoogleFonts.robotoTextTheme(
      ThemeData.light().textTheme,
    );

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
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white.withValues(alpha: 0.95),
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
      ),
      home: const SplashScreen(),
    );
  }
}
