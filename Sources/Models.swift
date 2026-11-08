import Foundation
import CoreLocation

struct PhotoClue: Identifiable, Equatable {
    let id = UUID()
    let imageURL: URL
    let photographer: String
    let dateTaken: String
    let airportName: String   // e.g. "Denver Int'l Airport - KDEN"
    let icao: String          // e.g. "KDEN"
    let registration: String
    let airline: String       // e.g. "Northwest Airlines"
    let aircraftType: String  // e.g. "Airbus A320-211"
}

struct Airport: Identifiable, Equatable {
    let icao: String
    let name: String
    let latitude: Double
    let longitude: Double

    var id: String { icao }
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct RoundResult: Identifiable {
    let id = UUID()
    let clue: PhotoClue
    let actual: Airport
    let guess: CLLocationCoordinate2D
    let distanceKm: Double
    let points: Int
}

enum GameState {
    case loading
    case guessing
    case reveal(RoundResult)
    case error(String)
}
