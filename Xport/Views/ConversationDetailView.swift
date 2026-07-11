import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ConversationDetailView: View {
    let conversation: ConversationRecord
    let folderURL: URL?

    @StateObject private var viewModel = ConversationDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.title)
                        .font(.title2)
                        .bold()
                    Text("Created: \(conversation.createdAtDisplay)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Updated: \(conversation.updatedAtDisplay)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                if viewModel.isLoadingTurns {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading conversation…")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 40)
                        Spacer()
                    }
                } else if let error = viewModel.loadErrorMessage {
                    Text(error)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(viewModel.turns) { turn in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(turn.role.displayLabel)
                                .font(.subheadline)
                                .bold()
                            MessageContentView(text: turn.text)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(turn.role == .user ? Color.blue.opacity(0.08) : Color.gray.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding()
        }
        .navigationTitle(conversation.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.exportConversation(conversation)
                } label: {
                    if viewModel.isExporting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
                .disabled(viewModel.isExporting || viewModel.isLoadingTurns || viewModel.turns.isEmpty)
            }
        }
        .textSelection(.enabled)
        .alert(
            "Export Failed",
            isPresented: Binding(
                get: { viewModel.exportErrorMessage != nil },
                set: { if !$0 { viewModel.exportErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.exportErrorMessage ?? "")
        }
        .overlay(alignment: .bottom) {
            if let url = viewModel.lastExportedURL {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Saved to \(url.lastPathComponent)")
                        .font(.footnote)
                    Button("Show in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                    .font(.footnote)
                }
                .padding(8)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .task {
                    try? await Task.sleep(for: .seconds(4))
                    withAnimation { viewModel.lastExportedURL = nil }
                }
            }
        }
        .animation(.default, value: viewModel.lastExportedURL)
        // `.task(id:)` re-runs whenever conversation.id changes, and — critically —
        // automatically cancels the previous invocation first. That's what fixes
        // rapid conversation-switching: tapping a new title cancels the in-flight
        // load for the old one instead of letting both run and pile up memory.
        .task(id: conversation.id) {
            await viewModel.loadTurns(for: conversation, folderURL: folderURL)
        }
    }
}
