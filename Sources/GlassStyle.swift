import SwiftUI

/// Liquid Glass container. On iOS 26+ uses the real `glassEffect` modifier;
/// older iOS falls back to a frosted material card.
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content

    init(cornerRadius: CGFloat = 26, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            content()
                .glassEffect(.regular.tint(.cyan.opacity(0.12)).interactive(), in: shape)
        } else {
            content()
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.strokeBorder(.white.opacity(0.18), lineWidth: 1))
        }
    }
}

/// Frosted "liquid glass" pill button.
struct GlassButtonStyle: ButtonStyle {
    var tint: Color = .cyan

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [tint.opacity(configuration.isPressed ? 0.55 : 0.85),
                                 tint.opacity(configuration.isPressed ? 0.35 : 0.55)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            )
            .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
            .shadow(color: tint.opacity(0.5), radius: 12, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 26) -> some View {
        GlassCard(cornerRadius: cornerRadius) { self }
    }
}
