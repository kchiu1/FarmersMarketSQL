import SwiftUI

struct MarketDetailView: View {
    @EnvironmentObject var dataStore: MarketDataStore
    let market: Market
    
    @State private var isLoadingDetails = false
    @State private var detailedMarket: Market?
    
    var displayMarket: Market {
        detailedMarket ?? market
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoadingDetails {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
                
                // Header Section
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayMarket.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let address = displayMarket.fullAddress {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
                
                Divider()
                
                // Show sections only if we have details
                if detailedMarket != nil {
                    // Seasonal Hours Section
                    if !displayMarket.seasons.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Seasonal Hours")
                                .font(.headline)
                            
                            ForEach(displayMarket.seasons, id: \.seasonNumber) { season in
                                VStack(alignment: .leading) {
                                    Text("Season \(season.seasonNumber)")
                                        .fontWeight(.semibold)
                                    Text(season.dates)
                                    Text(season.hours)
                                }
                                .padding(.bottom, 8)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Products Section
                    if !displayMarket.products.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Products Available")
                                .font(.headline)
                            
                            Text(displayMarket.products.map { $0.category }.joined(separator: ", "))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Payment Methods Section
                    if !displayMarket.payments.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Payment Methods")
                                .font(.headline)
                            
                            Text(displayMarket.payments.map { $0.rawValue }.joined(separator: ", "))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Website Link
                    if let website = displayMarket.website {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Website")
                                .font(.headline)
                            
                            Link(website, destination: URL(string: website)!)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                } else {
                    Text("Loading market details...")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Market Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isLoadingDetails = true
            detailedMarket = await dataStore.loadMarketDetails(for: market)
            isLoadingDetails = false
        }
    }
}
