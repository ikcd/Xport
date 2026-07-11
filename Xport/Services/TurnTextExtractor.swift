import Foundation

/// Extracts human-readable message text out of a Turn row's JSON `data` blob.
/// User turns store the message directly under "content". Assistant turns
/// sometimes have "content" populated, and sometimes the real reply is nested
/// under editAgentRounds[0].reply — this checks both, in order.
enum TurnTextExtractor {

    static func extractText(fromJSONString rawJSON: String) -> String {
        guard let data = rawJSON.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "(unreadable turn data)"
        }
        return extractText(fromTurnJSON: parsed)
    }

    static func extractText(fromTurnJSON json: [String: Any]) -> String {
        if let content = json["content"] as? String, !content.isEmpty {
            return content
        }

        if let rounds = json["editAgentRounds"] as? [[String: Any]] {
            for round in rounds {
                if let reply = round["reply"] as? String, !reply.isEmpty {
                    return reply
                }
            }
        }

        return "(no text content found)"
    }
}
