import XCTest
@testable import Xport

// MARK: - TurnTextExtractor Tests

final class TurnTextExtractorTests: XCTestCase {

    func testExtractContentField() {
        let json: [String: Any] = ["content": "Hello from user"]
        let result = TurnTextExtractor.extractText(fromTurnJSON: json)
        XCTAssertEqual(result, "Hello from user")
    }

    func testExtractEditAgentRoundsReply() {
        let json: [String: Any] = [
            "editAgentRounds": [["reply": "Assistant reply"]]
        ]
        let result = TurnTextExtractor.extractText(fromTurnJSON: json)
        XCTAssertEqual(result, "Assistant reply")
    }

    func testContentTakesPriorityOverEditAgentRounds() {
        let json: [String: Any] = [
            "content": "Direct content",
            "editAgentRounds": [["reply": "Round reply"]]
        ]
        let result = TurnTextExtractor.extractText(fromTurnJSON: json)
        XCTAssertEqual(result, "Direct content")
    }

    func testEmptyContentFallsToEditAgentRounds() {
        let json: [String: Any] = [
            "content": "",
            "editAgentRounds": [["reply": "Fallback reply"]]
        ]
        let result = TurnTextExtractor.extractText(fromTurnJSON: json)
        XCTAssertEqual(result, "Fallback reply")
    }

    func testNoTextContentReturnsPlaceholder() {
        let json: [String: Any] = [:]
        let result = TurnTextExtractor.extractText(fromTurnJSON: json)
        XCTAssertEqual(result, "(no text content found)")
    }

    func testInvalidJSONStringReturnsUnreadable() {
        let result = TurnTextExtractor.extractText(fromJSONString: "NOT JSON {{{{")
        XCTAssertEqual(result, "(unreadable turn data)")
    }

    func testValidJSONStringWithContent() {
        let jsonString = #"{"content": "Hello"}"#
        let result = TurnTextExtractor.extractText(fromJSONString: jsonString)
        XCTAssertEqual(result, "Hello")
    }

    func testEditAgentRoundsSkipsEmptyReplies() {
        let json: [String: Any] = [
            "editAgentRounds": [
                ["reply": ""],
                ["reply": "Second reply"]
            ]
        ]
        let result = TurnTextExtractor.extractText(fromTurnJSON: json)
        XCTAssertEqual(result, "Second reply")
    }
}
