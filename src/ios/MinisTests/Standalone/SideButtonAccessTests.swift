// Tests for [T-ios-side-button-access] — Japan Side Button Access wiring:
// entitlement, assistant.activate intent, and the shared voice-launch path.
//
// Docs:
//   https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.side-button-access.allow
//   https://developer.apple.com/documentation/appintents/launching-your-voice-based-conversational-app-from-the-side-button-of-iphone
//
// Standalone (`swift SideButtonAccessTests.swift`) like its neighbours.

import Foundation

var failures = 0
func check(_ label: String, _ ok: Bool) {
    if ok { print("  ✅ \(label)") } else { print("  ❌ \(label)"); failures += 1 }
}

print("SideButtonAccessTests")

let entitlements = (try? String(contentsOfFile: "../../Minis.entitlements", encoding: .utf8)) ?? ""
let intent = (try? String(contentsOfFile: "../../Agent/Intents/ActivateAssistantIntent.swift", encoding: .utf8)) ?? ""
let router = (try? String(contentsOfFile: "../../Shared/QuickActionRouter.swift", encoding: .utf8)) ?? ""
let pbx = (try? String(contentsOfFile: "../../Minis.xcodeproj/project.pbxproj", encoding: .utf8)) ?? ""

check("Minis.entitlements readable", !entitlements.isEmpty)
check("ActivateAssistantIntent.swift readable", !intent.isEmpty)
check("QuickActionRouter.swift readable", !router.isEmpty)

check(
    "entitlement com.apple.developer.side-button-access.allow is true",
    entitlements.contains("com.apple.developer.side-button-access.allow")
        && entitlements.contains("<true/>")
)

check(
    "intent uses @AppIntent(schema: .assistant.activate)",
    intent.contains("@AppIntent(schema: .assistant.activate)")
)
check(
    "intent declares supportedModes = .foreground (schema contract)",
    intent.contains("supportedModes: IntentModes = .foreground")
)
check(
    "intent is gated to iOS 26+",
    intent.contains("@available(iOS 26.0, *)")
)
check(
    "intent pre-warms capture audio session",
    intent.contains("AudioSessionCoordinator.shared.begin(.capture)")
)
check(
    "intent launches voice chat via QuickActionRouter",
    intent.contains("launchVoiceChat(source: \"sideButton\")")
)

check(
    "QuickActionRouter exposes launchVoiceChat",
    router.contains("func launchVoiceChat(source: String)")
)
check(
    "Home Screen voice shortcut uses launchVoiceChat",
    router.contains("launchVoiceChat(source: \"homeScreenShortcut\")")
)

check(
    "ActivateAssistantIntent.swift is in the Xcode project",
    pbx.contains("ActivateAssistantIntent.swift in Sources")
        && pbx.contains("path = ActivateAssistantIntent.swift")
)

if failures == 0 {
    print("All SideButtonAccessTests passed.")
    exit(0)
} else {
    print("SideButtonAccessTests failed: \(failures)")
    exit(1)
}
