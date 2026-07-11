import Foundation
import AppKit
import CoreText

enum PDFExportError: LocalizedError {
    case renderingFailed
    case writeFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .renderingFailed:
            return "Could not render the conversation to PDF."
        case .writeFailed(let underlying):
            return "Could not write the PDF file: \(underlying.localizedDescription)"
        }
    }
}

/// Converts a ConversationRecord into a paginated PDF document using Core Text
/// for text layout/pagination and Core Graphics for the PDF context itself.
///
/// Code blocks (```lang ... ```) are detected via MarkdownCodeParser and
/// rendered in a monospaced font on a shaded background, similar to a code
/// editor, instead of being dumped as plain prose like the rest of the reply.
final class PDFExportService {

    private let pageSize = CGSize(width: 612, height: 792) // US Letter, in points
    private let margin: CGFloat = 48

    // Fixed, non-dynamic colors for the PDF. A PDF is a static document with
    // a fixed white page — it should never follow the OS's light/dark mode.
    // NSColor.labelColor / .secondaryLabelColor / .separatorColor are dynamic
    // ("semantic") colors that resolve based on the current NSAppearance. When
    // drawn into an offscreen CGContext (as opposed to a real on-screen NSView),
    // that resolution is unreliable and can come out white-on-white — which is
    // exactly what caused the invisible text. Using fixed RGB values sidesteps
    // that entirely.
    private enum PDFColor {
        static let title = NSColor.black
        static let meta = NSColor(calibratedWhite: 0.45, alpha: 1.0)
        static let divider = NSColor(calibratedWhite: 0.8, alpha: 1.0)
        static let body = NSColor.black
        static let userRole = NSColor(calibratedRed: 0.0, green: 0.42, blue: 0.91, alpha: 1.0)
        static let assistantRole = NSColor.black
        static let codeBackground = NSColor(calibratedWhite: 0.94, alpha: 1.0)
        static let codeForeground = NSColor(calibratedRed: 0.11, green: 0.11, blue: 0.13, alpha: 1.0)
        static let codeLabel = NSColor(calibratedWhite: 0.45, alpha: 1.0)
    }

    /// Renders the conversation to PDF bytes.
    func generatePDFData(for conversation: ConversationRecord, turns: [TurnRecord]) throws -> Data {
        let attributedString = buildAttributedString(for: conversation, turns: turns)
        guard let data = renderPDF(from: attributedString) else {
            throw PDFExportError.renderingFailed
        }
        return data
    }

