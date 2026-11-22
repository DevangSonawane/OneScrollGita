import Flutter
import UIKit

// Apple's own UIKit Liquid Glass controls, shown in Flutter as platform
// views on iOS 26 and later (docs/PRD_v7.md section 4e). Flutter owns all
// state and navigation: each view shows what Flutter sends and reports taps
// back. Older iOS and Android use the Flutter versions instead.
//
// - Tab bar: UITabBarController's own tab bar, with the Shravan mini player
//   as its bottom accessory.
// - Reader top bar: chapter button, summary button, EN | हि (one glass group).
// - Button: a glass (or plain) UIButton, optionally with a native menu.
// - Action sheet: UIAlertController for long-press menus.

enum NativeGlass {
  static let prefix = "com.onescrollgita.app/"

  static func register(with registry: FlutterPluginRegistry) {
    guard #available(iOS 26.0, *) else { return }
    if let r = registry.registrar(forPlugin: "NativeGlassViews") {
      let m = r.messenger()
      func add(_ name: String, _ make: @escaping NativeViewFactory.Make) {
        r.register(
          NativeViewFactory(messenger: m, viewType: prefix + name, make: make),
          withId: prefix + name,
          gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicyEager
        )
      }
      add("native_tab_bar") { NativeTabBarView(frame: $0, channel: $1, args: $2) }
      add("native_reader_bar") { NativeReaderBarView(frame: $0, channel: $1, args: $2) }
      add("native_button") { NativeButtonView(frame: $0, channel: $1, args: $2) }
      add("native_segmented") { NativeSegmentedView(frame: $0, channel: $1, args: $2) }
    }
    if let r = registry.registrar(forPlugin: "NativeActionSheet") {
      NativeActionSheet.register(with: r)
    }
  }

  static func color(_ value: Any?) -> UIColor? {
    guard let argb = (value as? NSNumber)?.intValue else { return nil }
    return UIColor(
      red: CGFloat((argb >> 16) & 0xFF) / 255,
      green: CGFloat((argb >> 8) & 0xFF) / 255,
      blue: CGFloat(argb & 0xFF) / 255,
      alpha: CGFloat((argb >> 24) & 0xFF) / 255
    )
  }

  static func image(_ name: Any?) -> UIImage? {
    guard let name = name as? String, !name.isEmpty else { return nil }
    return UIImage(systemName: name)
  }
}

final class NativeViewFactory: NSObject, FlutterPlatformViewFactory {
  typealias Make = (CGRect, FlutterMethodChannel, [String: Any]) -> FlutterPlatformView

  private let messenger: FlutterBinaryMessenger
  private let viewType: String
  private let make: Make

  init(messenger: FlutterBinaryMessenger, viewType: String, make: @escaping Make) {
    self.messenger = messenger
    self.viewType = viewType
    self.make = make
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    let channel = FlutterMethodChannel(
      name: "\(viewType)_\(viewId)",
      binaryMessenger: messenger
    )
    return make(frame, channel, args as? [String: Any] ?? [:])
  }
}

/// The root view of each platform view: tells its owner about layout and
/// window changes.
final class NativeHostView: UIView {
  var onLayout: (() -> Void)?
  var onWindow: (() -> Void)?

  override func layoutSubviews() {
    super.layoutSubviews()
    onLayout?()
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    onWindow?()
  }

  /// The view controller that owns this view (Flutter's).
  var owningController: UIViewController? {
    var r: UIResponder? = next
    while let current = r {
      if let vc = current as? UIViewController { return vc }
      r = current.next
    }
    return nil
  }
}

/// Shared plumbing: the channel, `update` calls from Flutter, light/dark,
/// and size reports back to Flutter.
class NativeChannelView: NSObject, FlutterPlatformView {
  let channel: FlutterMethodChannel
  let host = NativeHostView()
  private var reported: CGSize = .zero

