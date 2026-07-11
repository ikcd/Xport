//
//  ContentView.swift
//  Xport
//
//  Created by kcd on 04/07/26.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var viewModel: ConversationListViewModel

    init(folderPath: String) {
        _viewModel = StateObject(wrappedValue: ConversationListViewModel())
    }
    
//    let conversation: ConversationRecord
    @State private var selectedOption = "Copilot for Xcode"
    @State private var fileLocation = "/Applications/Xcode.app"

    private let defaultLocations: [String: String] = [
        "Copilot for Xcode": "/Users/<UserName>/.config/github-copilot/xcode/9e6ad031f935b715/conversations",
        "Copilot for VS Code": "/Applications/Visual Studio Code.app",
        "Copilot for IntelliJ": "/Applications/IntelliJ IDEA.app"
    ]

    var body: some View {
        NavigationSplitView {
            List {
                Label("Home", systemImage: "house")
                Label("Search", systemImage: "magnifyingglass")
                Label("Settings", systemImage: "gear")
            }
            .navigationTitle("Menu")

        } detail: {
            VStack(alignment: .leading, spacing: 20) {

                // Top Bar
                HStack(spacing: 12) {

                    Menu {
                        Button("Copilot for Xcode") {
                            selectedOption = "Copilot for Xcode"
                            fileLocation = defaultLocations[selectedOption]!
                        }

                        Button("Copilot for VS Code") {}
                            .disabled(true)

                        Button("Copilot for IntelliJ") {}
                            .disabled(true)

                    } label: {
                        HStack(spacing: 6) {
                            Text(selectedOption)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    TextField("File Location", text: $fileLocation)
                        .textFieldStyle(.roundedBorder)
                        .overlay(alignment: .trailing) {
                            if !fileLocation.isEmpty {
                                Button {
                                    fileLocation = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, 8)
                            }
                        }

                }
                
                Spacer()
                
                
            }
            .padding()
        }
    }
}


#Preview {
    ContentView(folderPath: "")
}
