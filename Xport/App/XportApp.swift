import SwiftUI

@main
struct XportApp: App {
    // EDIT THIS PATH to point at the folder containing your .db files
    let folderPath = "/Users/kcd/.config/github-copilot/xcode/9e6ad031f935b715/conversations"

    var body: some Scene {
        WindowGroup {
            ConversationListView()
//            ContentView(folderPath: folderPath)
        }
    }
}
