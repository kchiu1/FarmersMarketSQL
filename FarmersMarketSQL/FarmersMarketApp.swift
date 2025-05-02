import SwiftUI

@main
struct FarmersMarketApp: App {
    @StateObject private var dataStore = MarketDataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
        }
    }
}
