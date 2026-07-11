import Foundation

/// Splits a message's raw text into alternating plain-text and code-block
/// segments, so both the live chat UI and the PDF exporter can render fenced
/// code (```lang ... ```) in an editor-like style instead of as plain prose.
enum MarkdownCodeParser {

    // Matches ```optionalLanguage\n ...code... \n``` (non-greedy, spans newlines)
    private static let fenceRegex: NSRegularExpression? = {
        let pattern = "```([a-zA-Z0-9+#._-]*)\\n?([\\s\\S]*?)```"
        return try? NSRegularExpression(pattern: pattern)
    }()

    static func parse(_ text: String) -> [MessageSegment] {
        guard let fenceRegex else { return [MessageSegment(kind: .text, content: text)] }

        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        let matches = fenceRegex.matches(in: text, range: fullRange)

        guard !matches.isEmpty else {
            return [MessageSegment(kind: .text, content: text)]
        }

        var segments: [MessageSegment] = []
        var cursor = 0

        for match in matches {
            // Plain text before this code block
            if match.range.location > cursor {
                let plainRange = NSRange(location: cursor, length: match.range.location - cursor)
                let plainText = nsText.substring(with: plainRange)
                if !plainText.isEmpty {
                    segments.append(MessageSegment(kind: .text, content: plainText))
                }
            }

            let languageRange = match.range(at: 1)
            let codeRange = match.range(at: 2)

            let language = languageRange.length > 0 ? nsText.substring(with: languageRange) : nil
            var code = codeRange.length > 0 ? nsText.substring(with: codeRange) : ""

            // Trim a single trailing newline so the code block doesn't end with a blank line
            if code.hasSuffix("\n") {
                code.removeLast()
            }

            segments.append(MessageSegment(kind: .code(language: language?.isEmpty == true ? nil : language), content: code))

            cursor = match.range.location + match.range.length
        }

        // Trailing plain text after the last code block
        if cursor < nsText.length {
            let trailingText = nsText.substring(from: cursor)
            if !trailingText.isEmpty {
                segments.append(MessageSegment(kind: .text, content: trailingText))
            }
        }

        return segments
    }
}
