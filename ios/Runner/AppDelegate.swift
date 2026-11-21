import Flutter
import Network
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var pathMonitor: NWPathMonitor?
  private var eventSink: FlutterEventSink?
  private var lastConnected: Bool?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()
    let methodChannel = FlutterMethodChannel(
      name: "com.example.app/connectivity",
      binaryMessenger: messenger
    )
    methodChannel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "checkConnectivity":
        if let monitor = self?.pathMonitor {
          result(monitor.currentPath.status == .satisfied)
        } else {
          result(true)
        }
      case "openNetworkSettings":
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else {
          result(false)
          return
        }
        UIApplication.shared.open(url, options: [:]) { success in
          result(success)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let eventChannel = FlutterEventChannel(
      name: "com.example.app/connectivity_events",
      binaryMessenger: messenger
    )
    eventChannel.setStreamHandler(ConnectivityStreamHandler(owner: self))
  }

  fileprivate func startMonitoring(sink: @escaping FlutterEventSink) {
    stopMonitoring()
    eventSink = sink
    let monitor = NWPathMonitor()
    monitor.pathUpdateHandler = { [weak self] path in
      let connected = path.status == .satisfied
      DispatchQueue.main.async {
        guard let self = self, let activeSink = self.eventSink else { return }
        if self.lastConnected != connected {
          self.lastConnected = connected
          activeSink(connected)
        }
      }
    }
    pathMonitor = monitor
    monitor.start(queue: DispatchQueue.global(qos: .utility))
  }

  fileprivate func stopMonitoring() {
    pathMonitor?.cancel()
    pathMonitor = nil
    eventSink = nil
    lastConnected = nil
  }
}

private final class ConnectivityStreamHandler: NSObject, FlutterStreamHandler {
  weak var owner: AppDelegate?

  init(owner: AppDelegate?) {
    self.owner = owner
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    owner?.startMonitoring(sink: events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    owner?.stopMonitoring()
    return nil
  }
}
