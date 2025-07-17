import Foundation
import CoreLocation

/// Decodes the Overpass API JSON
private struct OverpassResponse: Codable {
    struct Element: Codable {
        let tags: [String: String]?
    }
    let elements: [Element]
}

/// Fetches the posted speed-limit (mph) at a given coord via OpenStreetMap/Overpass.
enum SpeedLimitService {
    static func fetchSpeedLimit(for coordinate: CLLocationCoordinate2D) async throws -> Double? {
        // 20 m radius
        let query = """
        [out:json][timeout:5];
        way(around:20,\(coordinate.latitude),\(coordinate.longitude))["maxspeed"];
        out tags;
        """
        guard let esc = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://overpass-api.de/api/interpreter?data=\(esc)")
        else { return nil }

        let (data, _) = try await URLSession.shared.data(from: url)
        let resp = try JSONDecoder().decode(OverpassResponse.self, from: data)

        for element in resp.elements {
            if let s = element.tags?["maxspeed"] {
                let lower = s.lowercased().trimmingCharacters(in: .whitespaces)
                let digits = s.filter { $0.isNumber || $0 == "." }
                guard let num = Double(digits) else { continue }
                // if tag says "mph", use directly; otherwise assume km/h
                if lower.contains("mph") {
                    return num
                } else {
                    return num * 0.621371
                }
            }
        }
        return nil
    }
}
