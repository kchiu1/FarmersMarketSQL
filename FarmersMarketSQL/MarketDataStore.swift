import SwiftUI

@MainActor
class MarketDataStore: ObservableObject {
    @Published var markets: [Market] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMoreData = true
    @Published var loadingDetailsFor: Set<Int> = []
    
    private var currentPage = 0
    private let pageSize = 20
    
    func loadInitialData() async {
        guard !isLoading, markets.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        currentPage = 0
        
        do {
            try await DatabaseManager.shared.connect()
            let firstPage = try await DatabaseManager.shared.loadMarkets(page: currentPage, pageSize: pageSize)
            markets = firstPage
            hasMoreData = !firstPage.isEmpty
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func loadMoreDataIfNeeded(for market: Market? = nil) async {
        guard !isLoading, hasMoreData else { return }
        
        if let market = market,
           let lastIndex = markets.lastIndex(where: { $0.id == market.id }),
           markets.count - lastIndex > 5 {
            return
        }
        
        isLoading = true
        currentPage += 1
        
        do {
            let newMarkets = try await DatabaseManager.shared.loadMarkets(page: currentPage, pageSize: pageSize)
            if newMarkets.isEmpty {
                hasMoreData = false
            } else {
                markets.append(contentsOf: newMarkets)
            }
        } catch {
            errorMessage = error.localizedDescription
            currentPage -= 1
        }
        isLoading = false
    }
    
    func loadMarketDetails(for market: Market) async -> Market {
        // Check if we already have this market with details
        if let existing = markets.first(where: { $0.fmid == market.fmid &&
            !$0.seasons.isEmpty && !$0.payments.isEmpty && !$0.products.isEmpty }) {
            return existing
        }
        
        // Prevent duplicate loading
        guard !loadingDetailsFor.contains(market.fmid) else { return market }
        loadingDetailsFor.insert(market.fmid)
        
        var detailedMarket = market
        do {
            try await DatabaseManager.shared.loadAdditionalData(for: &detailedMarket)
            
            // Update the markets array with the new details
            if let index = markets.firstIndex(where: { $0.fmid == market.fmid }) {
                markets[index] = detailedMarket
            }
            
            loadingDetailsFor.remove(market.fmid)
            return detailedMarket
        } catch {
            print("Error loading market details: \(error.localizedDescription)")
            loadingDetailsFor.remove(market.fmid)
            return market
        }
    }
}
