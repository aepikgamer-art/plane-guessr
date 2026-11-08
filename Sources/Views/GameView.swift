import SwiftUI

struct GameView: View {
    @StateObject private var vm = GameViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradientBackground()

                switch vm.state {
                case .loading:
                    VStack(spacing: 18) {
                        Image(systemName: "airplane")
                            .font(.system(size: 56))
                            .symbolEffect(.pulse)
                            .foregroundStyle(.cyan)
                        Text("Finding a plane to stump you…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                case .guessing:
                    if let clue = vm.clue {
                        GuessScreen(clue: clue, vm: vm)
                    }
                case .reveal(let result):
                    ResultView(result: result, vm: vm)
                case .error(let message):
                    VStack(spacing: 14) {
                        Image(systemName: "wifi.exclamationmark").font(.largeTitle).foregroundStyle(.orange)
                        Text(message).multilineTextAlignment(.center)
                        Button("Retry") { Task { await vm.startRound() } }
                            .buttonStyle(GlassButtonStyle())
                    }
                    .padding(30)
                }
            }
            .navigationTitle("PlaneGuessr")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    GlassBadge(icon: "star.fill", text: "\(vm.totalScore)")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    GlassBadge(icon: "flame.fill", text: "\(vm.streak)")
                }
            }
        }
        .task { await vm.startRound() }
    }
}

struct GuessScreen: View {
    let clue: PhotoClue
    @ObservedObject var vm: GameViewModel

    var body: some View {
        VStack(spacing: 14) {
            PhotoClueView(clue: clue)
            MapGuessView(vm: vm)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }
}

struct GlassBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.caption)
            Text(text).font(.caption.weight(.bold)).monospacedDigit()
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .glassCard(cornerRadius: 99)
    }
}

struct MeshGradientBackground: View {
    var body: some View {
        if #available(iOS 18.0, *) {
            MeshGradient(width: 3, height: 3, points: [
                .init(0, 0), .init(0.5, 0), .init(1, 0),
                .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
                .init(0, 1), .init(0.5, 1), .init(1, 1)
            ], colors: [
                Color(red: 0.02, green: 0.05, blue: 0.12),
                Color(red: 0.03, green: 0.08, blue: 0.20),
                Color(red: 0.02, green: 0.05, blue: 0.12),
                Color(red: 0.03, green: 0.08, blue: 0.20),
                Color(red: 0.05, green: 0.12, blue: 0.28),
                Color(red: 0.03, green: 0.08, blue: 0.20),
                Color(red: 0.02, green: 0.05, blue: 0.12),
                Color(red: 0.03, green: 0.08, blue: 0.20),
                Color(red: 0.02, green: 0.05, blue: 0.12)
            ])
            .ignoresSafeArea()
        } else {
            LinearGradient(colors: [Color(red: 0.02, green: 0.05, blue: 0.12),
                                    Color(red: 0.05, green: 0.12, blue: 0.28)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
    }
}
