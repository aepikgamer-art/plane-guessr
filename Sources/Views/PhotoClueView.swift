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
            HStack(spacing: 8) {
                ClueChip(icon: "airplane.circle.fill", text: clue.registration)
                ClueChip(icon: "camera.fill", text: "© \(clue.photographer)")
                if !clue.dateTaken.isEmpty {
                    ClueChip(icon: "calendar", text: clue.dateTaken)
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

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.caption2)
            Text(text).font(.caption).lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassCard(cornerRadius: 99)
    }
}