  init(frame: CGRect, channel: FlutterMethodChannel, args: [String: Any]) {
    self.channel = channel
    super.init()
    host.frame = frame
    host.backgroundColor = .clear
    setUp()
    update(args)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      if call.method == "update", let a = call.arguments as? [String: Any] {
        self.update(a)
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  func view() -> UIView { host }

  /// Builds the subviews once.
  func setUp() {}

  /// Applies Flutter's state.
  func apply(_ a: [String: Any]) {}

  private func update(_ a: [String: Any]) {
    let dark = (a["dark"] as? NSNumber)?.boolValue ?? false
    host.overrideUserInterfaceStyle = dark ? .dark : .light
    if (a["measure"] as? NSNumber)?.boolValue == true { reported = .zero }
    apply(a)
    host.setNeedsLayout()
  }

  func send(_ method: String, _ arguments: Any? = nil) {
    channel.invokeMethod(method, arguments: arguments)
  }

  /// Tells Flutter the size this view needs (only when it changes).
  func report(_ size: CGSize) {
    let s = CGSize(width: ceil(size.width), height: ceil(size.height))
    guard s.width > 0, s.height > 0, s != reported else { return }
    reported = s
    send("size", ["width": Double(s.width), "height": Double(s.height)])
  }
}

// MARK: - Tab bar

/// An empty, see-through tab: Flutter draws the screens.
@available(iOS 26.0, *)
private final class NativeTabContent: UIViewController {
  var onInsets: (() -> Void)?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    view.isUserInteractionEnabled = false
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    onInsets?()
  }
}

@available(iOS 26.0, *)
final class NativeTabBarView: NativeChannelView, UITabBarControllerDelegate {
  private let controller = UITabBarController()
  private let haptic = UISelectionFeedbackGenerator()
  private var itemsKey: [String] = []
  private var miniPlayer: NativeMiniPlayerView?

  override func setUp() {
    controller.delegate = self
    controller.view.backgroundColor = .clear
    controller.view.frame = host.bounds
    controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    host.addSubview(controller.view)
    host.onLayout = { [weak self] in self?.measure() }
    host.onWindow = { [weak self] in self?.attach() }
  }

  /// Joins Flutter's view controller so the bar gets safe areas and trait
  /// changes like any system tab bar.
  private func attach() {
    guard controller.parent == nil, let parent = host.owningController else { return }
    parent.addChild(controller)
    controller.didMove(toParent: parent)
  }

  /// The height the bar (and the mini player above it) needs.
  private func measure() {
    var top = controller.tabBar.frame.minY
    if let mini = miniPlayer, mini.window != nil {
      // The accessory's glass capsule sits a little outside its content.
      top = min(top, mini.convert(mini.bounds, to: host).minY - 8)
    }
    let covered = host.bounds.height - top
    let inset = controller.selectedViewController?.view.safeAreaInsets.bottom ?? 0
    report(CGSize(width: host.bounds.width, height: max(covered, inset)))
  }

  private static func key(_ list: [[String: Any]]) -> [String] {
    list.map { d in
      [d["label"], d["symbol"], d["selectedSymbol"]]
        .map { ($0 as? String) ?? "" }
        .joined(separator: "|")
    }
  }

  override func apply(_ a: [String: Any]) {
    controller.overrideUserInterfaceStyle = host.overrideUserInterfaceStyle
    let tint = NativeGlass.color(a["tint"])
    controller.tabBar.tintColor = tint

    let list = (a["items"] as? [[String: Any]]) ?? []
    if Self.key(list) != itemsKey {
      itemsKey = Self.key(list)
      let tabs: [UIViewController] = list.enumerated().map { i, d in
        let vc = NativeTabContent()
        vc.onInsets = { [weak self] in self?.host.setNeedsLayout() }
        let item = UITabBarItem(
          title: d["label"] as? String,
          image: NativeGlass.image(d["symbol"]),
          tag: i
        )
        item.selectedImage = NativeGlass.image(d["selectedSymbol"]) ?? item.image
        vc.tabBarItem = item
        return vc
      }
      controller.setViewControllers(tabs, animated: false)
    }
    let selected = (a["selected"] as? NSNumber)?.intValue ?? 0
    if selected >= 0, selected < list.count, controller.selectedIndex != selected {
      controller.selectedIndex = selected
    }

    // The Shravan mini player docks into the bar, as in Apple Music.
    if let m = a["accessory"] as? [String: Any] {
      let mini: NativeMiniPlayerView
      if let existing = miniPlayer {
        mini = existing
      } else {
        mini = NativeMiniPlayerView()
        mini.onAction = { [weak self] id in self?.send("accessory", id) }
        miniPlayer = mini
        controller.setBottomAccessory(UITabAccessory(contentView: mini), animated: true)
      }
      mini.update(m, tint: tint)
    } else if miniPlayer != nil {
      miniPlayer = nil
      controller.setBottomAccessory(nil, animated: true)
    }
  }

