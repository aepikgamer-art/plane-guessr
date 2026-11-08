import SwiftUI
import MapKit

struct MapGuessView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottom) {
                // Real MKMapView wrapper: SwiftUI Map eats taps, so we do
                // tap-to-pin with a proper UITapGestureRecognizer.
                PinDropMapView(pin: vm.guessCoordinate) { coord in
                    vm.guessCoordinate = coord
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
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

            HStack(spacing: 10) {
                Button {
                    vm.nextRound()
                } label: {
                    Label("Skip", systemImage: "arrow.uturn.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle(tint: .gray))

                Button {
                    if vm.guessCoordinate != nil { vm.confirmGuess() }
                } label: {
                    Label(vm.guessCoordinate == nil ? "Drop a pin" : "Lock it in",
                          systemImage: vm.guessCoordinate == nil ? "hand.tap" : "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle(tint: .cyan))
                .disabled(vm.guessCoordinate == nil)
            }
        }
    }
}

// MARK: - MKMapView wrapper

final class GuessPin: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    init(_ c: CLLocationCoordinate2D) { coordinate = c }
}

struct PinDropMapView: UIViewRepresentable {
    var pin: CLLocationCoordinate2D?
    var onTap: (CLLocationCoordinate2D) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.mapType = .standard
        map.pointOfInterestFilter = .excludingAll
        map.showsTraffic = false
        map.showsCompass = true
        map.isRotateEnabled = false
        map.setRegion(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 25, longitude: -20),
            span: MKCoordinateSpan(latitudeDelta: 110, longitudeDelta: 110)
        ), animated: false)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped(_:)))
        tap.delegate = context.coordinator
        map.addGestureRecognizer(tap)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.syncPin(on: map)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: PinDropMapView
        private var lastPinLatitude: Double?
        private var lastPinLongitude: Double?

        init(_ parent: PinDropMapView) { self.parent = parent }

        @objc func tapped(_ gr: UITapGestureRecognizer) {
            guard let map = gr.view as? MKMapView else { return }
            parent.onTap(map.convert(gr.location(in: map), toCoordinateFrom: map))
        }

        /// Let the tap recognizer work alongside MKMapView's own pan/zoom gestures.
        func gestureRecognizer(_ g: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }

        func syncPin(on map: MKMapView) {
            let existing = map.annotations.filter { $0 is GuessPin }
            if let pin = parent.pin {
                let moved = pin.latitude != lastPinLatitude || pin.longitude != lastPinLongitude
                guard moved else { return }
                lastPinLatitude = pin.latitude
                lastPinLongitude = pin.longitude
                if !existing.isEmpty { map.removeAnnotations(existing) }
                map.addAnnotation(GuessPin(pin))
            } else if lastPinLatitude != nil || lastPinLongitude != nil {
                lastPinLatitude = nil
                lastPinLongitude = nil
                if !existing.isEmpty { map.removeAnnotations(existing) }
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation is GuessPin else { return nil }
            let id = "guessPin"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView)
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.annotation = annotation
            view.canShowCallout = false
            view.markerTintColor = .systemCyan
            view.glyphImage = UIImage(systemName: "mappin.and.ellipse")
            return view
        }
    }
}
