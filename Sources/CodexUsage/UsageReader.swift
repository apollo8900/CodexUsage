import Foundation

final class UsageReader {
    private let fileManager = FileManager.default
    private let tailBytes: UInt64 = 4 * 1024 * 1024
    private let maxCandidateFiles = 24

    func readLatest() -> UsageSnapshot {
        let codexHome = ProcessInfo.processInfo.environment["CODEX_HOME"]
            ?? (NSHomeDirectory() + "/.codex")

        let sessionsURL = URL(fileURLWithPath: codexHome)
            .appendingPathComponent("sessions")

        guard let enumerator = fileManager.enumerator(
            at: sessionsURL,
            includingPropertiesForKeys: [
                .contentModificationDateKey,
                .isRegularFileKey
            ],
            options: [.skipsHiddenFiles]
        ) else {
            return .empty
        }

        var files: [(url: URL, date: Date)] = []

        for case let url as URL in enumerator {
            guard url.pathExtension == "jsonl",
                  url.lastPathComponent.hasPrefix("rollout-") else {
                continue
            }

            let values = try? url.resourceValues(
                forKeys: [.contentModificationDateKey, .isRegularFileKey]
            )

            guard values?.isRegularFile == true else {
                continue
            }

            files.append((
                url,
                values?.contentModificationDate ?? .distantPast
            ))
        }

        files.sort { $0.date > $1.date }

        var best: (snapshot: UsageSnapshot, date: Date)?

        for item in files.prefix(maxCandidateFiles) {
            guard let snapshot = readSnapshot(from: item.url) else {
                continue
            }

            let timestamp = snapshot.recordedAt ?? item.date

            if best == nil || timestamp > best!.date {
                best = (snapshot, timestamp)
            }
        }

        return best?.snapshot ?? .empty
    }

    private func readSnapshot(from url: URL) -> UsageSnapshot? {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }

        defer {
            try? handle.close()
        }

        let size = (try? handle.seekToEnd()) ?? 0
        let start = size > tailBytes ? size - tailBytes : 0

        try? handle.seek(toOffset: start)

        guard let data = try? handle.readToEnd() else {
            return nil
        }

        guard let text = String(data: data, encoding: .utf8) else {
            return nil
        }

        let lines = text.split(
            separator: "\n",
            omittingEmptySubsequences: true
        )

        for rawLine in lines.reversed() {
            guard rawLine.contains("\"rate_limits\"")
                || rawLine.contains("\"rateLimits\"") else {
                continue
            }

            let line = String(rawLine)

            guard let lineData = line.data(using: .utf8),
                  let root = try? JSONSerialization.jsonObject(
                    with: lineData
                  ) as? [String: Any] else {
                continue
            }

            let payload = root["payload"] as? [String: Any]

            let rateLimits =
                (payload?["rate_limits"] as? [String: Any])
                ?? (payload?["rateLimits"] as? [String: Any])
                ?? (root["rate_limits"] as? [String: Any])
                ?? (root["rateLimits"] as? [String: Any])

            guard let rateLimits else {
                continue
            }

            let primary = parseWindow(
                rateLimits["primary"] as? [String: Any]
            )

            let secondary = parseWindow(
                rateLimits["secondary"] as? [String: Any]
            )

            var fiveHour: UsageWindow?
            var weekly: UsageWindow?

            for window in [primary, secondary].compactMap({ $0 }) {
                switch window.windowMinutes {
                case 300:
                    fiveHour = window
                case 10080:
                    weekly = window
                default:
                    break
                }
            }

            if fiveHour == nil, let primary {
                fiveHour = primary
            }

            if weekly == nil, let secondary {
                weekly = secondary
            }

            guard fiveHour != nil || weekly != nil else {
                continue
            }

            let recordedAt = parseTimestamp(root["timestamp"])

            return UsageSnapshot(
                fiveHour: fiveHour,
                weekly: weekly,
                recordedAt: recordedAt
            )
        }

        return nil
    }

    private func parseWindow(_ dictionary: [String: Any]?) -> UsageWindow? {
        guard let dictionary else {
            return nil
        }

        let usedPercent =
            number(dictionary["used_percent"])
            ?? number(dictionary["usedPercent"])

        let windowMinutes =
            integer(dictionary["window_minutes"])
            ?? integer(dictionary["windowDurationMins"])
            ?? integer(dictionary["window_duration_mins"])

        let resetsAt =
            integer(dictionary["resets_at"])
            ?? integer(dictionary["resetsAt"])
            ?? integer(dictionary["reset_at"])

        guard let usedPercent, let windowMinutes else {
            return nil
        }

        return UsageWindow(
            usedPercent: usedPercent,
            windowMinutes: windowMinutes,
            resetsAt: resetsAt.map {
                Date(timeIntervalSince1970: TimeInterval($0))
            }
        )
    }

    private func parseTimestamp(_ value: Any?) -> Date? {
        guard let string = value as? String else {
            return nil
        }

        if let date = ISO8601DateFormatter().date(from: string) {
            return date
        }

        return ISO8601DateFormatter.fractional.date(from: string)
    }

    private func number(_ value: Any?) -> Double? {
        if let number = value as? NSNumber {
            return number.doubleValue
        }

        if let string = value as? String {
            return Double(string)
        }

        return nil
    }

    private func integer(_ value: Any?) -> Int? {
        if let number = value as? NSNumber {
            return number.intValue
        }

        if let string = value as? String {
            return Int(string)
        }

        return nil
    }
}

private extension ISO8601DateFormatter {
    static let fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        return formatter
    }()
}
