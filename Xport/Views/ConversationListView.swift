import SwiftUI

struct ConversationListView: View {
    @StateObject private var viewModel = ConversationListViewModel()

    var body: some View {
        NavigationSplitView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading conversations…")
                } else if viewModel.selectedFolderURL == nil {
                    ContentUnavailableView {
                        Label("No Folder Selected", systemImage: "folder.badge.questionmark")
                    } description: {
                        Text("Choose a folder containing your .db files to get started.")
                    } actions: {
                        Button("Choose Folder…") {
                            viewModel.chooseFolder()
                        }
                    }
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    List(viewModel.conversations) { conversation in
                        NavigationLink {
                            ConversationDetailView(conversation: conversation, folderURL: viewModel.selectedFolderURL)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(conversation.title)
                                    .font(.headline)
                                Text("Updated: \(conversation.updatedAtDisplay)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Conversations")
            .toolbar {
                ToolbarItem {
                    Button {
                        viewModel.chooseFolder()
                    } label: {
                        Label("Choose Folder", systemImage: "folder")
                    }
                }
                ToolbarItem {
                    Button {
                        viewModel.loadConversations()
                    } label: {
                        Label("Reload", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.selectedFolderURL == nil)
                }
            }
        } detail: {
            Text("Select a conversation")
                .foregroundStyle(.secondary)
        }
        .onAppear {
            viewModel.restorePreviousFolderIfAvailable()
        }
    }
}

#Preview {
    ConversationListView()
}
