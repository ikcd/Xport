import Foundation

/// A chunk of a Turn's text, split apart so code blocks can be rendered
/// differently (monospaced, editor-style) from surrounding prose.
struct MessageSegment: Identifiable {
    enum Kind: Equatable {
        case text
        case code(language: String?)
    }

    let id = UUID()
    let kind: Kind
    let content: String
}
