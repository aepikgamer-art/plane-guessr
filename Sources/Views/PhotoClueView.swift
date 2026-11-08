import SwiftUI

struct PhotoClueView: View {
    let clue: PhotoClue

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AsyncImage(url: clue.imageURL) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Rectangle().fill(.ultraThinMaterial)
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    ZStack {
                        Rectangle().fill(.ultraThinMaterial)
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 250)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            // Clue chips (glass pills). The airport itself is deliberately NOT shown.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if !clue.airline.isEmpty {
                        ClueChip(icon: "building.2.fill", text: clue.airline, tint: .orange)
                    }
                    if !clue.aircraftType.isEmpty {
                        ClueChip(icon: "airplane", text: clue.aircraftType, tint: .cyan)
                    }
                    ClueChip(icon: "number", text: clue.registration, tint: .white)
                    if !clue.dateTaken.isEmpty {
                        ClueChip(icon: "calendar", text: clue.dateTaken, tint: .white)
                    }
                    ClueChip(icon: "camera.fill", text: "© \(clue.photographer)", tint: .gray)
                }
            }
        }
        .padding(14)
        .glassCard()
    }
}

struct ClueChip: View {
    let icon: String
    let text: String
    var tint: Color = .white

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.caption2).foregroundStyle(tint)
            Text(text).font(.caption).lineLimit(1).foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassCard(cornerRadius: 99)
    }
}
