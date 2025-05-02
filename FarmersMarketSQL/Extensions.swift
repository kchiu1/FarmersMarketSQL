//
//  Extensions.swift
//  FarmersMarketSQL
//
//  Created by Kyle Chiu on 4/30/25.
//

extension Location {
    var distanceString: String {
        // In a real app, you'd calculate distance from current location
        "\(String(format: "%.2f", latitude)), \(String(format: "%.2f", longitude))"
    }
}
