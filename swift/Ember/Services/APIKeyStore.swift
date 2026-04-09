import Foundation

/// Central place to resolve API keys.
/// Priority: environment variable → UserDefaults (entered in Settings)
enum APIKeyStore {
    static var openAI: String {
        if let env = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !env.isEmpty { return env }
        return UserDefaults.standard.string(forKey: "apiKey_openAI") ?? ""
    }

    static var anthropic: String {
        if let env = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !env.isEmpty { return env }
        return UserDefaults.standard.string(forKey: "apiKey_anthropic") ?? ""
    }

    static func save(openAI: String, anthropic: String) {
        UserDefaults.standard.set(openAI, forKey: "apiKey_openAI")
        UserDefaults.standard.set(anthropic, forKey: "apiKey_anthropic")
    }
}
