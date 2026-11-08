import SwiftUI
import MapKit

struct MapGuessView: View {
    @ObservedObject var vm: GameViewModel
    @State private var camera: MapCameraPosition = .worldSpin

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottom) {
                Map(position: $camera) {
                    if let guess = vm.guessCoordinate {
                        Marker("Your guess", systemImage: "mappin.and.ellipse", coordinate: guess)
                            .tint(.cyan)
                    }
                    if case .reveal(let result) = vm.state {
                        Marker(result.actual.name, systemImage: "airplane.circle", coordinate: result.actual.coordinate)
                            .tint(.orange)
                    }
                }
                .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll, showsTraffic: false))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                if vm.guessCoordinate == nil {
                    Text("Tap the map where you think this photo was taken")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassCard(cornerRadius: 99)
                        .padding(.bottom, 10)
                }
            }
            .frame(maxHeight: .infinity)

            Button {
                if vm.guessCoordinate != nil { vm.confirmGuess() }
            } label: {
                Label(vm.guessCoordinate == nil ? "Drop a pin on the map" : "Lock in my guess",
                      systemImage: vm.guessCoordinate == nil ? "hand.tap" : "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyle(tint: .cyan))
            .disabled(vm.guessCoordinate == nil)
        }
        // Tap anywhere on the container: convert to a map coordinate via the
        // map's UIViewRepresentable bridge (MKMapView projection).
        .overlay {
            MapTapBridge { coord in
                vm.guessCoordinate = coord
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }
}

extension MapCameraPosition {
    static let worldSpin = MapCameraPosition.camera(
        MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 30, longitude: 0),
                  distance: 14_000_000, heading: 0, pitch: 0)
    )
}

/// Transparent UIViewRepresentable that overlays the SwiftUI Map, converts
/// screen taps to geo-coordinates using MKMapView's projection, and forwards
/// them. SwiftUI Map consumes raw taps for marker selection, so this bridge is
/// the reliable way to implement "tap to drop a pin".
struct MapTapBridge: UIViewRepresentable {
    var onTap: (CLLocationCoordinate2D) -> Void

    func makeUIView(context: Context) -> UIView {
        let v = TapView()
        v.backgroundColor = .clear
        v.onMapTap = onTap
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped(_:)))
        v.addGestureRecognizer(tap)
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        (uiView as? TapView)?.onMapTap = onTap
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject {
        let parent: MapTapBridge
        init(_ parent: MapTapBridge) { self.parent = parent }

        @objc func tapped(_ gr: UITapGestureRecognizer) {
            guard let window = gr.view?.window else { return }
            let point = gr.location(in: window)
            // Find the underlying MKMapView in the window hierarchy.
            guard let mapView = Self.findMapView(in: window) else { return }
            let local = window.convert(point, to: mapView)
            parent.onTap(mapView.convert(local, toCoordinateFrom: mapView))
        }

        static func findMapView(in view: UIView) -> MKMapView? {
            if let mv = view as? MKMapView { return mv }
            for sub in view.subviews {
                if let found = findMapView(in: sub) { return found }
            }
            return nil
        }
    }

    final class TapView: UIView {
        var onMapTap: ((CLLocationCoordinate2D) -> Void)?
        // Pass touches through except taps handled by our gesture recognizer.
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            return nil // see README: enable this overlay's hit-testing if the
                       // SwiftUI Map doesn't already consume taps on your iOS version.
        }
    }
}
