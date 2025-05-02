import SwiftUI

struct ContentView: View {
    @StateObject private var dataStore = MarketDataStore()
    
    var body: some View {
        NavigationView {
            SearchView(dataStore: dataStore)
                .environmentObject(dataStore)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
