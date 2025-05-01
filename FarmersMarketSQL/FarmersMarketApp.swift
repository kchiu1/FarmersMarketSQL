//  FarmersMarketApp.swift
//  FarmersMarket

import SwiftUI

@main
struct FarmersMarketApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}

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
                    .frame(width: 100)
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
            Task {
                do {
                    try await DatabaseManager.shared.connect(
                        host: "localhost",
                        port: 3306,
                        username: "farmappuser",
                        password: "your_password"
                    )

                    let loadedMarkets = try await DatabaseManager.shared.loadAllData()
                    markets = loadedMarkets
                    filteredMarkets = loadedMarkets
                } catch {
                    print("Error loading markets: \(error)")
                }
            }
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
                filteredMarkets = markets.filter { $0.city?.localizedCaseInsensitiveContains(searchText) ?? false }
            case .state:
                filteredMarkets = markets.filter { $0.state?.localizedCaseInsensitiveContains(searchText) ?? false }
            case .zip:
                filteredMarkets = markets.filter { $0.zip?.localizedCaseInsensitiveContains(searchText) ?? false }
            }
        }
    }
}

extension Market: Identifiable {
    var id: Int { fmid }
}

struct MarketRow: View {
    let market: Market

    var body: some View {
        VStack(alignment: .leading) {
            Text(market.name).font(.headline)
            Text("\(market.city ?? "Unknown"), \(market.state ?? "") \(market.zip ?? "")")
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
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct MarketDetailView: View {
    let market: Market

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(market.city ?? ""), \(market.state ?? "") \(market.zip ?? "")")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Divider()

                Text("Available Foods").font(.title2).bold()
                Text(market.products.map { $0.category }.joined(separator: ", "))

                Divider()

                Text("Payment Methods").font(.title2).bold()
                Text(market.payments.map { $0.rawValue }.joined(separator: ", "))

                Spacer()

                NavigationLink(destination: ReviewsView(market: market)) {
                    Text("View Reviews")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                NavigationLink(destination: AddReviewView(market: market)) {
                    Text("Write a Review")
                        .font(.headline)
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

struct ReviewsView: View {
    let market: Market
    @State private var reviews: [Review] = []

    var body: some View {
        List(reviews, id: \.reviewer) { review in
            VStack(alignment: .leading) {
                Text(review.reviewer).font(.headline)
                Text(review.comment)
                HStack {
                    ForEach(0..<review.stars, id: \.self) { _ in
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                    }
                }
            }
        }
        .navigationTitle("Reviews")
        .onAppear {
            reviews = market.reviews
        }
    }
}

struct AddReviewView: View {
    let market: Market
    @State private var reviewerName = ""
    @State private var comment = ""
    @State private var rating = 0

    var body: some View {
        Form {
            TextField("Your Name", text: $reviewerName)
            TextField("Your Review", text: $comment)
            Stepper("Rating: \(rating)", value: $rating, in: 0...5)
            Button("Submit Review") {
                print("Review: \(reviewerName), \(comment), \(rating) stars")
            }
        }
        .navigationTitle("Write a Review")
    }
}
