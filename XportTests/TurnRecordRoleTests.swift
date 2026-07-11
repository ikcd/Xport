import XCTest
@testable import Xport

// MARK: - TurnRecord.Role Tests

final class TurnRecordRoleTests: XCTestCase {

    func testUserRole() {
        let role = TurnRecord.Role(rawValue: "user")
        XCTAssertEqual(role, .user)
        XCTAssertEqual(role.displayLabel, "🧑 User")
    }

    func testAssistantRole() {
        let role = TurnRecord.Role(rawValue: "assistant")
        XCTAssertEqual(role, .assistant)
        XCTAssertEqual(role.displayLabel, "🤖 Assistant")
    }

    func testUnknownRole() {
        let role = TurnRecord.Role(rawValue: "bot")
        XCTAssertEqual(role, .unknown)
        XCTAssertEqual(role.displayLabel, "❓ Unknown")
    }

    func testCaseInsensitiveUser() {
        XCTAssertEqual(TurnRecord.Role(rawValue: "User"), .user)
        XCTAssertEqual(TurnRecord.Role(rawValue: "USER"), .user)
    }

    func testCaseInsensitiveAssistant() {
        XCTAssertEqual(TurnRecord.Role(rawValue: "ASSISTANT"), .assistant)
        XCTAssertEqual(TurnRecord.Role(rawValue: "Assistant"), .assistant)
    }

    func testEmptyStringFallsToUnknown() {
        XCTAssertEqual(TurnRecord.Role(rawValue: ""), .unknown)
    }
}
