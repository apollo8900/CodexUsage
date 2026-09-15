import Foundation

final class AntigravityUsageReader {
    private var cachedEndpoint: (port: Int, csrfToken: String)?
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 1.5
        config.timeoutIntervalForResource = 2.0
        self.session = URLSession(configuration: config)
    }

    func readLatest() -> AntigravitySnapshot {
        // 1. Try cached endpoint first if available
        if let cached = cachedEndpoint,
           let snapshot = fetchQuota(port: cached.port, csrfToken: cached.csrfToken) {
            return snapshot
        }
        cachedEndpoint = nil

        // 2. Discover running language_server instances
        let candidates = findProcessCandidates()
        for candidate in candidates {
            let ports = findListeningPorts(for: candidate.pid)
            for port in ports {
                if let snapshot = fetchQuota(port: port, csrfToken: candidate.csrfToken) {
                    cachedEndpoint = (port: port, csrfToken: candidate.csrfToken)
                    return snapshot
                }
            }
        }

        return .empty
    }

    private struct ProcessCandidate {
        let pid: Int
        let csrfToken: String
    }

    private func findProcessCandidates() -> [ProcessCandidate] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["-fl", "language_server_macos_x64"]
        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
        } catch {
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()

        guard let output = String(data: data, encoding: .utf8) else {
            return []
        }

        var candidates: [ProcessCandidate] = []
        for line in output.components(separatedBy: "\n") {
            guard line.contains("--csrf_token") else { continue }

            let parts = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces)
            guard let pidStr = parts.first, let pid = Int(pidStr) else { continue }

            if let range = line.range(of: "--csrf_token ") {
                let after = line[range.upperBound...]
                let token = after.prefix(while: { !$0.isWhitespace })
                if !token.isEmpty {
                    candidates.append(ProcessCandidate(pid: pid, csrfToken: String(token)))
                }
            }
        }
        return candidates
    }

    private func findListeningPorts(for pid: Int) -> [Int] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        task.arguments = ["-a", "-p", "\(pid)", "-iTCP", "-sTCP:LISTEN", "-P", "-n"]
        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
        } catch {
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()

        guard let output = String(data: data, encoding: .utf8) else {
            return []
        }

        var ports: [Int] = []
        for line in output.components(separatedBy: "\n") {
            guard line.contains("127.0.0.1:") else { continue }
            if let range = line.range(of: "127.0.0.1:") {
                let after = line[range.upperBound...]
                let portStr = after.prefix(while: { $0.isNumber })
                if let port = Int(portStr), !ports.contains(port) {
                    ports.append(port)
                }
            }
        }
        return ports
    }

    private func fetchQuota(port: Int, csrfToken: String) -> AntigravitySnapshot? {
        guard let url = URL(string: "http://127.0.0.1:\(port)/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(csrfToken, forHTTPHeaderField: "x-codeium-csrf-token")
        request.httpBody = Data("{}".utf8)

        var result: AntigravitySnapshot?
        let semaphore = DispatchSemaphore(value: 0)

        let task = session.dataTask(with: request) { data, response, _ in
            defer { semaphore.signal() }

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let data = data else {
                return
            }

            result = self.parseResponse(data)
        }

        task.resume()
        _ = semaphore.wait(timeout: .now() + 1.5)

        return result
    }

    private func parseResponse(_ data: Data) -> AntigravitySnapshot? {
        struct ResponseRoot: Decodable {
            let response: QuotaBody?
        }
        struct QuotaBody: Decodable {
            let groups: [QuotaGroup]?
        }
        struct QuotaGroup: Decodable {
            let displayName: String?
            let buckets: [QuotaBucket]?
        }
        struct QuotaBucket: Decodable {
            let bucketId: String?
            let window: String?
            let remainingFraction: Double?
            let resetTime: String?
        }

        guard let root = try? JSONDecoder().decode(ResponseRoot.self, from: data),
              let groups = root.response?.groups else {
            return nil
        }

        var gemini5h: UsageWindow?
        var geminiWeekly: UsageWindow?
        var thirdParty5h: UsageWindow?
        var thirdPartyWeekly: UsageWindow?

        for group in groups {
            let groupName = (group.displayName ?? "").lowercased()
            let isGemini = groupName.contains("gemini")
            let isThirdParty = groupName.contains("claude") || groupName.contains("gpt")

            for bucket in group.buckets ?? [] {
                guard let fraction = bucket.remainingFraction else { continue }
                let remainingPct = max(0.0, min(100.0, fraction * 100.0))
                let usedPercent = 100.0 - remainingPct

                let resetsAt = bucket.resetTime.flatMap { parseDate($0) }
                let windowStr = bucket.window ?? ""
                let bucketId = bucket.bucketId ?? ""

                if isGemini || bucketId.contains("gemini") {
                    if windowStr == "5h" || bucketId.contains("5h") {
                        gemini5h = UsageWindow(
                            usedPercent: usedPercent,
                            windowMinutes: 300,
                            resetsAt: resetsAt
                        )
                    } else if windowStr == "weekly" || bucketId.contains("weekly") {
                        geminiWeekly = UsageWindow(
                            usedPercent: usedPercent,
                            windowMinutes: 10080,
                            resetsAt: resetsAt
                        )
                    }
                } else if isThirdParty || bucketId.contains("3p") {
                    if windowStr == "5h" || bucketId.contains("5h") {
                        thirdParty5h = UsageWindow(
                            usedPercent: usedPercent,
                            windowMinutes: 300,
                            resetsAt: resetsAt
                        )
                    } else if windowStr == "weekly" || bucketId.contains("weekly") {
                        thirdPartyWeekly = UsageWindow(
                            usedPercent: usedPercent,
                            windowMinutes: 10080,
                            resetsAt: resetsAt
                        )
                    }
                }
            }
        }

        guard gemini5h != nil || geminiWeekly != nil || thirdParty5h != nil || thirdPartyWeekly != nil else {
            return nil
        }

        return AntigravitySnapshot(
            gemini5h: gemini5h,
            geminiWeekly: geminiWeekly,
            thirdParty5h: thirdParty5h,
            thirdPartyWeekly: thirdPartyWeekly,
            recordedAt: Date()
        )
    }

    private func parseDate(_ string: String) -> Date? {
        if let date = ISO8601DateFormatter().date(from: string) {
            return date
        }
        return ISO8601DateFormatter.fractional.date(from: string)
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
