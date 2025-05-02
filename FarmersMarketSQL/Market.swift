//
//  Market.swift
//  FarmersMarketSQL
//
//  Created by Kyle Chiu on 4/30/25.
//


import Foundation

struct Market: Identifiable {
    let fmid: Int
    let name: String
    let street: String?
    let city: String?
    let county: String?
    let state: String?
    let zip: String?
    let latitude: Double?
    let longitude: Double?

    var website: String?
    var facebook: String?
    var twitter: String?
    var youtube: String?
    var otherMedia: String?

    var seasons: [Season]
    var payments: [PaymentType]
    var products: [Product]
    var location: Location?
    
    var id: Int { fmid }
}

extension Market {
    var fullAddress: String? {
        var components = [String]()
        if let street = street { components.append(street) }
        if let city = city { components.append(city) }
        if let state = state { components.append(state) }
        if let zip = zip { components.append(zip) }
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

struct Season {
    let seasonNumber: Int
    let dates: String
    let hours: String
}

enum PaymentType: String, CaseIterable {
    case credit = "Credit"
    case wic = "WIC"
    case wicCash = "WICcash"
    case sfmnp = "SFMNP"
    case snap = "SNAP"
}

struct Product {
    let category: String
    let isOrganic: Bool
}

struct Location {
    let zip: String
    let latitude: Double
    let longitude: Double
    let city: String
    let state: String
    let county: String
}