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

        // Do NOT call AudioSessionCoordinator.begin(.capture) here.
        // The Home Screen voice path arms the mic from AIChatView →
        // SpeechRecognitionManager.startRecording(), which configures
        // AVAudioSession directly and never ends a coordinator `.capture`
        // claim. A begin without a matching end would pin isCapturing and
        // block reply TTS for the rest of the process.
        //
        // Same navigation + mic start path as Home Screen "Chat with Voice".
        // launchVoiceChat marks the workflow non-idle before any await so
        // ContentView's launchScreen .task treats this as quickActionPending
        // even on cold start (when perform() races session list loading).
        QuickActionRouter.shared.launchVoiceChat(source: "sideButton")

        return .result()
    }
}
