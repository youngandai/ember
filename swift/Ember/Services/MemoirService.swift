import Foundation

struct MemoirService {
    static func generateMemoir(from transcript: String, sessionTitle: String) async throws -> String {
        let apiKey = APIKeyStore.anthropic
        guard !apiKey.isEmpty else {
            throw EmberError.missingAPIKey("ANTHROPIC_API_KEY — add it in Settings (⌘,)")
        }

        let systemPrompt = """
        You are a skilled memoir writer who transforms spoken stories into beautifully written \
        first-person memoir chapters. Your writing is warm, intimate, and literary — preserving \
        the speaker's unique voice and personality while elevating the prose to be worthy of a \
        treasured family keepsake.

        Guidelines:
        - Write in first person, as if the speaker is writing
        - Preserve the speaker's distinctive phrases, rhythms, and personality
        - Add sensory detail and emotional depth without inventing facts
        - Use evocative, literary prose — not journalistic or clinical
        - Structure as a proper memoir chapter with a beginning, middle, and end
        - The result should feel like something you'd find in a beautifully published memoir
        - Keep the length proportional to the source material
        """

        let userPrompt = """
        Please transform this recorded story called "\(sessionTitle)" into a beautifully written \
        first-person memoir chapter. Preserve the speaker's voice while elevating the prose.

        Transcript:
        \(transcript)
        """

        let requestBody: [String: Any] = [
            "model": "claude-opus-4-6",
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userPrompt]
            ]
        ]

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmberError.networkError("Invalid response")
        }
        guard httpResponse.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw EmberError.apiError("Claude API error \(httpResponse.statusCode): \(message)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw EmberError.apiError("Failed to parse Claude response")
        }

        return text
    }
}
