//
//  MarketRow.swift
//  FarmersMarketSQL
//
//  Created by Kyle Chiu on 4/30/25.
//


import SwiftUI

struct MarketRow: View {
    let market: Market
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(market.name)
                .font(.headline)
            
            if let city = market.city, let state = market.state {
                Text("\(city), \(state)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let distance = market.location?.distanceString {
                Text(distance)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}