import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

enum NetworkBannerStatus {
  hidden,
  offline,
  restored,
}

typedef ConnectivityCheckCallback = Future<bool> Function();
typedef OpenNetworkSettingsCallback = Future<bool> Function();

class ConnectivityService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.example.app/connectivity');
  static const EventChannel _eventChannel =
      EventChannel('com.example.app/connectivity_events');

  static final ConnectivityService instance = ConnectivityService();

  final ConnectivityCheckCallback _checkConnectivity;
  final Stream<bool>? _externalStream;
  final OpenNetworkSettingsCallback _openSettings;
  final Duration restoredDuration;

  final ValueNotifier<NetworkBannerStatus> bannerStatus =
      ValueNotifier<NetworkBannerStatus>(NetworkBannerStatus.hidden);

  StreamSubscription<bool>? _subscription;
  Timer? _dismissTimer;
  bool? _lastKnownConnected;
  bool _initialized = false;

  bool get isConnected => _lastKnownConnected ?? true;
  bool get isBannerVisible =>
      bannerStatus.value != NetworkBannerStatus.hidden;

  ConnectivityService({
    ConnectivityCheckCallback? checkConnectivity,
    Stream<bool>? connectivityStream,
    OpenNetworkSettingsCallback? openSettings,
    this.restoredDuration = const Duration(seconds: 3),
  })  : _checkConnectivity = checkConnectivity ?? _defaultCheckConnectivity,
        _externalStream = connectivityStream,
        _openSettings = openSettings ?? _defaultOpenSettings;

  static Future<bool> _defaultCheckConnectivity() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('checkConnectivity');
      return result ?? true;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> _defaultOpenSettings() async {
    try {
      final opened =
          await _methodChannel.invokeMethod<bool>('openNetworkSettings');
      if (opened == true) return true;
    } on MissingPluginException {
      // Fallback dùng permission_handler trên nền tảng không cài channel riêng.
    } catch (_) {}

    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final stream = _externalStream ??
        _eventChannel
            .receiveBroadcastStream()
            .map((event) => event == true);

    _subscription = stream.listen(
      handleConnectivityUpdate,
      onError: (_) {},
    );

    await refresh();
  }

  Future<void> refresh() async {
    final connected = await _checkConnectivity();
    handleConnectivityUpdate(connected);
  }

  @visibleForTesting
  void handleConnectivityUpdate(bool connected) {
    if (!connected) {
      _dismissTimer?.cancel();
      _dismissTimer = null;
      _lastKnownConnected = false;
      bannerStatus.value = NetworkBannerStatus.offline;
      return;
    }

    final wasOffline =
        _lastKnownConnected == false ||
        bannerStatus.value == NetworkBannerStatus.offline;
    _lastKnownConnected = true;

    if (wasOffline) {
      _showRestoredBanner();
    }
  }

  void _showRestoredBanner() {
    _dismissTimer?.cancel();
    bannerStatus.value = NetworkBannerStatus.restored;
    _dismissTimer = Timer(restoredDuration, () {
      if (bannerStatus.value == NetworkBannerStatus.restored) {
        bannerStatus.value = NetworkBannerStatus.hidden;
      }
      _dismissTimer = null;
    });
  }

  void dismissBanner() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (bannerStatus.value == NetworkBannerStatus.restored) {
      bannerStatus.value = NetworkBannerStatus.hidden;
    }
  }

  Future<void> openNetworkSettings() async {
    await _openSettings();
  }

  void dispose() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }
}

