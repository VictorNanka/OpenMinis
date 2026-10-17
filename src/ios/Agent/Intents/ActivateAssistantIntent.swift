import AppIntents
import Foundation

private let logger = AppLogger(category: "ActivateAssistantIntent")

/// Side Button Access — Japan-only voice assistant activation.
///
/// People in Japan can assign Minis to the iPhone side button. Pressing and
/// holding that button should land immediately in a live voice conversation
/// (mic armed, audio session running), not on a silent home screen.
///
/// Requires:
/// - Entitlement `com.apple.developer.side-button-access.allow` (Minis.entitlements)
/// - Matching App ID capability + provisioning profile
/// - Apple Account region = Japan, and physical presence in Japan (production)
///
/// Docs:
/// https://developer.apple.com/documentation/appintents/launching-your-voice-based-conversational-app-from-the-side-button-of-iphone
///
/// Schema contract (metadata-processor): use `supportedModes = .foreground`
/// rather than `openAppWhenRun`. Availability matches the assistant schema
/// domain (iOS 26+).
@available(iOS 26.0, *)
@AppIntent(schema: .assistant.activate)
struct ActivateAssistantIntent {
    static let supportedModes: IntentModes = .foreground

    @MainActor
    func perform() async throws -> some IntentResult {
        logger.info("Side Button activate — launching voice chat")

        // Pre-warm the capture audio session before the chat UI mounts so the
        // mic path is already live when AIChatView starts recording (Apple:
        // "start an audio session" immediately on side-button launch).
        AudioSessionCoordinator.shared.begin(.capture)

        // Same navigation + mic start path as Home Screen "Chat with Voice".
        QuickActionRouter.shared.launchVoiceChat(source: "sideButton")

        return .result()
    }
}
