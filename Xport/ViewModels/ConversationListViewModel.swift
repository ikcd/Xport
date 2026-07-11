import Foundation
import SwiftUI
import Combine

/// Owns the UI-facing state for the conversation list and drives it by calling
/// into the DatabaseReader service. Views bind to this via @StateObject / @ObservedObject.
///
/// Folder access goes through FolderAccessService, since a sandboxed app
/// cannot read arbitrary hardcoded paths — only folders the user has explicitly
/// granted access to via NSOpenPanel.
///
/// Only conversation metadata is loaded here (not turns) so the list stays
/// fast regardless of conversation size — turns are fetched lazily per
/// conversation in ConversationDetailViewModel.
@MainActor
final class ConversationListViewModel: ObservableObject {

    @Published var conversations: [ConversationRecord] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedFolderURL: URL?

    private let databaseReader: DatabaseReader
    private let folderAccessService: FolderAccessService

    init(
        databaseReader: DatabaseReader = DatabaseReader(),
        folderAccessService: FolderAccessService = FolderAccessService()
    ) {
        self.databaseReader = databaseReader
        self.folderAccessService = folderAccessService
    }

    /// Call this on app launch: tries to reuse a previously granted folder,
    /// otherwise leaves the list empty until the user chooses one.
    func restorePreviousFolderIfAvailable() {
        if let url = folderAccessService.resolvePreviouslyGrantedFolder() {
            selectedFolderURL = url
            loadConversations()
        }
    }

    /// Presents the folder picker so the user can grant access to a new folder.
    func chooseFolder() {
        guard let url = folderAccessService.promptUserToChooseFolder() else { return }
        selectedFolderURL = url
        loadConversations()
    }

    func loadConversations() {
        guard let folderURL = selectedFolderURL else {
            errorMessage = "No folder selected yet."
            return
        }

        isLoading = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            // Required for sandboxed access to a security-scoped bookmarked folder.
            let didStartAccessing = self.folderAccessService.startAccessing(folderURL)
            defer {
                if didStartAccessing {
                    self.folderAccessService.stopAccessing(folderURL)
                }
            }

            let files = self.databaseReader.findDatabaseFiles(inFolder: folderURL.path)

            if files.isEmpty {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "No .db files found in \(folderURL.path)"
                }
                return
            }

            var allConversations: [ConversationRecord] = []
            for file in files {
                allConversations.append(contentsOf: self.databaseReader.readConversationsMetadata(fromFile: file))
            }

            // Most recently active conversation first. Falls back to createdAt
            // for conversations that somehow have no updatedAt.
            allConversations.sort { lhs, rhs in
                let lhsDate = lhs.updatedAt ?? lhs.createdAt ?? .distantPast
                let rhsDate = rhs.updatedAt ?? rhs.createdAt ?? .distantPast
                return lhsDate > rhsDate
            }

            DispatchQueue.main.async {
                self.conversations = allConversations
                self.isLoading = false
            }
        }
    }
}
