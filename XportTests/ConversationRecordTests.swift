import XCTest
@testable import Xport

// MARK: - ConversationRecord Tests

final class ConversationRecordTests: XCTestCase {

    func testSourceFileName() {
        let record = ConversationRecord(
            id: "1",
            title: "Test",
            createdAt: nil,
            updatedAt: nil,
            sourceFilePath: "/some/path/to/mydb.db"
        )
        XCTAssertEqual(record.sourceFileName, "mydb.db")
    }

    func testCreatedAtDisplayNil() {
        let record = ConversationRecord(id: "1", title: "T", createdAt: nil, updatedAt: nil, sourceFilePath: "")
        XCTAssertEqual(record.createdAtDisplay, "N/A")
    }

    func testUpdatedAtDisplayNil() {
        let record = ConversationRecord(id: "1", title: "T", createdAt: nil, updatedAt: nil, sourceFilePath: "")
        XCTAssertEqual(record.updatedAtDisplay, "N/A")
    }

    func testCreatedAtDisplayWithDate() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let record = ConversationRecord(id: "1", title: "T", createdAt: date, updatedAt: nil, sourceFilePath: "")
        XCTAssertNotEqual(record.createdAtDisplay, "N/A")
    }
}

