import Foundation

struct UsageWindow {
    let usedPercent: Double
    let windowMinutes: Int
    let resetsAt: Date?

    var hasReset: Bool {
        guard let resetsAt else {
            return false
        }

        return Date() >= resetsAt
    }

    var remainingPercent: Int {
        if hasReset {
            return 100
        }

        return max(
            0,
            min(100, Int((100.0 - usedPercent).rounded()))
        )
    }

    var activeResetDate: Date? {
        guard let resetsAt, !hasReset else {
            return nil
        }

        return resetsAt
    }
}

struct UsageSnapshot {
    let fiveHour: UsageWindow?
    let weekly: UsageWindow?
    let recordedAt: Date?

    static let empty = UsageSnapshot(
        fiveHour: nil,
        weekly: nil,
        recordedAt: nil
    )
}

struct AntigravitySnapshot {
    let gemini5h: UsageWindow?
    let geminiWeekly: UsageWindow?
    let thirdParty5h: UsageWindow?
    let thirdPartyWeekly: UsageWindow?
    let recordedAt: Date?

    static let empty = AntigravitySnapshot(
        gemini5h: nil,
        geminiWeekly: nil,
        thirdParty5h: nil,
        thirdPartyWeekly: nil,
        recordedAt: nil
    )
}

enum DisplayMode: String, CaseIterable {
    case all = "all"
    case cgOnly = "cgOnly"
    case clOnly = "clOnly"
    case gmOnly = "gmOnly"

    var title: String {
        switch self {
        case .all:
            return "All (CG · CL · GM)"
        case .cgOnly:
            return "ChatGPT (CG) Only"
        case .clOnly:
            return "Claude (CL) Only"
        case .gmOnly:
            return "Gemini (GM) Only"
        }
    }

    private static let key = "CodexUsage.DisplayMode"

    static var current: DisplayMode {
        get {
            guard let raw = UserDefaults.standard.string(forKey: key) else {
                return .all
            }
            if let mode = DisplayMode(rawValue: raw) {
                return mode
            }
            switch raw {
            case "both":
                return .all
            case "codexOnly":
                return .cgOnly
            case "geminiOnly":
                return .gmOnly
            default:
                return .all
            }
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
        }
    }
}

