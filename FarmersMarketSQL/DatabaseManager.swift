import MySQLNIO
import NIOCore
import Foundation

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private var connection: MySQLConnection?
    private let lock = NSLock()
    private var isConnected = false
    
    private init() {}

    // MARK: - Connection Management
    
    func connect(
        host: String = "localhost",
        port: Int = 3306,
        username: String = "farmappuser",
        password: String = "your_password",
        database: String = "farmersmarkets"
    ) async throws {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isConnected else { return }
        
        do {
            let newConnection = try await MySQLConnection.connect(
                to: .makeAddressResolvingHost(host, port: port),
                username: username,
                database: database,
                password: password,
                tlsConfiguration: nil,
                on: eventLoopGroup.next()
            ).get()
            
            self.connection = newConnection
            self.isConnected = true
        } catch {
            self.isConnected = false
            throw DatabaseError.connectionFailed("Failed to connect: \(error.localizedDescription)")
        }
    }

    func disconnect() {
        lock.lock()
        defer { lock.unlock() }
        
        guard isConnected else { return }
        
        do {
            try connection?.close().wait()
            connection = nil
            isConnected = false
        } catch {
            print("Error disconnecting: \(error.localizedDescription)")
        }
    }
    
    deinit {
        disconnect()
    }

    // MARK: - Market Data Loading
    
    func loadMarkets(page: Int, pageSize: Int) async throws -> [Market] {
        guard isConnected else {
            throw DatabaseError.notConnected
        }
        
        let offset = page * pageSize
        let query = """
        SELECT i.fmid, i.name, i.street, i.city, i.county, i.state, i.zip, 
               i.x as latitude, i.y as longitude
        FROM FMInfo i
        ORDER BY i.name
        LIMIT ? OFFSET ?
        """
        
        do {
            let rows = try await connection!.query(query, [
                .init(int: pageSize),
                .init(int: offset)
            ]).get()
            
            var markets: [Market] = []
            for row in rows {
                guard let fmid = row.column("fmid")?.int,
                      let name = row.column("name")?.string else {
                    continue
                }
                
                let market = Market(
                    fmid: fmid,
                    name: name,
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
                    location: nil
                )
                markets.append(market)
            }
            return markets
        } catch {
            throw DatabaseError.queryFailed("Market query failed: \(error.localizedDescription)")
        }
    }
    
    func loadAdditionalData(for market: inout Market) async throws {
        guard isConnected else {
            throw DatabaseError.notConnected
        }
        
        async let media = loadMedia(for: market.fmid)
        async let seasons = loadSeasons(for: market.fmid)
        async let payments = loadPayments(for: market.fmid)
        async let products = loadProducts(for: market.fmid)
        async let location = loadLocation(for: market.zip)

        do {
            let (mediaResults, seasons, payments, products, location) = try await (media, seasons, payments, products, location)
            
            market.website = mediaResults.website
            market.facebook = mediaResults.facebook
            market.twitter = mediaResults.twitter
            market.youtube = mediaResults.youtube
            market.otherMedia = mediaResults.otherMedia
            market.seasons = seasons
            market.payments = payments
            market.products = products
            market.location = location
        } catch {
            print("Error loading additional data for market \(market.fmid): \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Detailed Data Loading
    
    private func loadMedia(for fmid: Int) async throws -> (
        website: String?, facebook: String?, twitter: String?, youtube: String?, otherMedia: String?
    ) {
        let query = "SELECT media, url FROM FMMedia WHERE fmid = ?"
        
        do {
            let rows = try await connection!.query(query, [
                .init(int: fmid)
            ]).get()
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
        } catch {
            throw DatabaseError.queryFailed("Media query failed: \(error.localizedDescription)")
        }
    }

    private func loadSeasons(for fmid: Int) async throws -> [Season] {
        let query = "SELECT season, dates, hours FROM FMOpen WHERE fmid = ? ORDER BY season"
        
        do {
            let rows = try await connection!.query(query, [
                .init(int: fmid)
            ]).get()
            var seasons: [Season] = []
            
            for row in rows {
                guard let season = row.column("season")?.int,
                      let dates = row.column("dates")?.string,
                      let hours = row.column("hours")?.string else {
                    continue
                }
                seasons.append(Season(seasonNumber: season, dates: dates, hours: hours))
            }
            return seasons
        } catch {
            throw DatabaseError.queryFailed("Seasons query failed: \(error.localizedDescription)")
        }
    }

    private func loadPayments(for fmid: Int) async throws -> [PaymentType] {
        let query = "SELECT type FROM FMPayment WHERE fmid = ?"
        
        do {
            let rows = try await connection!.query(query, [
                .init(int: fmid)
            ]).get()
            var payments: [PaymentType] = []
            
            for row in rows {
                guard let typeString = row.column("type")?.string,
                      let paymentType = PaymentType(rawValue: typeString) else {
                    continue
                }
                payments.append(paymentType)
            }
            return payments
        } catch {
            throw DatabaseError.queryFailed("Payments query failed: \(error.localizedDescription)")
        }
    }

    private func loadProducts(for fmid: Int) async throws -> [Product] {
        let query = """
        SELECT c.name as category, 
               EXISTS(SELECT 1 FROM FMProduct p2 
                      WHERE p2.fmid = ? AND p2.categoryid = 29) as isOrganic
        FROM FMProduct p
        JOIN FMCategory c ON p.categoryid = c.id
        WHERE p.fmid = ?
        """
        
        do {
            let rows = try await connection!.query(query, [
                .init(int: fmid),
                .init(int: fmid)
            ]).get()
            
            var products: [Product] = []
            for row in rows {
                guard let category = row.column("category")?.string,
                      let isOrganic = row.column("isOrganic")?.bool else {
                    continue
                }
                products.append(Product(category: category, isOrganic: isOrganic))
            }
            return products
        } catch {
            throw DatabaseError.queryFailed("Products query failed: \(error.localizedDescription)")
        }
    }

    private func loadLocation(for zip: String?) async throws -> Location? {
        guard let zip = zip else { return nil }
        
        let query = """
        SELECT latitude, longitude, city, state, county 
        FROM Location WHERE zip = ?
        LIMIT 1
        """
        
        do {
            let rows = try await connection!.query(query, [
                .init(string: zip)
            ]).get()
            guard let row = rows.first else { return nil }
            
            guard let latitude = row.column("latitude")?.double,
                  let longitude = row.column("longitude")?.double,
                  let city = row.column("city")?.string,
                  let state = row.column("state")?.string,
                  let county = row.column("county")?.string else {
                return nil
            }
            
            return Location(
                zip: zip,
                latitude: latitude,
                longitude: longitude,
                city: city,
                state: state,
                county: county
            )
        } catch {
            throw DatabaseError.queryFailed("Location query failed: \(error.localizedDescription)")
        }
    }
}

enum DatabaseError: Error {
    case notConnected
    case connectionFailed(String)
    case queryFailed(String)
    case invalidData(String)
    
    var localizedDescription: String {
        switch self {
        case .notConnected:
            return "Not connected to database"
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}
