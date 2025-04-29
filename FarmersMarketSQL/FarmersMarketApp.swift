//
//  FarmersMarketApp.swift
//  FarmersMarketSQL
//
//  Created by Kyle Chiu on 4/28/25.
//

import SwiftUI

@main
struct FarmersMarketApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}

// MARK: - HomeView

struct HomeView: View {
    @State private var searchText = ""
    @State private var searchType: SearchType = .name
    @State private var markets: [Market] = []
    @State private var filteredMarkets: [Market] = []

    enum SearchType: String, CaseIterable {
        case name = "Name"
        case city = "City"
        case state = "State"
        case zip = "Zip"
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    SearchBar(text: $searchText, placeholder: "Search markets")
                    
                    Picker("Search Type", selection: $searchType) {
                        ForEach(SearchType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)
                    .padding(.trailing, 8)
                }
                .padding()

                List(filteredMarkets) { market in
                    NavigationLink(destination: MarketDetailView(market: market)) {
                        MarketRow(market: market)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Farmers Markets")
        }
        .onChange(of: searchText) { _ in filterMarkets() }
        .onChange(of: searchType) { _ in filterMarkets() }
        .onAppear {
            loadMarkets()
        }
    }

    private func filterMarkets() {
        if searchText.isEmpty {
            filteredMarkets = markets
        } else {
            switch searchType {
            case .name:
                filteredMarkets = markets.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            case .city:
                filteredMarkets = markets.filter { $0.city.localizedCaseInsensitiveContains(searchText) }
            case .state:
                filteredMarkets = markets.filter { $0.state.localizedCaseInsensitiveContains(searchText) }
            case .zip:
                filteredMarkets = markets.filter { $0.zip.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }

    private func loadMarkets() {
        // TODO: Replace this with real API call
        self.markets = [
            Market(id: 1, name: "Market 1", city: "City 1", state: "State 1", zip: "12345"),
            Market(id: 2, name: "Market 2", city: "City 2", state: "State 2", zip: "67890"),
            Market(id: 3, name: "Market 3", city: "City 3", state: "State 3", zip: "10112"),
            Market(id: 4, name: "Market 4", city: "City 4", state: "State 4", zip: "13145"),
        ]
        self.filteredMarkets = self.markets
    }
}

// MARK: - Components

struct MarketRow: View {
    let market: Market

    var body: some View {
        VStack(alignment: .leading) {
            Text(market.name)
                .font(.headline)
            Text("\(market.city), \(market.state) \(market.zip)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct Market: Identifiable, Codable {
    let id: Int
    let name: String
    let city: String
    let state: String
    let zip: String
}

// MARK: - Detail Views

struct MarketDetailView: View {
    let market: Market

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(market.city), \(market.state) \(market.zip)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Divider()

                Text("Available Foods")
                    .font(.title2)
                    .bold()
                Text("Baked goods, Cheese, Crafts, Flowers, Eggs, Seafood, Herbs, Vegetables, Honey, etc.")
                    .font(.body)

                Divider()

                Text("Payment Methods")
                    .font(.title2)
                    .bold()
                Text("Credit, WIC, WICcash, SFMNP, SNAP")
                    .font(.body)

                Divider()

                NavigationLink(destination: ReviewsView(market: market)) {
                    Text("View Reviews")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                NavigationLink(destination: AddReviewView(market: market)) {
                    Text("Write a Review")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle(market.name)
    }
}

// Dummy Views
struct ReviewsView: View {
    let market: Market
    var body: some View {
        Text("Reviews for \(market.name)")
    }
}

struct AddReviewView: View {
    let market: Market
    var body: some View {
        Text("Write a Review for \(market.name)")
    }
}


// Preview for HomeView
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
