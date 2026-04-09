import Foundation

enum EmberError: LocalizedError {
    case missingAPIKey(String)
    case networkError(String)
    case apiError(String)
    case fileError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let key):
            return "Missing API key: \(key). Set it in your environment variables."
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .apiError(let msg):
            return "API error: \(msg)"
        case .fileError(let msg):
            return "File error: \(msg)"
        }
    }
}
