import Foundation

/// Plain data model representing a single row from the `Conversation` table.
///
/// Turns are intentionally NOT loaded here — only lightweight metadata is
/// fetched when the conversation list is built. Turns are fetched on demand
/// when a conversation is actually opened (see ConversationDetailViewModel),
/// so listing hundreds of conversations stays fast and doesn't eagerly pull
/// every message from every .db file into memory up front.
struct ConversationRecord: Identifiable, Equatable {
    let id: String
    let title: String
    let createdAt: Date?
    let updatedAt: Date?

    /// Full path to the .db file this conversation came from, needed to
    /// reopen it later when lazily loading turns.
    let sourceFilePath: String

    var sourceFileName: String {
        (sourceFilePath as NSString).lastPathComponent
    }

    var createdAtDisplay: String {
        DateFormatterHelper.humanReadable(createdAt)
    }

    var updatedAtDisplay: String {
        DateFormatterHelper.humanReadable(updatedAt)
    }
}
