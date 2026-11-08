import SwiftUI
import MapKit

struct ResultView: View {
    let result: RoundResult
    @ObservedObject var vm: GameViewModel

    var body: some View {
        VStack(spacing: 14) {
            MapGuessResultCard(result: result)
                .frame(height: 260)

            VStack(spacing: 10) {
                Label(result.actual.name, systemImage: "airplane.circle.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                HStack(spacing: 26) {
                    Stat(value: "\(Int(result.distanceKm.rounded()))", unit: "km off")
                    Stat(value: "+\(result.points)", unit: "points")
                    Stat(value: "\(vm.totalScore)", unit: "total")
                }
            }
            .padding(.vertical, 6)

            Text(verdict(for: result.distanceKm))
                .font(.headline)
                .foregroundStyle(.cyan)

            Button {
                vm.nextRound()
            } label: {
                Label("Next plane", systemImage: "arrow.right.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyle(tint: .orange))
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    private func verdict(for km: Double) -> String {
        switch km {
        case ..<10: return "NAILED IT. Ramp rat certified"
        case ..<50: return "basically a local"
        case ..<200: return "solid guess, fr"
        case ..<1000: return "same continent at least"
        default: return "bro… that's not even close"
        }
    }
}

struct MapGuessResultCard: View {
    let result: RoundResult

    @State private var camera: MapCameraPosition

    init(result: RoundResult) {
        self.result = result
        _camera = State(initialValue: .camera(
            MapCamera(centerCoordinate: result.actual.coordinate,
                      distance: 900_000, heading: 0, pitch: 0)
        ))
    }

    var body: some View {
        Map(position: $camera) {
            Marker("Actual: \(result.actual.name)", systemImage: "airplane.circle", coordinate: result.actual.coordinate)
                .tint(.orange)
            Marker("You", systemImage: "mappin.and.ellipse", coordinate: result.guess)
                .tint(.cyan)
            MapPolyline(coordinates: [result.guess, result.actual.coordinate])
                .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 3, dash: [6, 5]))
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct Stat: View {
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.title2.weight(.heavy)).monospacedDigit()
            Text(unit).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
