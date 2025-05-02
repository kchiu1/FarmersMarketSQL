import SwiftUI

struct SearchView: View {
    @ObservedObject var dataStore: MarketDataStore
    @State private var searchText = ""
    @State private var searchFilter: SearchFilter = .name
    
    enum SearchFilter: String, CaseIterable {
        case name = "Name"
        case city = "City"
        case state = "State"
        case zip = "ZIP Code"
    }
    
    var filteredMarkets: [Market] {
        if searchText.isEmpty {
            return dataStore.markets
        }
        
        let lowercasedSearch = searchText.lowercased()
        
        switch searchFilter {
        case .name:
            return dataStore.markets.filter { $0.name.lowercased().contains(lowercasedSearch) }
        case .city:
            return dataStore.markets.filter { $0.city?.lowercased().contains(lowercasedSearch) ?? false }
        case .state:
            return dataStore.markets.filter { $0.state?.lowercased().contains(lowercasedSearch) ?? false }
        case .zip:
            return dataStore.markets.filter { $0.zip?.lowercased().contains(lowercasedSearch) ?? false }
        }
    }
    
    var body: some View {
        List {
            Picker("Filter", selection: $searchFilter) {
                ForEach(SearchFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            ForEach(filteredMarkets) { market in
                NavigationLink {
                    MarketDetailView(market: market)
                        .environmentObject(dataStore)
                } label: {
                    MarketRow(market: market)
                }
                .onAppear {
                    Task {
                        await dataStore.loadMoreDataIfNeeded(for: market)
                    }
                }
            }
            
            if dataStore.isLoading && !dataStore.markets.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Farmers Markets")
        .searchable(text: $searchText)
        .overlay {
            if dataStore.isLoading && dataStore.markets.isEmpty {
                ProgressView()
            } else if filteredMarkets.isEmpty && !dataStore.isLoading {
                Text("No markets found")
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await dataStore.loadInitialData()
        }
        .refreshable {
            await dataStore.loadInitialData()
        }
    }
}
