import AppKit

final class Preferences {
    private enum Key {
        static let collapsed = "collapsed.v1"
        static let spacerWidth = "spacerWidth.v1"
        static let alwaysHiddenEnabled = "alwaysHiddenEnabled.v1"
        static let autoCollapseSeconds = "autoCollapseSeconds.v1"
    }

    var collapsed: Bool {
        get { UserDefaults.standard.object(forKey: Key.collapsed) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: Key.collapsed) }
    }

    var spacerWidth: CGFloat {
        get {
            let value = UserDefaults.standard.double(forKey: Key.spacerWidth)
            return value > 0 ? CGFloat(value) : 460
        }
        set { UserDefaults.standard.set(Double(newValue), forKey: Key.spacerWidth) }
    }

    var alwaysHiddenEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Key.alwaysHiddenEnabled) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: Key.alwaysHiddenEnabled) }
    }

    var autoCollapseSeconds: TimeInterval {
        get {
            let value = UserDefaults.standard.double(forKey: Key.autoCollapseSeconds)
            return value > 0 ? value : 8
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.autoCollapseSeconds) }
    }
}

final class BarShelfController: NSObject, NSApplicationDelegate {
    private let preferences = Preferences()
    private var toggleItem: NSStatusItem!
    private var separatorItem: NSStatusItem!
    private var shelfSpacerItem: NSStatusItem!
    private var alwaysHiddenSeparatorItem: NSStatusItem!
    private var statusMenu: NSMenu!
    private var window: NSWindow?
    private var collapseTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        createStatusItems()
        applyState(animated: false)
    }

    private func createStatusItems() {
        alwaysHiddenSeparatorItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        configureButton(alwaysHiddenSeparatorItem.button, title: "▥", help: "BarShelf always-hidden separator. Hold Command and drag menu bar icons left of this marker.")

        shelfSpacerItem = NSStatusBar.system.statusItem(withLength: 1)
        configureButton(shelfSpacerItem.button, title: "", help: "BarShelf hidden shelf spacer")
        shelfSpacerItem.button?.isEnabled = false

        separatorItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        configureButton(separatorItem.button, title: "│", help: "BarShelf separator. Hold Command and drag menu bar icons left of this marker to hide them when collapsed.")

        toggleItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        configureButton(toggleItem.button, title: "‹", help: "Toggle BarShelf")
        toggleItem.button?.target = self
        toggleItem.button?.action = #selector(toggleShelf)
        toggleItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        statusMenu = NSMenu()
        statusMenu.addItem(NSMenuItem(title: "Expand / Collapse", action: #selector(toggleShelfFromMenu), keyEquivalent: ""))
        statusMenu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        statusMenu.addItem(NSMenuItem(title: "How to Use", action: #selector(showHelp), keyEquivalent: "?"))
        statusMenu.addItem(.separator())
        statusMenu.addItem(NSMenuItem(title: "Quit BarShelf", action: #selector(quit), keyEquivalent: "q"))
        statusMenu.items.forEach { $0.target = self }
    }

    private func configureButton(_ button: NSStatusBarButton?, title: String, help: String) {
        button?.title = title
        button?.toolTip = help
        button?.font = .systemFont(ofSize: 15, weight: .medium)
    }

    @objc private func toggleShelf() {
        if NSApp.currentEvent?.type == .rightMouseUp, let button = toggleItem.button {
            statusMenu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
            return
        }
        preferences.collapsed.toggle()
        applyState(animated: true)
    }

    @objc private func toggleShelfFromMenu() {
        preferences.collapsed.toggle()
        applyState(animated: true)
    }

    private func applyState(animated: Bool) {
        let collapsed = preferences.collapsed
        let width = collapsed ? preferences.spacerWidth : 1
        shelfSpacerItem.length = width

        toggleItem.button?.title = collapsed ? "‹" : "›"
        toggleItem.button?.toolTip = collapsed ? "Expand BarShelf" : "Collapse BarShelf"
        alwaysHiddenSeparatorItem.isVisible = preferences.alwaysHiddenEnabled

        collapseTimer?.invalidate()
        if !collapsed {
            collapseTimer = Timer.scheduledTimer(withTimeInterval: preferences.autoCollapseSeconds, repeats: false) { [weak self] _ in
                self?.preferences.collapsed = true
                self?.applyState(animated: true)
            }
        }
    }

    @objc private func openSettings() {
        if window == nil { buildSettingsWindow() }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildSettingsWindow() {
        let content = NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 360))

        let title = NSTextField(labelWithString: "BarShelf")
        title.font = .systemFont(ofSize: 26, weight: .semibold)
        title.translatesAutoresizingMaskIntoConstraints = false

        let instructions = NSTextField(wrappingLabelWithString: "Hold Command (⌘) and drag menu bar icons around the BarShelf separator. Put icons you want hidden to the left of │. Click BarShelf to expand/collapse that shelf.")
        instructions.textColor = .secondaryLabelColor
        instructions.translatesAutoresizingMaskIntoConstraints = false

        let widthLabel = NSTextField(labelWithString: "Hidden shelf width")
        widthLabel.translatesAutoresizingMaskIntoConstraints = false

        let widthSlider = NSSlider(value: Double(preferences.spacerWidth), minValue: 180, maxValue: 900, target: self, action: #selector(widthChanged(_:)))
        widthSlider.translatesAutoresizingMaskIntoConstraints = false

        let autoCollapseLabel = NSTextField(labelWithString: "Auto-collapse delay")
        autoCollapseLabel.translatesAutoresizingMaskIntoConstraints = false

        let autoCollapseSlider = NSSlider(value: preferences.autoCollapseSeconds, minValue: 2, maxValue: 30, target: self, action: #selector(autoCollapseChanged(_:)))
        autoCollapseSlider.translatesAutoresizingMaskIntoConstraints = false

        let alwaysHidden = NSButton(checkboxWithTitle: "Show always-hidden separator", target: self, action: #selector(alwaysHiddenChanged(_:)))
        alwaysHidden.state = preferences.alwaysHiddenEnabled ? .on : .off
        alwaysHidden.translatesAutoresizingMaskIntoConstraints = false

        let helpButton = NSButton(title: "How to use", target: self, action: #selector(showHelp))
        helpButton.translatesAutoresizingMaskIntoConstraints = false

        let quitButton = NSButton(title: "Quit", target: self, action: #selector(quit))
        quitButton.translatesAutoresizingMaskIntoConstraints = false

        [title, instructions, widthLabel, widthSlider, autoCollapseLabel, autoCollapseSlider, alwaysHidden, helpButton, quitButton].forEach(content.addSubview)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: content.topAnchor, constant: 24),
            title.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            title.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),

            instructions.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
            instructions.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            instructions.trailingAnchor.constraint(equalTo: title.trailingAnchor),

            widthLabel.topAnchor.constraint(equalTo: instructions.bottomAnchor, constant: 28),
            widthLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            widthSlider.centerYAnchor.constraint(equalTo: widthLabel.centerYAnchor),
            widthSlider.leadingAnchor.constraint(equalTo: widthLabel.trailingAnchor, constant: 18),
            widthSlider.trailingAnchor.constraint(equalTo: title.trailingAnchor),

            autoCollapseLabel.topAnchor.constraint(equalTo: widthLabel.bottomAnchor, constant: 26),
            autoCollapseLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            autoCollapseSlider.centerYAnchor.constraint(equalTo: autoCollapseLabel.centerYAnchor),
            autoCollapseSlider.leadingAnchor.constraint(equalTo: widthSlider.leadingAnchor),
            autoCollapseSlider.trailingAnchor.constraint(equalTo: title.trailingAnchor),

            alwaysHidden.topAnchor.constraint(equalTo: autoCollapseLabel.bottomAnchor, constant: 28),
            alwaysHidden.leadingAnchor.constraint(equalTo: title.leadingAnchor),

            helpButton.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            helpButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24),
            quitButton.leadingAnchor.constraint(equalTo: helpButton.trailingAnchor, constant: 10),
            quitButton.centerYAnchor.constraint(equalTo: helpButton.centerYAnchor)
        ])

        window = NSWindow(contentRect: content.frame, styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window?.title = "BarShelf Settings"
        window?.contentView = content
        window?.center()
    }

    @objc private func widthChanged(_ sender: NSSlider) {
        preferences.spacerWidth = CGFloat(sender.doubleValue)
        applyState(animated: false)
    }

    @objc private func autoCollapseChanged(_ sender: NSSlider) {
        preferences.autoCollapseSeconds = sender.doubleValue
        applyState(animated: false)
    }

    @objc private func alwaysHiddenChanged(_ sender: NSButton) {
        preferences.alwaysHiddenEnabled = sender.state == .on
        applyState(animated: false)
    }

    @objc private func showHelp() {
        let alert = NSAlert()
        alert.messageText = "How BarShelf works"
        alert.informativeText = "1. Hold Command (⌘).\n2. Drag menu bar icons you want hidden to the left of BarShelf's │ separator.\n3. Click BarShelf's ‹ / › item to collapse or expand the shelf.\n\nmacOS does not expose a public API for directly hiding arbitrary third-party menu bar items, so this MVP uses the proven separator/spacer technique instead of private APIs."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = BarShelfController()
app.delegate = delegate
app.run()
