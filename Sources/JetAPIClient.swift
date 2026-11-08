import Foundation
import CoreLocation

enum JetAPIError: Error {
    case badResponse(Int)
    case noUsablePhotos
}

// JetAPI response (https://www.jetapi.dev, open-source Go server by macsencasaus)
// GET /api?reg=N306US&photos=10&only_jp=true
struct JetPhotosResult: Codable {
    struct ImageAttributes: Codable {
        let Image: String?
        let Link: String?
        let Thumbnail: String?
        let DateTaken: String?
        let Location: String?
        let Photographer: String?
        let Aircraft: String?
        let Airline: String?
    }
    let Reg: String?
    let Images: [ImageAttributes]?
}

struct ScrapeResult: Codable {
    let JetPhotos: JetPhotosResult?
    let FlightRadar: ScrapeResult?
}

struct JetAPIClient {
    static let shared = JetAPIClient()
    private let base = URL(string: "https://www.jetapi.dev")!
    private let session: URLSession

    init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 25
        cfg.httpAdditionalHeaders = ["User-Agent": "PlaneGuessr/1.0"]
        session = URLSession(configuration: cfg)
    }

    func photos(registration: String) async throws -> [PhotoClue] {
        var comps = URLComponents(url: base.appendingPathComponent("api"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "reg", value: registration),
            URLQueryItem(name: "photos", value: "10"),
            URLQueryItem(name: "only_jp", value: "true"),
        ]
        guard let url = comps.url else { throw JetAPIError.badResponse(-1) }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw JetAPIError.badResponse((response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        // only_jp=true returns the JetPhotosResult directly; the combined
        // endpoint wraps it in {"JetPhotos": {...}}. Handle both.
        var result: JetPhotosResult?
        if let direct = try? JSONDecoder().decode(JetPhotosResult.self, from: data) {
            result = direct
        } else {
            result = (try? JSONDecoder().decode(ScrapeResult.self, from: data))?.JetPhotos
        }

        let images = result?.Images ?? []
        return images.compactMap { img in
            guard let loc = img.Location,
                  let photoURLString = img.Image ?? img.Thumbnail,
                  let photoURL = URL(string: photoURLString) else { return nil }
            return PhotoClue(
                imageURL: photoURL,
                photographer: img.Photographer ?? "Unknown",
                dateTaken: img.DateTaken ?? "",
                airportName: loc,
                icao: JetAPIClient.icaoFromAirport(loc) ?? "",
                registration: result?.Reg ?? registration
            )
        }
    }

    /// Pick a random registration, keep any of its photos that include a usable airport string.
    func randomClue(from pool: [String]) async throws -> PhotoClue {
        var tried = Set<String>()
        var lastError: Error = JetAPIError.noUsablePhotos
        for _ in 0..<6 {
            let reg = pool.randomElement()!
            guard !tried.contains(reg) else { continue }
            tried.insert(reg)
            do {
                let photos = try await photos(registration: reg)
                if let clue = photos.randomElement() { return clue }
            } catch {
                lastError = error
            }
        }
        throw lastError
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
