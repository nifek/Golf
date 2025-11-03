import SwiftUI

enum Theme {
    // Base palette tuned to the mockups
    static let background = Color(red: 0.03, green: 0.27, blue: 0.22)   // deep green
    static let surface = Color(red: 0.15, green: 0.43, blue: 0.36)      // mid green
    static let card = Color(red: 0.24, green: 0.56, blue: 0.46)         // lighter card
    static let accent = Color(red: 0.83, green: 0.91, blue: 0.86)       // pale mint text
    static let gold = Color(red: 0.95, green: 0.84, blue: 0.40)         // stars
    static let shadow = Color.black.opacity(0.25)
}

struct FilledButtonStyle: ButtonStyle {
    var color: Color = Theme.card
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(color)
                    .shadow(color: Theme.shadow, radius: 12, x: 0, y: 8)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.995 : 1.0)
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.card.opacity(0.9))
                    .shadow(color: Theme.shadow, radius: 10, x: 0, y: 8)
            )
    }
}

extension View {
    func cardBackground() -> some View { modifier(CardBackground()) }
}


