import Foundation
import CoreLocation

/// Decodes the Overpass API JSON
private struct OverpassResponse: Codable {
    struct Element: Codable {
        let tags: [String: String]?
    }
    let elements: [Element]
}

/// Cached speed limit entry
private struct CachedSpeedLimit {
    let speedLimit: Double?
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    
    func isValid(for newCoordinate: CLLocationCoordinate2D, cacheLifetime: TimeInterval = 300) -> Bool {
        // Check if cache is fresh (within 5 minutes)
        guard Date().timeIntervalSince(timestamp) < cacheLifetime else { return false }
        
        // Check if new location is within 50 meters of cached location
        let cachedLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let newLocation = CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)
        return cachedLocation.distance(from: newLocation) < 50
    }
}

/// Fetches the posted speed-limit (mph) at a given coord via OpenStreetMap/Overpass with intelligent caching
@MainActor
enum SpeedLimitService {
    // Thread-safe cache
    private static var cache: CachedSpeedLimit?
    private static var pendingRequest: Task<Double?, Error>?
    
    static func fetchSpeedLimit(for coordinate: CLLocationCoordinate2D) async throws -> Double? {
        // Return cached value if valid
        if let cached = cache, cached.isValid(for: coordinate) {
            return cached.speedLimit
        }
        
        // If there's already a pending request, wait for it
        if let pending = pendingRequest {
            return try await pending.value
        }
        
        // Create new request
        let task = Task<Double?, Error> {
            defer { pendingRequest = nil }
            
            let speedLimit = try await performFetch(for: coordinate)
            
            // Cache the result
            cache = CachedSpeedLimit(
                speedLimit: speedLimit,
                coordinate: coordinate,
                timestamp: Date()
            )
            
            return speedLimit
        }
        
        pendingRequest = task
        return try await task.value
    }
    
    private static func performFetch(for coordinate: CLLocationCoordinate2D) async throws -> Double? {
        // Optimized query with smaller radius (20m) and timeout
        let query = """
        [out:json][timeout:3];
        way(around:20,\(coordinate.latitude),\(coordinate.longitude))["maxspeed"];
        out tags;
        """
        
        guard let esc = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://overpass-api.de/api/interpreter?data=\(esc)")
        else { return nil }
        
        // Configure URLSession for performance
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 3.0  // 3 second timeout
        config.timeoutIntervalForResource = 5.0
        config.waitsForConnectivity = false
        config.requestCachePolicy = .returnCacheDataElseLoad
        
        let session = URLSession(configuration: config)
        
        do {
            let (data, response) = try await session.data(from: url)
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            
            let resp = try JSONDecoder().decode(OverpassResponse.self, from: data)
            
            for element in resp.elements {
                if let s = element.tags?["maxspeed"] {
                    return parseSpeedLimit(from: s)
                }
            }
            return nil
        } catch {
            // Log error but don't crash
            print("Speed limit fetch error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private static func parseSpeedLimit(from string: String) -> Double? {
        let lower = string.lowercased().trimmingCharacters(in: .whitespaces)
        let digits = string.filter { $0.isNumber || $0 == "." }
        
        guard let num = Double(digits) else { return nil }
        
        // Handle different units
        if lower.contains("mph") {
            return num
        } else if lower.contains("kph") || lower.contains("km/h") {
            return num * 0.621371
        } else {
            // Default to km/h if no unit specified (common in Europe)
            return num * 0.621371
        }
    }
    
    /// Clear cache (useful for testing or manual refresh)
    static func clearCache() {
        cache = nil
        pendingRequest?.cancel()
        pendingRequest = nil
    }
}