    /// Renders and writes the PDF to the given destination URL.
    @discardableResult
    func exportPDF(for conversation: ConversationRecord, turns: [TurnRecord], to url: URL) throws -> URL {
        let data = try generatePDFData(for: conversation, turns: turns)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw PDFExportError.writeFailed(underlying: error)
        }
        return url
    }

    // MARK: - Attributed string construction

    private func buildAttributedString(for conversation: ConversationRecord, turns: [TurnRecord]) -> NSAttributedString {
        let result = NSMutableAttributedString()

        let titleFont = NSFont.boldSystemFont(ofSize: 20)
        let metaFont = NSFont.systemFont(ofSize: 10)
        let roleFont = NSFont.boldSystemFont(ofSize: 13)

        let titleParagraph = NSMutableParagraphStyle()
        titleParagraph.paragraphSpacing = 10

        result.append(NSAttributedString(
            string: conversation.title + "\n",
            attributes: [.font: titleFont, .foregroundColor: PDFColor.title, .paragraphStyle: titleParagraph]
        ))

        let metaParagraph = NSMutableParagraphStyle()
        metaParagraph.paragraphSpacing = 4

        result.append(NSAttributedString(
            string: "Created: \(conversation.createdAtDisplay)\n",
            attributes: [
                .font: metaFont,
                .foregroundColor: PDFColor.meta,
                .paragraphStyle: metaParagraph
            ]
        ))
        result.append(NSAttributedString(
            string: "Updated: \(conversation.updatedAtDisplay)\n\n",
            attributes: [
                .font: metaFont,
                .foregroundColor: PDFColor.meta,
                .paragraphStyle: metaParagraph
            ]
        ))

        let divider = NSAttributedString(
            string: "―――――――――――――――――――――――\n\n",
            attributes: [.font: metaFont, .foregroundColor: PDFColor.divider]
        )
        result.append(divider)

        let turnParagraph = NSMutableParagraphStyle()
        turnParagraph.paragraphSpacing = 14
        turnParagraph.lineSpacing = 2

        for turn in turns {
            let roleColor: NSColor = turn.role == .user ? PDFColor.userRole : PDFColor.assistantRole

            result.append(NSAttributedString(
                string: turn.role.displayLabel + "\n",
                attributes: [.font: roleFont, .foregroundColor: roleColor, .paragraphStyle: turnParagraph]
            ))

            result.append(attributedContent(for: turn.text, baseParagraphStyle: turnParagraph))
            result.append(NSAttributedString(string: "\n", attributes: [.font: metaFont]))
        }

        return result
    }

    /// Splits a turn's text into plain/code segments and returns them as one
    /// attributed string, styling code blocks distinctly from prose.
    private func attributedContent(for text: String, baseParagraphStyle: NSParagraphStyle) -> NSAttributedString {
        let bodyFont = NSFont.systemFont(ofSize: 12)
        let codeFont = NSFont.monospacedSystemFont(ofSize: 10.5, weight: .regular)

        let codeParagraph = NSMutableParagraphStyle()
        codeParagraph.paragraphSpacingBefore = 6
        codeParagraph.paragraphSpacing = 6
        codeParagraph.headIndent = 10
        codeParagraph.firstLineHeadIndent = 10
        codeParagraph.lineSpacing = 2

        let result = NSMutableAttributedString()
        let segments = MarkdownCodeParser.parse(text)

        for segment in segments {
            switch segment.kind {
            case .text:
                result.append(NSAttributedString(
                    string: segment.content,
                    attributes: [
                        .font: bodyFont,
                        .foregroundColor: PDFColor.body,
                        .paragraphStyle: baseParagraphStyle
                    ]
                ))

            case .code(let language):
                // Language label line, e.g. "swift"
                if let language {
                    result.append(NSAttributedString(
                        string: language.uppercased() + "\n",
                        attributes: [
                            .font: NSFont.boldSystemFont(ofSize: 8.5),
                            .foregroundColor: PDFColor.codeLabel,
                            .backgroundColor: PDFColor.codeBackground,
                            .paragraphStyle: codeParagraph
                        ]
                    ))
                }

                let codeLines = segment.content.isEmpty ? " " : segment.content
                result.append(NSAttributedString(
                    string: codeLines + "\n",
                    attributes: [
                        .font: codeFont,
                        .foregroundColor: PDFColor.codeForeground,
                        .backgroundColor: PDFColor.codeBackground,
                        .paragraphStyle: codeParagraph
                    ]
                ))
            }
        }

        return result
    }

    // MARK: - Core Text pagination + PDF rendering

    /// Paginates the attributed string across as many PDF pages as needed using
    /// CTFramesetter, which is the standard Core Text technique for flowing text
    /// across multiple pages: keep asking for a frame starting where the last one
    /// left off until the whole string has been consumed.
    private func renderPDF(from attributedString: NSAttributedString) -> Data? {
        let pdfData = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: pageSize)

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }

        // Extra safety net: even though we now use fixed (non-dynamic) colors
        // everywhere above, force light-appearance color resolution during
        // drawing in case any dynamic system color ever sneaks back in here.
        // A PDF page is always a fixed white page, so it should never pick up
        // colors meant for dark mode.
        if let lightAppearance = NSAppearance(named: .aqua) {
            lightAppearance.performAsCurrentDrawingAppearance {
                drawPages(from: attributedString, into: context, mediaBox: mediaBox)
            }
        } else {
            drawPages(from: attributedString, into: context, mediaBox: mediaBox)
        }

        return pdfData as Data
    }

    private func drawPages(from attributedString: NSAttributedString, into context: CGContext, mediaBox: CGRect) {
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let textRect = mediaBox.insetBy(dx: margin, dy: margin)
        let path = CGPath(rect: textRect, transform: nil)

        var currentRange = CFRange(location: 0, length: 0)
        let totalLength = attributedString.length

        repeat {
            context.beginPDFPage(nil)

            let frame = CTFramesetterCreateFrame(framesetter, currentRange, path, nil)
            CTFrameDraw(frame, context)

            let visibleRange = CTFrameGetVisibleStringRange(frame)
            context.endPDFPage()

            // Safety valve: if a page can't fit any content, bail out instead of looping forever.
            guard visibleRange.length > 0 else { break }

            currentRange.location += visibleRange.length
        } while currentRange.location < totalLength

        context.closePDF()
    }
}
