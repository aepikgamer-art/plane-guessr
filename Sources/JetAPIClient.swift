import Foundation
import CoreLocation

enum JetAPIError: Error {
    case badResponse
    case noUsablePhotos
}

struct JetAPIClient {
    static let shared = JetAPIClient()
    private let base = URL(string: "https://www.jetapi.dev")!
    private let session: URLSession

    init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 20
        cfg.httpAdditionalHeaders = ["User-Agent": "PlaneGuessr/1.0"]
        session = URLSession(configuration: cfg)
    }

    func photos(registration: String) async throws -> [PhotoClue] {
        var comps = URLComponents(url: base.appendingPathComponent("aircraft"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "reg", value: registration)]
        guard let url = comps.url else { throw JetAPIError.badResponse }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw JetAPIError.badResponse
        }
        let raw = try JSONSerialization.jsonObject(with: data)
        return Self.extractClues(from: raw, registration: registration)
    }

    func randomClue(from pool: [String]) async throws -> PhotoClue {
        var tried = Set<String>()
        for _ in 0..<6 {
            let reg = pool.randomElement()!
            guard !tried.contains(reg) else { continue }
            tried.insert(reg)
            guard let photos = try? await photos(registration: reg), !photos.isEmpty else { continue }
            if let clue = photos.randomElement() { return clue }
        }
        throw JetAPIError.noUsablePhotos
    }

    // MARK: - Lenient JSON walking

    static func extractClues(from node: Any, registration: String) -> [PhotoClue] {
        var clues: [PhotoClue] = []
        walk(node) { dict in
            var airport: String?
            var photographer: String?
            var date: String?
            var image: String?

            for (key, value) in dict {
                guard let s = Self.asString(value) else { continue }
                let k = key.lowercased()
                if airport == nil, k.contains("airport"), s.count < 120, s.contains(" - ") {
                    airport = s
                } else if airport == nil, k.contains("airport"), s.count < 120 {
                    airport = s
                }
                if photographer == nil, k.contains("photograph"), s.count < 80 { photographer = s }
                if date == nil, k.contains("date"), s.count < 40 { date = s }
                if image == nil, s.hasPrefix("http"), s.contains(".jpg") || s.contains(".jpeg") || s.contains(".png") || s.contains("jetphotos") {
                    if k.contains("thumb") || k.contains("image") || k.contains("photo") || k.contains("url") || k.contains("src") {
                        image = s
                    }
                }
            }

            guard let apt = airport, let img = image, let u = URL(string: img) else { return }
            clues.append(PhotoClue(
                imageURL: u,
                photographer: photographer ?? "Unknown",
                dateTaken: date ?? "",
                airportName: apt,
                icao: Self.icaoFromAirport(apt) ?? "",
                registration: registration
            ))
        }
        return clues
    }

    private static func walk(_ node: Any, visit: ([String: Any]) -> Void) {
        if let dict = node as? [String: Any] {
            visit(dict)
            for value in dict.values { walk(value, visit: visit) }
        } else if let arr = node as? [Any] {
            for item in arr { walk(item, visit: visit) }
        }
    }

    private static func asString(_ value: Any) -> String? {
        if let s = value as? String { return s }
        if let n = value as? Int { return String(n) }
        return nil
    }

    /// "Denver Int'l Airport - KDEN" -> "KDEN"
    static func icaoFromAirport(_ s: String) -> String? {
        let tokens = s.split(separator: " ").map(String.init)
        guard let last = tokens.last, last.count == 4, last == last.uppercased(),
              last.first?.isLetter == true,
              last.rangeOfCharacter(from: CharacterSet.letters.inverted) == nil else { return nil }
        return last
    }
}

func haversineKm(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
    let r = 6371.0
    let dLat = (b.latitude - a.latitude) * .pi / 180
    let dLon = (b.longitude - a.longitude) * .pi / 180
    let la = a.latitude * .pi / 180
    let lb = b.latitude * .pi / 180
    let h = sin(dLat / 2) * sin(dLat / 2) + cos(la) * cos(lb) * sin(dLon / 2) * sin(dLon / 2)
    return 2 * r * asin(min(1, sqrt(h)))
}

func pointsFor(distanceKm: Double) -> Int {
    Int((5000 * pow(2.0, -distanceKm / 250)).rounded())
}
