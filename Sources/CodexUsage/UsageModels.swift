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
