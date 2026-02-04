import SwiftUI

// MARK: - App Theme

struct AppTheme {
    // Primary colors
    static let primaryBlue = Color(red: 0.20, green: 0.40, blue: 0.85)
    static let accentBlue = Color(red: 0.30, green: 0.55, blue: 1.0)
    static let darkBlue = Color(red: 0.08, green: 0.15, blue: 0.35)
    static let deepNavy = Color(red: 0.05, green: 0.08, blue: 0.22)

    // Accent colors
    static let accentRed = Color(red: 0.85, green: 0.25, blue: 0.30)
    static let successGreen = Color(red: 0.20, green: 0.75, blue: 0.45)
    static let warningOrange = Color(red: 1.0, green: 0.60, blue: 0.20)

    // Neutrals
    static let cardBackground = Color.white.opacity(0.12)
    static let cardBackgroundSolid = Color(red: 0.14, green: 0.18, blue: 0.32)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textMuted = Color.white.opacity(0.5)

    // Background gradient
    static let backgroundGradient = LinearGradient(
        colors: [deepNavy, darkBlue, Color(red: 0.10, green: 0.20, blue: 0.45)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Card Modifier

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardBackground)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Action Button Style

struct ActionButtonStyle: ButtonStyle {
    var color: Color = AppTheme.primaryBlue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = AppTheme.textPrimary

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.accentBlue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(valueColor)
            }

            Spacer()
        }
    }
}

// MARK: - Badge View

struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(color))
    }
}
