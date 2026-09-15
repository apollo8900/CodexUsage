import AppKit
import Foundation

@main
struct CodexUsageMain {
    static func main() {
        if CommandLine.arguments.contains("--check") || CommandLine.arguments.contains("-c") {
            let antigravity = AntigravityUsageReader().readLatest()
            let codex = UsageReader().readLatest()

            print("=== ChatGPT (CG) Usage ===")
            if let c5 = codex.fiveHour {
                var info = "5h Limit: \(c5.remainingPercent)% remaining"
                if let reset = c5.activeResetDate {
                    info += " · resets \(reset)"
                }
                print(info)
            } else {
                print("5h Limit: Not available")
            }

            if let cw = codex.weekly {
                var info = "7d Limit: \(cw.remainingPercent)% remaining"
                if let reset = cw.activeResetDate {
                    info += " · resets \(reset)"
                }
                print(info)
            } else {
                print("7d Limit: Not available")
            }

            print("\n=== Claude (CL) Usage ===")
            if let cl5 = antigravity.thirdParty5h {
                var info = "5h Limit: \(cl5.remainingPercent)% remaining"
                if let reset = cl5.activeResetDate {
                    info += " · resets \(reset)"
                }
                print(info)
            } else {
                print("5h Limit: Not available")
            }

            if let clw = antigravity.thirdPartyWeekly {
                var info = "7d Limit: \(clw.remainingPercent)% remaining"
                if let reset = clw.activeResetDate {
                    info += " · resets \(reset)"
                }
                print(info)
            } else {
                print("7d Limit: Not available")
            }

            print("\n=== Gemini (GM) Usage ===")
            if let g5 = antigravity.gemini5h {
                var info = "5h Limit: \(g5.remainingPercent)% remaining"
                if let reset = g5.activeResetDate {
                    info += " · resets \(reset)"
                }
                print(info)
            } else {
                print("5h Limit: Not available")
            }

            if let gw = antigravity.geminiWeekly {
                var info = "7d Limit: \(gw.remainingPercent)% remaining"
                if let reset = gw.activeResetDate {
                    info += " · resets \(reset)"
                }
                print(info)
            } else {
                print("7d Limit: Not available")
            }
            return
        }

        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

