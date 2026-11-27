// Apple Watch companion sync, iPhone side (docs/PRD_v10.md section 4).
//
// Flutter (lib/application/watch_sync.dart) sends a small state: the
// language, the last-read verse ID and the bookmarked verse IDs. This file
// keeps the latest copy and hands it to the watch through WatchConnectivity's
// application context, which the system delivers when the watch can take it
// (latest state only, so offline changes are never queued up).
//
// The watch ships its own copy of the verse text, so no scripture is ever
// sent. Nothing here touches the network: WatchConnectivity talks to the
// paired watch only.

import Flutter
import Foundation
import WatchConnectivity

final class WatchSync: NSObject, WCSessionDelegate {
  static let shared = WatchSync()

  private static let storeKey = "watch_sync_state"
  private var session: WCSession? {
    WCSession.isSupported() ? WCSession.default : nil
  }

  /// Starts the session at launch, so the watch's "send me the latest"
  /// request is answered even before Flutter is up.
  func activate() {
    guard let session else { return }
    session.delegate = self
    session.activate()
  }

  /// Registers the method channel Flutter uses.
  func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.onescrollgita.app/watch",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "update" else {
        result(FlutterMethodNotImplemented)
        return
      }
      if let state = call.arguments as? [String: Any] {
        self?.store(state)
        self?.push()
      }
      result(nil)
    }
  }

  // MARK: - State

  private func store(_ state: [String: Any]) {
    // JSON drops NSNull (a missing last-read verse) cleanly.
    let clean = state.filter { !($0.value is NSNull) }
    UserDefaults.standard.set(clean, forKey: Self.storeKey)
  }

  private var stored: [String: Any]? {
    UserDefaults.standard.dictionary(forKey: Self.storeKey)
  }

  /// Hands the stored state to the watch if one with the app is paired.
  private func push() {
    guard let session, session.activationState == .activated,
      session.isPaired, session.isWatchAppInstalled,
      let state = stored
    else { return }
    if NSDictionary(dictionary: session.applicationContext)
      .isEqual(to: state)
    {
      return
    }
    try? session.updateApplicationContext(state)
  }

  // MARK: - WCSessionDelegate

  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    push()
  }

  /// The watch app was installed or the pairing changed.
  func sessionWatchStateDidChange(_ session: WCSession) {
    push()
  }

  /// The watch asks for the latest state (on open, while reachable).
  func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
  ) {
    replyHandler(stored ?? [:])
  }

  func sessionDidBecomeInactive(_ session: WCSession) {}

  /// Switching to another watch: activate again for the new one.
  func sessionDidDeactivate(_ session: WCSession) {
    session.activate()
  }
}
