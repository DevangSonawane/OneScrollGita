// One Scroll Gita for Apple Watch (docs/PRD_v10.md): today's verse, a random
// verse, bookmarks and continue reading, plus the system Now Playing
// controls for audio playing on the iPhone. Native SwiftUI; no Flutter.

import SwiftUI
import WatchKit

@main
struct GitaWatchApp: App {
  @StateObject private var store = WatchStore()
  @Environment(\.scenePhase) private var scenePhase

  var body: some Scene {
    WindowGroup {
      HomeView()
        .environmentObject(store)
        .tint(.gitaAccent)
    }
    .onChange(of: scenePhase) { _, phase in
      if phase == .active { store.refresh() }
    }
  }
}

enum Route: Hashable {
  case today
  case random
  case verse(String)
  case bookmarks
  case listen
}

extension Color {
  /// The app's saffron accent (dark value of the iPhone widgets' accent;
  /// the watch is always dark).
  static let gitaAccent = Color(red: 0xE3 / 255, green: 0x9A / 255, blue: 0x5E / 255)
}

// MARK: - Home

struct HomeView: View {
  @EnvironmentObject private var store: WatchStore
  @State private var path: [Route] = []

  var body: some View {
    NavigationStack(path: $path) {
      List {
        if let today = Scripture.shared.daily() {
          NavigationLink(value: Route.today) {
            TodayCard(verse: today, language: store.language)
          }
        }
        NavigationLink(value: Route.random) {
          Label("Random Verse", systemImage: "shuffle")
        }
        NavigationLink(value: store.lastVerse.map { Route.verse($0.id) }) {
          VStack(alignment: .leading, spacing: 2) {
            Label("Continue Reading", systemImage: "book")
            Text(store.lastVerse.map { "Bhagavad-gītā \($0.label)" } ?? "Read on your iPhone first")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }
        .disabled(store.lastVerse == nil)
        NavigationLink(value: Route.bookmarks) {
          HStack {
            Label("Bookmarks", systemImage: "bookmark")
            Spacer()
            if !store.bookmarkIds.isEmpty {
              Text("\(store.bookmarks.count)")
                .foregroundStyle(.secondary)
            }
          }
        }
        NavigationLink(value: Route.listen) {
          Label("Now Playing", systemImage: "headphones")
        }
        Section {
          EmptyView()
        } footer: {
          Text(Scripture.shared.attribution)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
      .navigationTitle("Gita")
      .navigationDestination(for: Route.self) { route in
        switch route {
        case .today:
          if let verse = Scripture.shared.daily() {
            VerseScreen(verse: verse, title: "Today")
          }
        case .random:
          RandomVerseScreen()
        case .verse(let id):
          if let verse = Scripture.shared.verse(id: id) {
            VerseScreen(verse: verse, title: verse.label)
          }
        case .bookmarks:
          BookmarksScreen()
        case .listen:
          ListenScreen()
        }
      }
    }
    // Tapping the complication opens today's verse.
    .onOpenURL { url in
      if url.host == "today" { path = [.today] }
    }
  }
}

private struct TodayCard: View {
  let verse: Verse
  let language: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("TODAY · \(verse.label)")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(Color.gitaAccent)
      Text(verse.translation(language))
        .font(.footnote)
        .lineLimit(3)
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Today's verse, \(verse.reference)")
  }
}

// MARK: - Reading

/// One verse: reference, Sanskrit, transliteration and translation, read
/// with the Digital Crown. Text is shown exactly as in the dataset.
struct VerseContent: View {
  let verse: Verse
  let language: String

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(verse.reference)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(Color.gitaAccent)
        .accessibilityAddTraits(.isHeader)
      Text(verse.sanskrit.joined(separator: "\n"))
        .font(.body)
        .lineSpacing(2)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel("Sanskrit")
        .accessibilityValue(verse.transliteration.joined(separator: " "))
      Text(verse.transliteration.joined(separator: "\n"))
        .font(.footnote.italic())
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityHidden(true)
      Divider()
      Text(verse.translation(language))
        .font(.body)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct VerseScreen: View {
  @EnvironmentObject private var store: WatchStore
  let verse: Verse
  let title: String

  var body: some View {
    ScrollView {
      VerseContent(verse: verse, language: store.language)
    }
    .navigationTitle(title)
  }
}

struct RandomVerseScreen: View {
  @EnvironmentObject private var store: WatchStore
  @State private var verse: Verse? = Scripture.shared.random()

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        if let verse {
          VerseContent(verse: verse, language: store.language)
            .id("top")
          Button {
            self.verse = Scripture.shared.random(excluding: verse.id)
            proxy.scrollTo("top", anchor: .top)
          } label: {
            Label("Another Verse", systemImage: "shuffle")
          }
          .padding(.top, 8)
        }
      }
    }
    .navigationTitle(verse?.label ?? "Random")
  }
}

struct BookmarksScreen: View {
  @EnvironmentObject private var store: WatchStore

  var body: some View {
    let items = store.bookmarks
    Group {
      if items.isEmpty {
        ScrollView {
          VStack(spacing: 8) {
            Image(systemName: "bookmark")
              .font(.title2)
              .foregroundStyle(Color.gitaAccent)
            Text(store.syncedAt == nil
              ? "Open One Scroll Gita on your iPhone to bring your bookmarks here."
              : "Bookmark verses in the iPhone app to read them here.")
              .font(.footnote)
              .multilineTextAlignment(.center)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)
          .padding(.top, 12)
        }
      } else {
        List(items) { verse in
          NavigationLink(value: Route.verse(verse.id)) {
            VStack(alignment: .leading, spacing: 2) {
              Text(verse.label)
                .font(.headline)
              Text(verse.translation(store.language))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            }
          }
        }
      }
    }
    .navigationTitle("Bookmarks")
  }
}

// MARK: - Audio

/// The system Now Playing controls. They drive whatever the iPhone is
/// playing (the app's Shravan audio included) through the phone's own
/// Now Playing session; the watch has no audio engine of its own.
struct ListenScreen: View {
  var body: some View {
    NowPlayingView()
      .navigationTitle("Now Playing")
  }
}
