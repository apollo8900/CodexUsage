import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(
        withLength: NSStatusItem.variableLength
    )

    private let codexReader = UsageReader()
    private let antigravityReader = AntigravityUsageReader()

    private var timer: Timer?

    private var lastCodexSnapshot: UsageSnapshot = .empty
    private var lastAntigravitySnapshot: AntigravitySnapshot = .empty

    // ChatGPT (CG) items
    private lazy var cg5HourItem = NSMenuItem(
        title: "5h: —",
        action: nil,
        keyEquivalent: ""
    )

    private lazy var cgWeeklyItem = NSMenuItem(
        title: "7d: —",
        action: nil,
        keyEquivalent: ""
    )

    private lazy var cgUpdatedItem = NSMenuItem(
        title: "Last Updated: —",
        action: nil,
        keyEquivalent: ""
    )

    // Claude (CL) items
    private lazy var claude5HourItem = NSMenuItem(
        title: "5h: —",
        action: nil,
        keyEquivalent: ""
    )

    private lazy var claudeWeeklyItem = NSMenuItem(
        title: "7d: —",
        action: nil,
        keyEquivalent: ""
    )

    private lazy var claudeUpdatedItem = NSMenuItem(
        title: "Last Updated: —",
        action: nil,
        keyEquivalent: ""
    )

    // Gemini (GM) items
    private lazy var gemini5HourItem = NSMenuItem(
        title: "5h: —",
        action: nil,
        keyEquivalent: ""
    )

    private lazy var geminiWeeklyItem = NSMenuItem(
        title: "7d: —",
        action: nil,
        keyEquivalent: ""
    )

    private lazy var geminiUpdatedItem = NSMenuItem(
        title: "Last Updated: —",
        action: nil,
        keyEquivalent: ""
    )

    // Display mode items
    private var displayModeMenuItems: [DisplayMode: NSMenuItem] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        configureStatusItem()
        configureMenu()

        refreshNow()

        timer = Timer.scheduledTimer(
            timeInterval: 30,
            target: self,
            selector: #selector(refreshNow),
            userInfo: nil,
            repeats: true
        )

        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.title = "CG 5h:— / 7d:—  |  CL 5h:— / 7d:—  |  GM 5h:— / 7d:—"
        button.toolTip = "AI remaining usage"
    }

    private func configureMenu() {
        let menu = NSMenu()

        // 1. ChatGPT (CG) Section
        let cgHeader = NSMenuItem(
            title: "ChatGPT (CG) Remaining",
            action: nil,
            keyEquivalent: ""
        )
        cgHeader.isEnabled = false

        cg5HourItem.isEnabled = false
        cgWeeklyItem.isEnabled = false
        cgUpdatedItem.isEnabled = false

        menu.addItem(cgHeader)
        menu.addItem(cg5HourItem)
        menu.addItem(cgWeeklyItem)
        menu.addItem(cgUpdatedItem)

        menu.addItem(.separator())

        // 2. Claude (CL) Section
        let claudeHeader = NSMenuItem(
            title: "Claude (CL) Remaining",
            action: nil,
            keyEquivalent: ""
        )
        claudeHeader.isEnabled = false

        claude5HourItem.isEnabled = false
        claudeWeeklyItem.isEnabled = false
        claudeUpdatedItem.isEnabled = false

        menu.addItem(claudeHeader)
        menu.addItem(claude5HourItem)
        menu.addItem(claudeWeeklyItem)
        menu.addItem(claudeUpdatedItem)

        menu.addItem(.separator())

        // 3. Gemini (GM) Section
        let geminiHeader = NSMenuItem(
            title: "Gemini (GM) Remaining",
            action: nil,
            keyEquivalent: ""
        )
        geminiHeader.isEnabled = false

        gemini5HourItem.isEnabled = false
        geminiWeeklyItem.isEnabled = false
        geminiUpdatedItem.isEnabled = false

        menu.addItem(geminiHeader)
        menu.addItem(gemini5HourItem)
        menu.addItem(geminiWeeklyItem)
        menu.addItem(geminiUpdatedItem)

        menu.addItem(.separator())

        // 4. Display Mode Submenu
        let displayModeParent = NSMenuItem(
            title: "Menu Bar Display",
            action: nil,
            keyEquivalent: ""
        )
        let displaySubmenu = NSMenu()

        for mode in DisplayMode.allCases {
            let item = NSMenuItem(
                title: mode.title,
                action: #selector(selectDisplayMode(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = mode.rawValue
            displayModeMenuItems[mode] = item
            displaySubmenu.addItem(item)
        }

        updateDisplayModeChecks()
        displayModeParent.submenu = displaySubmenu
        menu.addItem(displayModeParent)

        menu.addItem(.separator())

        // 5. Actions
        let refreshItem = NSMenuItem(
            title: "Refresh Now",
            action: #selector(refreshNow),
            keyEquivalent: "r"
        )
        refreshItem.target = self
        menu.addItem(refreshItem)

        let codexUsagePageItem = NSMenuItem(
            title: "Open Codex Usage Page",
            action: #selector(openCodexUsagePage),
            keyEquivalent: "u"
        )
        codexUsagePageItem.target = self
        menu.addItem(codexUsagePageItem)

        let antigravityPageItem = NSMenuItem(
            title: "Open Antigravity",
            action: #selector(openAntigravity),
            keyEquivalent: "a"
        )
        antigravityPageItem.target = self
        menu.addItem(antigravityPageItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func refreshNow() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let codexSnapshot = self.codexReader.readLatest()
            let antigravitySnapshot = self.antigravityReader.readLatest()

            DispatchQueue.main.async {
                self.lastCodexSnapshot = codexSnapshot
                self.lastAntigravitySnapshot = antigravitySnapshot
                self.render()
            }
        }
    }

    private func render() {
        let cg5Text = lastCodexSnapshot.fiveHour
            .map { "\($0.remainingPercent)%" } ?? "—"
        let cg7Text = lastCodexSnapshot.weekly
            .map { "\($0.remainingPercent)%" } ?? "—"

        let cl5Text = lastAntigravitySnapshot.thirdParty5h
            .map { "\($0.remainingPercent)%" } ?? "—"
        let cl7Text = lastAntigravitySnapshot.thirdPartyWeekly
            .map { "\($0.remainingPercent)%" } ?? "—"

        let gm5Text = lastAntigravitySnapshot.gemini5h
            .map { "\($0.remainingPercent)%" } ?? "—"
        let gm7Text = lastAntigravitySnapshot.geminiWeekly
            .map { "\($0.remainingPercent)%" } ?? "—"

        // Menu Bar Title
        switch DisplayMode.current {
        case .all:
            statusItem.button?.title = "CG 5h:\(cg5Text)/7d:\(cg7Text)  |  CL 5h:\(cl5Text)/7d:\(cl7Text)  |  GM 5h:\(gm5Text)/7d:\(gm7Text)"
        case .cgOnly:
            statusItem.button?.title = "CG 5h:\(cg5Text) / 7d:\(cg7Text)"
        case .clOnly:
            statusItem.button?.title = "CL 5h:\(cl5Text) / 7d:\(cl7Text)"
        case .gmOnly:
            statusItem.button?.title = "GM 5h:\(gm5Text) / 7d:\(gm7Text)"
        }

        // ChatGPT (CG) details
        cg5HourItem.title = detailTitle(
            label: "5h",
            window: lastCodexSnapshot.fiveHour
        )
        cgWeeklyItem.title = detailTitle(
            label: "7d",
            window: lastCodexSnapshot.weekly
        )
        if let recordedAt = lastCodexSnapshot.recordedAt {
            cgUpdatedItem.title = "Last Updated: \(Self.localDateFormatter.string(from: recordedAt))"
        } else {
            cgUpdatedItem.title = "Last Updated: (Codex not detected)"
        }

        // Claude (CL) details
        claude5HourItem.title = detailTitle(
            label: "5h",
            window: lastAntigravitySnapshot.thirdParty5h
        )
        claudeWeeklyItem.title = detailTitle(
            label: "7d",
            window: lastAntigravitySnapshot.thirdPartyWeekly
        )
        if let recordedAt = lastAntigravitySnapshot.recordedAt {
            claudeUpdatedItem.title = "Last Updated: \(Self.localDateFormatter.string(from: recordedAt))"
        } else {
            claudeUpdatedItem.title = "Last Updated: (Antigravity not detected)"
        }

        // Gemini (GM) details
        gemini5HourItem.title = detailTitle(
            label: "5h",
            window: lastAntigravitySnapshot.gemini5h
        )
        geminiWeeklyItem.title = detailTitle(
            label: "7d",
            window: lastAntigravitySnapshot.geminiWeekly
        )
        if let recordedAt = lastAntigravitySnapshot.recordedAt {
            geminiUpdatedItem.title = "Last Updated: \(Self.localDateFormatter.string(from: recordedAt))"
        } else {
            geminiUpdatedItem.title = "Last Updated: (Antigravity not detected)"
        }

        // Tooltip
        statusItem.button?.toolTip = """
        ChatGPT (CG):
          5h: \(cg5Text)
          7d: \(cg7Text)

        Claude (CL):
          5h: \(cl5Text)
          7d: \(cl7Text)

        Gemini (GM):
          5h: \(gm5Text)
          7d: \(gm7Text)
        """
    }

    private func detailTitle(
        label: String,
        window: UsageWindow?
    ) -> String {
        guard let window else {
            return "\(label): —"
        }

        var title = "\(label): \(window.remainingPercent)% remaining"

        if let resetsAt = window.activeResetDate {
            title += " · resets \(Self.localDateFormatter.string(from: resetsAt))"
        }

        return title
    }

    @objc private func selectDisplayMode(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let mode = DisplayMode(rawValue: raw) else {
            return
        }

        DisplayMode.current = mode
        updateDisplayModeChecks()
        render()
    }

    private func updateDisplayModeChecks() {
        let current = DisplayMode.current
        for (mode, item) in displayModeMenuItems {
            item.state = (mode == current) ? .on : .off
        }
    }

    @objc private func openCodexUsagePage() {
        guard let url = URL(string: "https://chatgpt.com/codex/settings/usage") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    @objc private func openAntigravity() {
        if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.antigravity.ide") ??
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.antigravity") {
            NSWorkspace.shared.openApplication(at: appUrl, configuration: NSWorkspace.OpenConfiguration())
        } else if let url = URL(string: "https://antigravity.google") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private static let localDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