  func tabBarController(
    _ tabBarController: UITabBarController,
    shouldSelect viewController: UIViewController
  ) -> Bool {
    if let i = tabBarController.viewControllers?.firstIndex(of: viewController) {
      // A light tick when switching tabs, as the Flutter pill did.
      if i != tabBarController.selectedIndex { haptic.selectionChanged() }
      send("select", i)
    }
    return true
  }
}

/// The mini player's content inside the tab bar accessory.
final class NativeMiniPlayerView: UIView {
  var onAction: ((String) -> Void)?

  private let numeral = UILabel()
  private let title = UILabel()
  private let subtitle = UILabel()
  private let play = UIButton(type: .system)
  private let close = UIButton(type: .system)

  override init(frame: CGRect) {
    super.init(frame: frame)
    numeral.font = .systemFont(ofSize: 13, weight: .semibold)
    numeral.textAlignment = .center
    numeral.layer.cornerRadius = 15
    numeral.layer.masksToBounds = true
    numeral.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate(Self.soft([
      numeral.widthAnchor.constraint(equalToConstant: 30),
      numeral.heightAnchor.constraint(equalToConstant: 30),
    ]))
    numeral.isAccessibilityElement = false

    title.font = .preferredFont(forTextStyle: .subheadline)
    title.adjustsFontForContentSizeCategory = true
    title.maximumContentSizeCategory = .accessibilityMedium
    subtitle.font = .preferredFont(forTextStyle: .caption1)
    subtitle.adjustsFontForContentSizeCategory = true
    subtitle.maximumContentSizeCategory = .accessibilityMedium
    subtitle.textColor = .secondaryLabel
    let text = UIStackView(arrangedSubviews: [title, subtitle])
    text.axis = .vertical
    text.spacing = 0
    text.isAccessibilityElement = true
    text.accessibilityTraits = .button

    play.addAction(UIAction { [weak self] _ in self?.onAction?("toggle") }, for: .primaryActionTriggered)
    close.setImage(UIImage(systemName: "xmark"), for: .normal)
    close.tintColor = .secondaryLabel
    close.accessibilityLabel = "Close player"
    close.addAction(UIAction { [weak self] _ in self?.onAction?("close") }, for: .primaryActionTriggered)
    for b in [play, close] {
      b.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate(Self.soft([
        b.widthAnchor.constraint(equalToConstant: 44),
        b.heightAnchor.constraint(equalToConstant: 44),
      ]))
    }

    let row = UIStackView(arrangedSubviews: [numeral, text, play, close])
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 10
    row.translatesAutoresizingMaskIntoConstraints = false
    addSubview(row)
    NSLayoutConstraint.activate(Self.soft([
      row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
      row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
      row.topAnchor.constraint(equalTo: topAnchor),
      row.bottomAnchor.constraint(equalTo: bottomAnchor),
    ]))

    let tap = UITapGestureRecognizer(target: self, action: #selector(open))
    text.addGestureRecognizer(tap)
    text.isUserInteractionEnabled = true
    numeral.isUserInteractionEnabled = false
    text.accessibilityHint = "Opens the player"
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

  /// Just below required, so the brief zero-size moment while UIKit sets up
  /// the accessory never breaks a constraint.
  private static func soft(_ list: [NSLayoutConstraint]) -> [NSLayoutConstraint] {
    list.forEach { $0.priority = .init(999) }
    return list
  }

  @objc private func open() { onAction?("open") }

  override func accessibilityActivate() -> Bool {
    onAction?("open")
    return true
  }

  func update(_ m: [String: Any], tint: UIColor?) {
    numeral.text = m["numeral"] as? String
    numeral.textColor = tint
    numeral.backgroundColor = tint?.withAlphaComponent(0.15)
    title.text = m["title"] as? String
    subtitle.text = m["subtitle"] as? String
    title.superview?.accessibilityLabel = "Now playing: \(title.text ?? "")"
    let playing = (m["playing"] as? NSNumber)?.boolValue ?? false
    play.setImage(UIImage(systemName: playing ? "pause.fill" : "play.fill"), for: .normal)
    play.tintColor = .label
    play.accessibilityLabel = playing ? "Pause" : "Play"
  }
}

// MARK: - Reader top bar

/// Chapter button, summary button and EN | हि, in one glass group so they
/// share one backdrop (one surface in the glass budget).
@available(iOS 26.0, *)
final class NativeReaderBarView: NativeChannelView {
  private let group = UIVisualEffectView(effect: UIGlassContainerEffect())
  private let chapter = UIButton(configuration: .glass())
  private let info = UIButton(configuration: .glass())
  private let languageGlass = UIVisualEffectView(effect: UIGlassEffect())
  private let language = UISegmentedControl(items: ["EN", "हि"])

  override func setUp() {
    group.frame = host.bounds
    group.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    host.addSubview(group)
    group.contentView.addSubview(chapter)
    group.contentView.addSubview(info)
    group.contentView.addSubview(languageGlass)
    languageGlass.contentView.addSubview(language)
    languageGlass.cornerConfiguration = .capsule()

    chapter.addAction(UIAction { [weak self] _ in self?.send("tap", "chapter") }, for: .primaryActionTriggered)
    info.addAction(UIAction { [weak self] _ in self?.send("tap", "info") }, for: .primaryActionTriggered)
    language.addAction(UIAction { [weak self] _ in
      guard let self = self else { return }
      self.send("language", self.language.selectedSegmentIndex == 1 ? "hi" : "en")
    }, for: .valueChanged)
    language.accessibilityLabel = "Translation language"
    host.onLayout = { [weak self] in self?.layout() }
  }

  private func layout() {
    let b = host.bounds
    let h = b.height
    let fit = language.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: h))
    let segW = max(fit.width + 8, 92)
    languageGlass.frame = CGRect(x: b.width - segW, y: 0, width: segW, height: h)
    language.frame = languageGlass.bounds.insetBy(dx: 4, dy: 4)
    info.frame = CGRect(x: b.width - segW - 8 - h, y: 0, width: h, height: h)
    chapter.frame = CGRect(x: 0, y: 0, width: max(0, b.width - segW - h - 16), height: h)
  }

