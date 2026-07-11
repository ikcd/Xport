import Foundation

/// Centralized date formatting so every layer converts Unix timestamps consistently.
enum DateFormatterHelper {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.timeZone = TimeZone.current
        return f
    }()

    static func humanReadable(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        return formatter.string(from: date)
    }

    static func date(fromUnixTimestamp timestamp: Double?) -> Date? {
        guard let timestamp = timestamp else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
}
