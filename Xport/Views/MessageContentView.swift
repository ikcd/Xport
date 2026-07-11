import SwiftUI
import AppKit

/// Renders a message's text, splitting out fenced ```code``` blocks and
/// displaying them in a monospaced, editor-style panel (language tag, dark
/// background, horizontal scroll for long lines) instead of as plain prose.
struct MessageContentView: View {
    let text: String

    private var segments: [MessageSegment] {
        MarkdownCodeParser.parse(text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(segments) { segment in
                switch segment.kind {
                case .text:
                    Text(segment.content)
                        .font(.body)
                        .textSelection(.enabled)

                case .code(let language):
                    CodeBlockView(code: segment.content, language: language)
                }
            }
        }
    }
}

private struct CodeBlockView: View {
    let code: String
    let language: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let language {
                HStack {
                    Text(language.uppercased())
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    CopyButton(text: code)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.25))
            } else {
                HStack {
                    Spacer()
                    CopyButton(text: code)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.25))
            }

            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(Color(red: 0.85, green: 0.87, blue: 0.9))
                    .padding(10)
                    .textSelection(.enabled)
            }
            .background(Color.black.opacity(0.85))
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.3), lineWidth: 1)
        )
    }
}

private struct CopyButton: View {
    let text: String
    @State private var copied = false

    var body: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                copied = false
            }
        } label: {
            Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }
}
