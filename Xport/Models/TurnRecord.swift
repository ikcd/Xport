import Foundation

/// Plain data model representing a single row from the `Turn` table.
struct TurnRecord: Identifiable {
    enum Role: String {
        case user
        case assistant
        case unknown

        init(rawValue value: String) {
            switch value.lowercased() {
            case "user": self = .user
            case "assistant": self = .assistant
            default: self = .unknown
            }
        }

        var displayLabel: String {
            switch self {
            case .user: return "🧑 User"
            case .assistant: return "🤖 Assistant"
            case .unknown: return "❓ Unknown"
            }
        }
    }

    let id: String
    let role: Role
    let text: String
}
