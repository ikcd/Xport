//
//  FolderAccessService.swift
//  Xport
//
//  Created by kcd on 04/07/26.
//


import Foundation
import AppKit

/// Handles sandbox-safe folder access: lets the user pick a folder via NSOpenPanel,
/// and persists that permission across app launches using a security-scoped bookmark.
/// This is required because a sandboxed app cannot read arbitrary hardcoded paths —
/// it can only read paths the user has explicitly granted access to.
final class FolderAccessService {

    private let bookmarkKey = "ConversationReader.folderBookmark"

    /// Presents a folder picker to the user and stores a security-scoped bookmark
    /// for the chosen folder so we can re-access it on future launches.
    func promptUserToChooseFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        panel.message = "Choose the folder containing your .db files"

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        saveBookmark(for: url)
        return url
    }

    /// Attempts to resolve a previously saved bookmark. Returns nil if none exists
    /// or if the bookmark is stale (e.g. the folder moved or was deleted).
    func resolvePreviouslyGrantedFolder() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return nil
        }

        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }

        if isStale {
            // Re-save a fresh bookmark if the old one is stale but the folder is still valid.
            saveBookmark(for: url)
        }

        return url
    }

    /// Must be called before reading files inside a security-scoped URL,
    /// and matched with `stopAccessing` when done.
    @discardableResult
    func startAccessing(_ url: URL) -> Bool {
        url.startAccessingSecurityScopedResource()
    }

    func stopAccessing(_ url: URL) {
        url.stopAccessingSecurityScopedResource()
    }

    // MARK: - Private

    private func saveBookmark(for url: URL) {
        guard let bookmarkData = try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }

        UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
    }
}
