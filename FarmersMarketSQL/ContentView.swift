//
//  ContentView.swift
//  FarmersMarketSQL
//
//  Created by Kyle Chiu on 4/29/25.
//


import SwiftUI

struct ContentView: View {
    @State private var markets: [Market] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    ProgressView()
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else {
                    ForEach(markets, id: \.fmid) { market in
                        VStack(alignment: .leading) {
                            Text(market.name)
                                .font(.headline)
                            Text("\(market.city ?? ""), \(market.state ?? "")")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Farmers Markets")
            .task {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await DatabaseManager.shared.connect()
            markets = try await DatabaseManager.shared.loadAllData()
        } catch {
            errorMessage = error.localizedDescription
            print("Error loading data: \(error)")
        }
        
        isLoading = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
