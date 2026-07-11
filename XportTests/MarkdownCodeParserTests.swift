import XCTest
@testable import Xport

// MARK: - MarkdownCodeParser Tests

final class MarkdownCodeParserTests: XCTestCase {

    func testPlainTextNoCodeBlock() {
        let segments = MarkdownCodeParser.parse("Just plain text")
        XCTAssertEqual(segments.count, 1)
        if case .text = segments[0].kind {
            XCTAssertEqual(segments[0].content, "Just plain text")
        } else {
            XCTFail("Expected text segment")
        }
    }

    func testSingleCodeBlock() {
        let input = "```swift\nlet x = 1\n```"
        let segments = MarkdownCodeParser.parse(input)
        XCTAssertEqual(segments.count, 1)
        if case .code(let lang) = segments[0].kind {
            XCTAssertEqual(lang, "swift")
            XCTAssertEqual(segments[0].content, "let x = 1")
        } else {
            XCTFail("Expected code segment")
        }
    }

    func testCodeBlockWithoutLanguage() {
        let input = "```\nsome code\n```"
        let segments = MarkdownCodeParser.parse(input)
        XCTAssertEqual(segments.count, 1)
        if case .code(let lang) = segments[0].kind {
            XCTAssertNil(lang)
        } else {
            XCTFail("Expected code segment")
        }
    }

    func testTextBeforeCodeBlock() {
        let input = "Intro text\n```swift\nlet x = 1\n```"
        let segments = MarkdownCodeParser.parse(input)
        XCTAssertEqual(segments.count, 2)
        if case .text = segments[0].kind { } else { XCTFail("Expected text first") }
        if case .code = segments[1].kind { } else { XCTFail("Expected code second") }
    }

    func testTextAfterCodeBlock() {
        let input = "```swift\nlet x = 1\n```\nTrailing text"
        let segments = MarkdownCodeParser.parse(input)
        XCTAssertEqual(segments.count, 2)
        if case .code = segments[0].kind { } else { XCTFail("Expected code first") }
        if case .text = segments[1].kind {
            XCTAssertEqual(segments[1].content, "\nTrailing text")
        } else {
            XCTFail("Expected text second")
        }
    }

    func testTextBetweenCodeBlocks() {
        let input = "```swift\nlet x = 1\n```\nMiddle\n```python\nprint('hi')\n```"
        let segments = MarkdownCodeParser.parse(input)
        XCTAssertEqual(segments.count, 3)
        if case .code(let lang) = segments[0].kind { XCTAssertEqual(lang, "swift") } else { XCTFail() }
        if case .text = segments[1].kind { } else { XCTFail("Expected text middle") }
        if case .code(let lang) = segments[2].kind { XCTAssertEqual(lang, "python") } else { XCTFail() }
    }

    func testEmptyString() {
        let segments = MarkdownCodeParser.parse("")
        XCTAssertEqual(segments.count, 1)
        if case .text = segments[0].kind {
            XCTAssertEqual(segments[0].content, "")
        } else {
            XCTFail("Expected text segment for empty input")
        }
    }

    func testCodeBlockTrailingNewlineStripped() {
        let input = "```swift\nlet x = 1\n\n```"
        let segments = MarkdownCodeParser.parse(input)
        XCTAssertEqual(segments.count, 1)
        if case .code = segments[0].kind {
            XCTAssertFalse(segments[0].content.hasSuffix("\n"), "Trailing newline should be stripped")
        } else {
            XCTFail("Expected code segment")
        }
    }

    func testMultipleCodeBlocksSameLanguage() {
        let input = "```js\nconsole.log(1)\n```\n```js\nconsole.log(2)\n```"
        let segments = MarkdownCodeParser.parse(input)
        let codeSegments = segments.filter {
            if case .code = $0.kind { return true }
            return false
        }
        XCTAssertEqual(codeSegments.count, 2)
    }
}
