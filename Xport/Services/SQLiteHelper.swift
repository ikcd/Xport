import Foundation
import SQLite3

/// Thin wrapper around the raw SQLite3 C API to keep column-reading boilerplate
/// out of the higher-level DatabaseReader service.
enum SQLiteHelper {

    static func openDatabase(at path: String) -> OpaquePointer? {
        var db: OpaquePointer?
        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
            return db
        }
        print("❌ Could not open database at \(path)")
        return nil
    }

    static func columnText(_ stmt: OpaquePointer?, _ index: Int32) -> String? {
        guard let cString = sqlite3_column_text(stmt, index) else { return nil }
        return String(cString: cString)
    }

    static func columnBlobAsString(_ stmt: OpaquePointer?, _ index: Int32) -> String? {
        guard let bytes = sqlite3_column_blob(stmt, index) else { return nil }
        let length = Int(sqlite3_column_bytes(stmt, index))
        let data = Data(bytes: bytes, count: length)
        return String(data: data, encoding: .utf8)
    }

    static func columnDoubleOrNil(_ stmt: OpaquePointer?, _ index: Int32) -> Double? {
        if sqlite3_column_type(stmt, index) == SQLITE_NULL { return nil }
        return sqlite3_column_double(stmt, index)
    }
}
