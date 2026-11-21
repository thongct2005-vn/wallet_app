import 'package:app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage msg) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void>? _firebaseInitFuture;

/// Khởi tạo Firebase một lần theo cơ chế lazy/non-blocking để không chặn `runApp`.
Future<void> ensureFirebaseInitialized() {
  final existing = _firebaseInitFuture;
  if (existing != null) return existing;

  final future = () async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }();

  _firebaseInitFuture = future;
  future.catchError((_) {
    if (identical(_firebaseInitFuture, future)) {
      _firebaseInitFuture = null;
    }
  });
  return future;
}

