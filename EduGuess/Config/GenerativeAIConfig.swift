import Foundation

enum GenerativeAIConfig {
    /// Returns the Gemini API key fetched from Firebase Remote Config.
    /// The key is configured in the Firebase Console under Remote Config
    /// with parameter name: "gemini_api_key"
    /// If Remote Config has not been fetched or the key is empty, the app
    /// falls back to static question templates.
    static var apiKey: String {
        RemoteConfigService.geminiApiKey
    }
}
