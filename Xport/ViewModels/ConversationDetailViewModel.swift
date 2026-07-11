import Foundation
import AppKit
import UniformTypeIdentifiers
import Combine

/// Owns both:
/// 1. Lazy loading of a conversation's turns (fetched on demand, not eagerly
///    at list-load time), and
/// 2. Exporting the loaded conversation to PDF.
///
/// Turn loading is driven by the View via `.task(id: conversation.id) { ... }`,
/// which SwiftUI automatically cancels if the id changes (i.e. the user picks
/// a different conversation) before the previous load finishes. Combined with
/// the cancellation checks inside DatabaseReader.readTurns, this prevents
/// switching rapidly between conversations from piling up abandoned work or
/// memory, and from blocking the main thread (no more spinning-beachball).
@MainActor
final class ConversationDetailViewModel: ObservableObject {

    @Published var turns: [TurnRecord] = []
    @Published var isLoadingTurns: Bool = false
    @Published var loadErrorMessage: String?

    @Published var isExporting: Bool = false
    @Published var exportErrorMessage: String?
    @Published var lastExportedURL: URL?

    private let databaseReader: DatabaseReader
    private let folderAccessService: FolderAccessService
    private let pdfExportService: PDFExportService

    init(
        databaseReader: DatabaseReader = DatabaseReader(),
        folderAccessService: FolderAccessService = FolderAccessService(),
        pdfExportService: PDFExportService = PDFExportService()
    ) {
        self.databaseReader = databaseReader
        self.folderAccessService = folderAccessService
        self.pdfExportService = pdfExportService
    }

    /// Loads turns for the given conversation from its source .db file.
    /// Intended to be called from `.task(id: conversation.id)` so SwiftUI
    /// cancels any in-flight load automatically when the selection changes.
    func loadTurns(for conversation: ConversationRecord, folderURL: URL?) async {
        isLoadingTurns = true
        loadErrorMessage = nil
        // Clear stale turns immediately so the previous conversation's
        // messages don't briefly flash while the new one loads.
        turns = []

        let didStartAccessing = folderURL.map { folderAccessService.startAccessing($0) } ?? false
        defer {
            if didStartAccessing, let folderURL {
                folderAccessService.stopAccessing(folderURL)
            }
        }

        do {
            let filePath = conversation.sourceFilePath
            let conversationID = conversation.id
            let reader = databaseReader

            let loadedTurns = try await Task.detached(priority: .userInitiated) {
                try reader.readTurns(fromFile: filePath, conversationID: conversationID)
            }.value

            // Task.detached doesn't automatically inherit cancellation from a
            // surrounding SwiftUI `.task`, so check explicitly before publishing —
            // avoids overwriting newer state with a stale, slow-finishing result.
            try Task.checkCancellation()

            turns = loadedTurns
            isLoadingTurns = false
        } catch is CancellationError {
            // Superseded by a newer selection — silently drop this result.
        } catch {
            isLoadingTurns = false
            loadErrorMessage = error.localizedDescription
        }
    }

    /// Presents an NSSavePanel so the user picks the destination, then renders
    /// and writes the PDF off the main thread using the currently loaded turns.
    func exportConversation(_ conversation: ConversationRecord) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = sanitizedFileName(from: conversation.title)
        panel.title = "Export Conversation as PDF"
        panel.message = "Choose where to save this conversation"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let destinationURL = panel.url else {
            return // user cancelled
        }

        isExporting = true
        exportErrorMessage = nil
        lastExportedURL = nil

        let turnsSnapshot = turns
        let service = pdfExportService

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try service.exportPDF(for: conversation, turns: turnsSnapshot, to: destinationURL)
                DispatchQueue.main.async {
                    self?.isExporting = false
                    self?.lastExportedURL = destinationURL
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isExporting = false
                    self?.exportErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func sanitizedFileName(from title: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = title.components(separatedBy: invalidCharacters).joined(separator: "-")
        return cleaned.isEmpty ? "Conversation" : cleaned
    }
}
