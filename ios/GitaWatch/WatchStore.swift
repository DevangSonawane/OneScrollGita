// Watch side of the sync (docs/PRD_v10.md section 4). The iPhone app is the
// only place bookmarks and the reading position are kept; this is a
// read-only mirror of the IDs it last sent, cached so the watch works when
// the phone is away. Verse text comes from the watch's own copy.

import Foundation
import WatchConnectivity
import WidgetKit

@MainActor
final class WatchStore: NSObject, ObservableObject {
  @Published private(set) var language: String
  @Published private(set) var lastVerseId: String?
  @Published private(set) var bookmarkIds: [String]
  /// When the phone's state last arrived; nil until the first sync.
  @Published private(set) var syncedAt: Date?

  private enum Key {
    static let lastVerse = "watch_last_verse_id"
    static let bookmarks = "watch_bookmarks"
    static let syncedAt = "watch_synced_at"
  }

  private let defaults = SharedState.defaults

  override init() {
    language = SharedState.language
    lastVerseId = defaults.string(forKey: Key.lastVerse)
    bookmarkIds = defaults.stringArray(forKey: Key.bookmarks) ?? []
    syncedAt = defaults.object(forKey: Key.syncedAt) as? Date
    super.init()
    if WCSession.isSupported() {
      WCSession.default.delegate = self
      WCSession.default.activate()
    }
  }

  var bookmarks: [Verse] {
    bookmarkIds.compactMap { Scripture.shared.verse(id: $0) }
  }

  var lastVerse: Verse? {
    lastVerseId.flatMap { Scripture.shared.verse(id: $0) }
  }

  /// Asks the phone for its latest state when it is reachable (the app was
  /// opened). Otherwise the cached state stays, and the system delivers the
  /// phone's next application context later.
  func refresh() {
    let session = WCSession.default
    guard WCSession.isSupported(), session.activationState == .activated,
      session.isReachable
    else { return }
    session.sendMessage(["request": "state"]) { [weak self] reply in
      Task { @MainActor in self?.apply(reply) }
    } errorHandler: { _ in }
  }

  private func apply(_ state: [String: Any]) {
    // An empty reply means the phone has not sent anything yet.
    guard (state["v"] as? Int) == 1 else { return }
    let lang = state["lang"] as? String ?? "en"
    let last = state["lastVerseId"] as? String
    let ids = state["bookmarks"] as? [String] ?? []
    let now = Date()
    if lang != language {
      defaults.set(lang, forKey: SharedState.languageKey)
      language = lang
      // The complication shows the translation in this language.
      WidgetCenter.shared.reloadAllTimelines()
    }
    if last != lastVerseId {
      defaults.set(last, forKey: Key.lastVerse)
      lastVerseId = last
    }
    if ids != bookmarkIds {
      defaults.set(ids, forKey: Key.bookmarks)
      bookmarkIds = ids
    }
    defaults.set(now, forKey: Key.syncedAt)
    syncedAt = now
  }
}

extension WatchStore: WCSessionDelegate {
  nonisolated func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    let context = session.receivedApplicationContext
    Task { @MainActor in
      if !context.isEmpty { self.apply(context) }
      self.refresh()
    }
  }

  nonisolated func session(
    _ session: WCSession,
    didReceiveApplicationContext applicationContext: [String: Any]
  ) {
    Task { @MainActor in self.apply(applicationContext) }
  }

  nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
    Task { @MainActor in self.refresh() }
  }
}
