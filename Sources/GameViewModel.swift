import SwiftUI
import CoreLocation

@MainActor
final class GameViewModel: ObservableObject {
    @Published var state: GameState = .loading
    @Published var clue: PhotoClue?
    @Published var actualAirport: Airport?
    @Published var guessCoordinate: CLLocationCoordinate2D?
    @Published var lastResult: RoundResult?
    @Published var totalScore = 0
    @Published var roundNumber = 0
    @Published var streak = 0

    private let api = JetAPIClient.shared

    func startRound() async {
        state = .loading
        clue = nil
        actualAirport = nil
        guessCoordinate = nil

        do {
            let newClue = try await api.randomClue(from: RegistrationPool.registrations)
            clue = newClue
            state = .guessing
            // Resolve the actual airport in the background; needed at reveal.
            actualAirport = await AirportDatabase.resolve(for: newClue)
            if actualAirport == nil {
                state = .error("Couldn't resolve the airport. Try again.")
            }
        } catch {
            state = .error("JetAPI didn't return a usable photo. \(error.localizedDescription)")
        }
    }

    func confirmGuess() {
        guard let clue, let airport = actualAirport, let guess = guessCoordinate else { return }
        let dist = haversineKm(guess, airport.coordinate)
        let pts = pointsFor(distanceKm: dist)
        let result = RoundResult(clue: clue, actual: airport, guess: guess, distanceKm: dist, points: pts)
        lastResult = result
        totalScore += pts
        roundNumber += 1
        streak = dist < 50 ? streak + 1 : 0
        state = .reveal(result)
    }

    func nextRound() {
        Task { await startRound() }
    }
}
