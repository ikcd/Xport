import Foundation
import SQLite3

/// Service responsible for all data access: finding .db files, opening them,
/// and mapping raw SQLite rows into Model objects. No UI or state-management
/// logic lives here — that belongs in the ViewModel.
final class DatabaseReader {

    /// Finds all `.db` files inside a given folder.
    func findDatabaseFiles(inFolder folderPath: String) -> [String] {
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: folderPath)
            return contents
                .filter { $0.lowercased().hasSuffix(".db") }
                .map { folderPath + "/" + $0 }
        } catch {
            print("❌ Could not read folder at \(folderPath): \(error)")
            return []
        }
    }

    /// Reads ONLY conversation metadata (id, title, dates) from a single .db
    /// file — no turns. This keeps the initial list load fast regardless of
    /// how many messages each conversation contains.
    func readConversationsMetadata(fromFile path: String) -> [ConversationRecord] {
        guard let db = SQLiteHelper.openDatabase(at: path) else { return [] }
        defer { sqlite3_close(db) }

        return readConversationRows(db: db, sourceFilePath: path)
    }

    /// Reads the turns for a single conversation, on demand, from its source
    /// .db file. Throws `CancellationError` if the enclosing Task is
    /// cancelled mid-read (e.g. the user switched to a different conversation
    /// before this finished) so no wasted work or memory piles up.
    func readTurns(fromFile path: String, conversationID: String) throws -> [TurnRecord] {
        guard let db = SQLiteHelper.openDatabase(at: path) else { return [] }
        defer { sqlite3_close(db) }

        var results: [TurnRecord] = []
        let query = "SELECT id, role, data FROM Turn WHERE conversationID = ? ORDER BY rowID ASC;"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else {
            print("❌ Failed to prepare Turn query: \(String(cString: sqlite3_errmsg(db)))")
            return results
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, conversationID, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        var rowCount = 0
        while sqlite3_step(stmt) == SQLITE_ROW {
            rowCount += 1
            // Check for cancellation periodically rather than every row, to
            // avoid the overhead of checking on every single iteration.
            if rowCount % 25 == 0 {
                try Task.checkCancellation()
            }

            let id = SQLiteHelper.columnText(stmt, 0) ?? "unknown"
            let roleRaw = SQLiteHelper.columnText(stmt, 1) ?? "unknown"
            let rawJSON = SQLiteHelper.columnBlobAsString(stmt, 2) ?? "{}"

            let text = TurnTextExtractor.extractText(fromJSONString: rawJSON)
            results.append(TurnRecord(id: id, role: TurnRecord.Role(rawValue: roleRaw), text: text))
        }

        return results
    }

    // MARK: - Private

    private func readConversationRows(db: OpaquePointer, sourceFilePath: String) -> [ConversationRecord] {
        var results: [ConversationRecord] = []
        let query = "SELECT id, title, createdAt, updatedAt FROM Conversation;"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else {
            print("❌ Failed to prepare Conversation query: \(String(cString: sqlite3_errmsg(db)))")
            return results
        }
        defer { sqlite3_finalize(stmt) }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = SQLiteHelper.columnText(stmt, 0) ?? "unknown"
            let title = SQLiteHelper.columnText(stmt, 1) ?? "(untitled)"
            let createdAt = DateFormatterHelper.date(fromUnixTimestamp: SQLiteHelper.columnDoubleOrNil(stmt, 2))
            let updatedAt = DateFormatterHelper.date(fromUnixTimestamp: SQLiteHelper.columnDoubleOrNil(stmt, 3))

            results.append(ConversationRecord(
                id: id,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sourceFilePath: sourceFilePath
            ))
        }

        return results
    }
}
