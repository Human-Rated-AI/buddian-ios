import SwiftUI

@main
struct BuddianApp: App {
    @StateObject private var modelCache = ModelCache.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelCache)
        }
    }
}
