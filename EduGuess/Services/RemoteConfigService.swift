import Foundation
import FirebaseRemoteConfig

/// Manages fetching the Gemini API key from Firebase Remote Config.
/// Falls back to a placeholder/empty value if Remote Config is not available,
/// ensuring the app continues to work using static question templates.
enum RemoteConfigService {
    private static let geminiApiKeyParameter = "gemini_api_key"

    /// The Remote Config singleton instance.
    static let remoteConfig: RemoteConfig = {
        let config = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        // Cache duration: 1 hour in production. For development you may lower this.
        settings.minimumFetchInterval = 3600
        config.configSettings = settings
        return config
    }()

    /// Activates any fetched Remote Config values and returns the Gemini API key.
    /// This should be called once at app launch.
    static func activateAndGetGeminiKey() async -> String {
        do {
            // Try to fetch and activate the latest values.
            _ = try await remoteConfig.fetchAndActivate()
        } catch {
            print("Remote Config fetch/activate failed: \(error.localizedDescription)")
            // Continue with defaults/last cached values.
        }

        let key = remoteConfig.configValue(forKey: geminiApiKeyParameter).stringValue ?? ""
        return key.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns the currently cached Gemini API key synchronously.
    /// Use this after `activateAndGetGeminiKey()` has been called at launch.
    static var geminiApiKey: String {
        let key = remoteConfig.configValue(forKey: geminiApiKeyParameter).stringValue ?? ""
        return key.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