  override func apply(_ a: [String: Any]) {
    let tint = NativeGlass.color(a["tint"])

    var c = UIButton.Configuration.glass()
    c.title = a["chapterTitle"] as? String
    c.titleLineBreakMode = .byTruncatingTail
    c.image = UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(scale: .small))
    c.imagePlacement = .trailing
    c.imagePadding = 4
    c.baseForegroundColor = .label
    c.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { t in
      var t = t
      t.font = UIFont.preferredFont(forTextStyle: .subheadline)
      return t
    }
    chapter.configuration = c
    chapter.accessibilityLabel = a["chapterLabel"] as? String

    var i = UIButton.Configuration.glass()
    i.image = UIImage(systemName: "info.circle")
    i.baseForegroundColor = .label
    info.configuration = i
    info.accessibilityLabel = a["infoLabel"] as? String

    language.selectedSegmentIndex = (a["language"] as? String) == "hi" ? 1 : 0
    language.selectedSegmentTintColor = tint?.withAlphaComponent(0.25)
  }
}

// MARK: - Button

/// A UIButton: glass, tinted glass or plain, with an optional native menu.
@available(iOS 26.0, *)
final class NativeButtonView: NativeChannelView {
  private let button = UIButton(type: .system)

  override func setUp() {
    button.frame = host.bounds
    button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    host.addSubview(button)
    button.addAction(UIAction { [weak self] _ in
      guard let self = self, self.button.menu == nil else { return }
      self.send("tap")
    }, for: .primaryActionTriggered)
    host.onLayout = { [weak self] in
      guard let self = self else { return }
      let fit = self.button.sizeThatFits(
        CGSize(width: CGFloat.greatestFiniteMagnitude, height: self.host.bounds.height)
      )
      self.report(CGSize(width: fit.width, height: self.host.bounds.height))
    }
  }

  override func apply(_ a: [String: Any]) {
    let tint = NativeGlass.color(a["tint"])
    var c: UIButton.Configuration
    switch a["style"] as? String {
    case "prominentGlass": c = .prominentGlass()
    case "plain": c = .plain()
    default: c = .glass()
    }
    c.title = a["title"] as? String
    c.titleLineBreakMode = .byTruncatingTail
    if let img = NativeGlass.image(a["symbol"]) {
      c.image = img
      c.imagePlacement = (a["trailing"] as? NSNumber)?.boolValue == true ? .trailing : .leading
      c.imagePadding = 6
      c.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(textStyle: .subheadline)
    }
    c.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { t in
      var t = t
      t.font = UIFont.preferredFont(forTextStyle: .headline)
      return t
    }
    if let fg = NativeGlass.color(a["foreground"]) { c.baseForegroundColor = fg }
    button.configuration = c
    button.tintColor = tint
    button.accessibilityLabel = a["label"] as? String

    if let items = a["menu"] as? [[String: Any]], !items.isEmpty {
      button.menu = UIMenu(children: items.map { d in
        let id = (d["id"] as? String) ?? ""
        return UIAction(
          title: (d["title"] as? String) ?? "",
          image: NativeGlass.image(d["symbol"]),
          attributes: (d["destructive"] as? NSNumber)?.boolValue == true ? .destructive : []
        ) { [weak self] _ in self?.send("menu", id) }
      })
      button.showsMenuAsPrimaryAction = true
    } else {
      button.menu = nil
      button.showsMenuAsPrimaryAction = false
    }
  }
}

