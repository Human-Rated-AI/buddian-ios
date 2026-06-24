import SwiftUI

@main
struct BuddianApp: App {
    @StateObject private var modelCache = ModelCache.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await modelCache.refresh()
                }
                .environmentObject(modelCache)
        }
    }
}
