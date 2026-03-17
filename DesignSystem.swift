import SwiftUI

// MARK: - Colors

extension Color {
    static let brtrBackground = Color(hex: "#0D0B1E")
    static let brtrSurface = Color(hex: "#1A1635")
    static let brtrCard = Color(hex: "#1E1A3A")
    static let brtrPurple = Color(hex: "#7B3FFF")
    static let brtrPurpleLight = Color(hex: "#9B6FFF")
    static let brtrPurpleDim = Color(hex: "#3D2080")
    static let brtrTextPrimary = Color.white
    static let brtrTextSecondary = Color(hex: "#A09ABF")
    static let brtrTextMuted = Color(hex: "#6B6589")
    static let brtrGreen = Color(hex: "#4ADE80")
    static let brtrBorder = Color(hex: "#2E2855")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Fonts

struct BRTRFont {
    static func largeTitle() -> Font { .system(size: 32, weight: .bold) }
    static func title() -> Font { .system(size: 24, weight: .bold) }
    static func title2() -> Font { .system(size: 20, weight: .semibold) }
    static func headline() -> Font { .system(size: 17, weight: .semibold) }
    static func body() -> Font { .system(size: 15, weight: .regular) }
    static func subheadline() -> Font { .system(size: 13, weight: .regular) }
    static func caption() -> Font { .system(size: 11, weight: .regular) }
}

// MARK: - Button Styles

struct BRTRPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BRTRFont.headline())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(LinearGradient(colors: [.brtrPurple, .brtrPurpleLight], startPoint: .leading, endPoint: .trailing))
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

struct BRTRSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BRTRFont.headline())
            .foregroundColor(.brtrPurpleLight)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.brtrPurpleDim.opacity(0.4))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.brtrPurple.opacity(0.5), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

// MARK: - Card Modifier

struct BRTRCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.brtrCard)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brtrBorder, lineWidth: 1))
    }
}

extension View {
    func brtrCard() -> some View {
        modifier(BRTRCard())
    }
}

// MARK: - Components

struct StarRating: View {
    let rating: Double
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
            }
        }
    }
}

struct VerifiedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 12))
                .foregroundColor(.brtrGreen)
            Text("Verified")
                .font(BRTRFont.caption())
                .foregroundColor(.brtrGreen)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.brtrGreen.opacity(0.15))
        .cornerRadius(20)
    }
}