// MARK: - Segmented control

/// Apple's UISegmentedControl (EN | हि, theme). Compact ones sit in their
/// own glass capsule; full-width ones (settings) are the plain system control.
@available(iOS 26.0, *)
final class NativeSegmentedView: NativeChannelView {
  private let glass = UIVisualEffectView(effect: UIGlassEffect())
  private let control = UISegmentedControl()
  private var labels: [String] = []
  private var compact = false
  private let haptic = UISelectionFeedbackGenerator()

  override func setUp() {
    glass.cornerConfiguration = .capsule()
    host.addSubview(glass)
    host.addSubview(control)
    control.addAction(UIAction { [weak self] _ in
      guard let self = self else { return }
      self.haptic.selectionChanged()
      self.send("select", self.control.selectedSegmentIndex)
    }, for: .valueChanged)
    host.onLayout = { [weak self] in self?.layout() }
  }

  private func layout() {
    let b = host.bounds
    let fit = control.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: 0))
    if compact {
      glass.isHidden = false
      glass.frame = b
      control.frame = b.insetBy(dx: 4, dy: 4)
      report(CGSize(width: fit.width + 8, height: max(fit.height + 8, 44)))
    } else {
      glass.isHidden = true
      control.frame = CGRect(x: 0, y: (b.height - fit.height) / 2, width: b.width, height: fit.height)
      report(CGSize(width: b.width, height: max(fit.height, 44)))
    }
  }

  override func apply(_ a: [String: Any]) {
    compact = (a["compact"] as? NSNumber)?.boolValue ?? false
    let list = (a["labels"] as? [String]) ?? []
    if list != labels {
      labels = list
      control.removeAllSegments()
      for (i, title) in list.enumerated() {
        control.insertSegment(withTitle: title, at: i, animated: false)
        if compact { control.setWidth(44, forSegmentAt: i) }
      }
    }
    let selected = (a["selected"] as? NSNumber)?.intValue ?? 0
    if control.selectedSegmentIndex != selected { control.selectedSegmentIndex = selected }
    if compact {
      control.selectedSegmentTintColor = NativeGlass.color(a["tint"])?.withAlphaComponent(0.25)
    }
    control.accessibilityLabel = a["label"] as? String
  }
}

// MARK: - Action sheet

/// Long-press menus as the system action sheet.
final class NativeActionSheet: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: NativeGlass.prefix + "native_actions",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(NativeActionSheet(), channel: channel)
  }

  private static func topController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "show",
          let a = call.arguments as? [String: Any],
          let top = Self.topController()
    else {
      result(FlutterMethodNotImplemented)
      return
    }
    var done = false
    let finish: (Any?) -> Void = { value in
      guard !done else { return }
      done = true
      result(value)
    }
    let sheet = UIAlertController(
      title: a["title"] as? String,
      message: a["message"] as? String,
      preferredStyle: .actionSheet
    )
    for d in (a["actions"] as? [[String: Any]]) ?? [] {
      let id = (d["id"] as? String) ?? ""
      let destructive = (d["destructive"] as? NSNumber)?.boolValue == true
      sheet.addAction(UIAlertAction(
        title: d["title"] as? String,
        style: destructive ? .destructive : .default
      ) { _ in finish(id) })
    }
    sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in finish(nil) })
    if let p = sheet.popoverPresentationController {
      p.sourceView = top.view
      if let r = a["rect"] as? [String: Any] {
        func v(_ k: String) -> CGFloat { CGFloat((r[k] as? NSNumber)?.doubleValue ?? 0) }
        p.sourceRect = CGRect(x: v("x"), y: v("y"), width: v("width"), height: v("height"))
      } else {
        p.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.maxY, width: 0, height: 0)
      }
    }
    top.present(sheet, animated: true)
  }
}
