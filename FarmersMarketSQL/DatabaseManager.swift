import MySQLNIO
import NIOCore
import Foundation

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private var connection: MySQLConnection?
    
    private var allMarkets: [Market] = []
    
    private init() {}

    // MARK: - Connection

    func connect(
        host: String = "localhost",
        port: Int = 3306,
        username: String = "farmappuser",
        password: String = "your_password",
        database: String = "farmersmarkets"
    ) async throws {
        self.connection = try await MySQLConnection.connect(
            to: .makeAddressResolvingHost(host, port: port),
            username: username,
            database: database,
            password: password,
            tlsConfiguration: nil, // explicitly disable SSL/TLS
            on: eventLoopGroup.next()
        ).get()
    }

    // MARK: - Data Loading

    func loadAllData() async throws -> [Market] {
        guard let connection = connection else {
            throw DatabaseError.notConnected
        }

        let markets = try await loadMarkets(connection: connection)
        allMarkets = markets

        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in allMarkets.indices {
                group.addTask { [self] in
                    try await loadAdditionalData(for: &allMarkets[index], connection: connection)
                }
            }
            try await group.waitForAll()
        }

        return allMarkets
    }

    private func loadMarkets(connection: MySQLConnection) async throws -> [Market] {
        let query = """
        SELECT i.fmid, i.name, i.street, i.city, i.county, i.state, i.zip, 
               i.x as latitude, i.y as longitude
        FROM FMInfo i
        """

        let rows = try await connection.query(query).get()

        return rows.map { row in
            Market(
                fmid: row.column("fmid")?.int ?? 0,
                name: row.column("name")?.string ?? "Unknown Market",
                street: row.column("street")?.string,
                city: row.column("city")?.string,
                county: row.column("county")?.string,
                state: row.column("state")?.string,
                zip: row.column("zip")?.string,
                latitude: row.column("latitude")?.double,
                longitude: row.column("longitude")?.double,
                website: nil,
                facebook: nil,
                twitter: nil,
                youtube: nil,
                otherMedia: nil,
                seasons: [],
                payments: [],
                products: [],
                reviews: [],
                location: nil
            )
        }
    }

    private func loadAdditionalData(for market: inout Market, connection: MySQLConnection) async throws {
        async let media = loadMedia(for: market.fmid, connection: connection)
        async let seasons = loadSeasons(for: market.fmid, connection: connection)
        async let payments = loadPayments(for: market.fmid, connection: connection)
        async let products = loadProducts(for: market.fmid, connection: connection)
        async let reviews = loadReviews(for: market.fmid, connection: connection)
        async let location = loadLocation(for: market.zip, connection: connection)

        let mediaResults = try await media
        market.website = mediaResults.website
        market.facebook = mediaResults.facebook
        market.twitter = mediaResults.twitter
        market.youtube = mediaResults.youtube
        market.otherMedia = mediaResults.otherMedia

        market.seasons = try await seasons
        market.payments = try await payments
        market.products = try await products
        market.reviews = try await reviews
        market.location = try await location
    }

    // MARK: - Detail Loading Functions

    private func loadMedia(for fmid: Int, connection: MySQLConnection) async throws -> (
        website: String?, facebook: String?, twitter: String?, youtube: String?, otherMedia: String?
    ) {
        let query = "SELECT media, url FROM FMMedia WHERE fmid = ?"
        let rows = try await connection.query(query, [MySQLData(string: String(fmid))]).get()

        var result: (String?, String?, String?, String?, String?) = (nil, nil, nil, nil, nil)

        for row in rows {
            guard let media = row.column("media")?.string,
                  let url = row.column("url")?.string else { continue }

            switch media.lowercased() {
            case "website": result.0 = url
            case "facebook": result.1 = url
            case "twitter": result.2 = url
            case "youtube": result.3 = url
            default: result.4 = url
            }
        }

        return result
    }

    private func loadSeasons(for fmid: Int, connection: MySQLConnection) async throws -> [Season] {
        let query = "SELECT season, dates, hours FROM FMOpen WHERE fmid = ? ORDER BY season"
        let rows = try await connection.query(query, [MySQLData(string: String(fmid))]).get()

        return rows.compactMap { row in
            guard let season = row.column("season")?.int,
                  let dates = row.column("dates")?.string,
                  let hours = row.column("hours")?.string else {
                return nil
            }
            return Season(seasonNumber: season, dates: dates, hours: hours)
        }
    }

    private func loadPayments(for fmid: Int, connection: MySQLConnection) async throws -> [PaymentType] {
        let query = "SELECT type FROM FMPayment WHERE fmid = ?"
        let rows = try await connection.query(query, [MySQLData(string: String(fmid))]).get()

        return rows.compactMap { row in
            guard let typeString = row.column("type")?.string else { return nil }
            return PaymentType(rawValue: typeString)
        }
    }

    private func loadProducts(for fmid: Int, connection: MySQLConnection) async throws -> [Product] {
        let query = """
        SELECT c.name as category, 
               EXISTS(SELECT 1 FROM FMProduct p2 
                      WHERE p2.fmid = ? AND p2.categoryid = 29) as isOrganic
        FROM FMProduct p
        JOIN FMCategory c ON p.categoryid = c.id
        WHERE p.fmid = ?
        """
        let fmidData = MySQLData(string: String(fmid))
        let rows = try await connection.query(query, [fmidData, fmidData]).get()

        return rows.compactMap { row in
            guard let category = row.column("category")?.string,
                  let isOrganic = row.column("isOrganic")?.bool else {
                return nil
            }
            return Product(category: category, isOrganic: isOrganic)
        }
    }

    private func loadReviews(for fmid: Int, connection: MySQLConnection) async throws -> [Review] {
        let query = "SELECT reviewer, comment, stars FROM FMReview WHERE fmid = ?"
        let rows = try await connection.query(query, [MySQLData(string: String(fmid))]).get()

        return rows.compactMap { row in
            guard let reviewer = row.column("reviewer")?.string,
                  let comment = row.column("comment")?.string,
                  let stars = row.column("stars")?.int else {
                return nil
            }
            return Review(reviewer: reviewer, comment: comment, stars: stars, date: nil)
        }
    }

    private func loadLocation(for zip: String?, connection: MySQLConnection) async throws -> Location? {
        guard let zip = zip else { return nil }
        let query = """
        SELECT latitude, longitude, city, state, county 
        FROM Location WHERE zip = ?
        LIMIT 1
        """
        let rows = try await connection.query(query, [MySQLData(string: zip)]).get()

        guard let row = rows.first,
              let latitude = row.column("latitude")?.double,
              let longitude = row.column("longitude")?.double,
              let city = row.column("city")?.string,
              let state = row.column("state")?.string,
              let county = row.column("county")?.string else {
            return nil
        }

        return Location(zip: zip, latitude: latitude, longitude: longitude,
                        city: city, state: state, county: county)
    }

    // MARK: - Public Access

    func getAllMarkets() -> [Market] {
        return allMarkets
    }

    func getMarket(by fmid: Int) -> Market? {
        return allMarkets.first { $0.fmid == fmid }
    }

    // MARK: - Cleanup

    func disconnect() {
        try? connection?.close().wait()
        try? eventLoopGroup.syncShutdownGracefully()
    }
}

enum DatabaseError: Error {
    case notConnected
    case queryFailed
    case invalidData
}

// Supporting Models

struct Market {
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
    var reviews: [Review]
    var location: Location?
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

struct Review {
    let reviewer: String
    let comment: String
    let stars: Int
    let date: Date?
}

struct Location {
    let zip: String
    let latitude: Double
    let longitude: Double
    let city: String
    let state: String
    let county: String
}
