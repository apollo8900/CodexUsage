import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(
        withLength: NSStatusItem.variableLength
    )

    private let usageReader = UsageReader()

    private var timer: Timer?

    private lazy var fiveHourItem = NSMenuItem(
        title: "5h: —",
        action: nil,
        keyEquivalent: ""
    )

    private lazy var weeklyItem = NSMenuItem(
        title: "7d: —",
        action: nil,
        keyEquivalent: ""
    )

    private lazy var updatedItem = NSMenuItem(
        title: "Last Updated: —",
        action: nil,
        keyEquivalent: ""
    )

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

        button.title = "Codex 5h:— / 7d:—"
        button.toolTip = "Codex remaining usage"
    }

    private func configureMenu() {
        let menu = NSMenu()

        let header = NSMenuItem(
            title: "Codex Remaining Usage",
            action: nil,
            keyEquivalent: ""
        )

        header.isEnabled = false

        fiveHourItem.isEnabled = false
        weeklyItem.isEnabled = false
        updatedItem.isEnabled = false

        menu.addItem(header)
        menu.addItem(.separator())
        menu.addItem(fiveHourItem)
        menu.addItem(weeklyItem)
        menu.addItem(updatedItem)
        menu.addItem(.separator())

        let refreshItem = NSMenuItem(
            title: "Refresh Now",
            action: #selector(refreshNow),
            keyEquivalent: "r"
        )

        refreshItem.target = self
        menu.addItem(refreshItem)

        let usagePageItem = NSMenuItem(
            title: "Open Codex Usage Page",
            action: #selector(openUsagePage),
            keyEquivalent: "u"
        )

        usagePageItem.target = self
        menu.addItem(usagePageItem)

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
        let snapshot = usageReader.readLatest()

        DispatchQueue.main.async { [weak self] in
            self?.render(snapshot)
        }
    }

    private func render(_ snapshot: UsageSnapshot) {
        let fiveHourText = snapshot.fiveHour
            .map { "\($0.remainingPercent)%" } ?? "—"

        let weeklyText = snapshot.weekly
            .map { "\($0.remainingPercent)%" } ?? "—"

        statusItem.button?.title =
            "Codex 5h:\(fiveHourText) / 7d:\(weeklyText)"

        fiveHourItem.title = detailTitle(
            label: "5h",
            window: snapshot.fiveHour
        )

        weeklyItem.title = detailTitle(
            label: "7d",
            window: snapshot.weekly
        )

        if let recordedAt = snapshot.recordedAt {
            updatedItem.title =
                "Last Updated: \(Self.localDateFormatter.string(from: recordedAt))"
        } else {
            updatedItem.title = "Last Updated: —"
        }

        statusItem.button?.toolTip = """
        Codex remaining usage
        5h: \(fiveHourText)
        7d: \(weeklyText)
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

        if let resetsAt = window.resetsAt {
            title +=
                " · resets \(Self.localDateFormatter.string(from: resetsAt))"
        }

        return title
    }

    @objc private func openUsagePage() {
        guard let url = URL(
            string: "https://chatgpt.com/codex/settings/usage"
        ) else {
            return
        }

        NSWorkspace.shared.open(url)
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
