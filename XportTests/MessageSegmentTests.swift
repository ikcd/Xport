import XCTest
@testable import Xport

// MARK: - MessageSegment Tests

final class MessageSegmentTests: XCTestCase {

    func testTextKind() {
        let segment = MessageSegment(kind: .text, content: "Hello")
        XCTAssertEqual(segment.content, "Hello")
        if case .text = segment.kind { } else { XCTFail("Expected .text kind") }
    }

    func testCodeKindWithLanguage() {
        let segment = MessageSegment(kind: .code(language: "swift"), content: "let x = 1")
        if case .code(let lang) = segment.kind {
            XCTAssertEqual(lang, "swift")
        } else {
            XCTFail("Expected .code kind")
        }
    }

    func testCodeKindWithoutLanguage() {
        let segment = MessageSegment(kind: .code(language: nil), content: "some code")
        if case .code(let lang) = segment.kind {
            XCTAssertNil(lang)
        } else {
            XCTFail("Expected .code kind")
        }
    }

    func testUniqueIDs() {
        let s1 = MessageSegment(kind: .text, content: "a")
        let s2 = MessageSegment(kind: .text, content: "b")
        XCTAssertNotEqual(s1.id, s2.id)
    }
}
