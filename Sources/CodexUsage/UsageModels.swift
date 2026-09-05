import Foundation

struct UsageWindow {
    let usedPercent: Double
    let windowMinutes: Int
    let resetsAt: Date?

    var remainingPercent: Int {
        max(0, min(100, Int((100.0 - usedPercent).rounded())))
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
