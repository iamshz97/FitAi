//
//  AppTheme.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - App Theme

/// Centralized theme configuration for the FitAi app.
/// Premium dark design with sophisticated emerald accents.
struct AppTheme {
    
    // MARK: - Colors
    
    struct Colors {
        // Primary Background (Deep Dark)
        static let background = Color(red: 0.06, green: 0.07, blue: 0.08)
        static let backgroundSecondary = Color(red: 0.08, green: 0.09, blue: 0.10)
        static let backgroundTertiary = Color(red: 0.10, green: 0.11, blue: 0.12)
        
        // Card Backgrounds (Subtle dark with hint of green)
        static let cardBackground = Color(red: 0.09, green: 0.10, blue: 0.11)
        static let cardBackgroundElevated = Color(red: 0.11, green: 0.12, blue: 0.13)
        
        // Glass Effect
        static let glassBackground = Color.white.opacity(0.08)
        static let glassBorder = Color.white.opacity(0.12)
        
        // Accent Colors (Sophisticated Emerald/Teal)
        static let accent = Color(red: 0.20, green: 0.78, blue: 0.60) // Sophisticated emerald
        static let accentSecondary = Color(red: 0.15, green: 0.65, blue: 0.50)
        static let accentMuted = Color(red: 0.18, green: 0.45, blue: 0.38)
        
        // Text Colors
        static let textPrimary = Color.white
        static let textSecondary = Color(white: 0.65)
        static let textTertiary = Color(white: 0.45)
        static let textAccent = accent
        
        // Status Colors
        static let success = Color(red: 0.20, green: 0.78, blue: 0.60)
        static let warning = Color(red: 0.95, green: 0.70, blue: 0.35)
        static let error = Color(red: 0.92, green: 0.40, blue: 0.40)
        static let info = Color(red: 0.45, green: 0.70, blue: 0.95)
        
        // Chart Colors (Gradient greens - sophisticated)
        static let chartBar1 = Color(red: 0.15, green: 0.35, blue: 0.30)
        static let chartBar2 = Color(red: 0.17, green: 0.45, blue: 0.38)
        static let chartBar3 = Color(red: 0.18, green: 0.60, blue: 0.48)
        static let chartBar4 = Color(red: 0.20, green: 0.78, blue: 0.60)
        
        // Chip/Tag Colors
        static let chipBackground = Color(white: 0.12)
        static let chipBackgroundSelected = accent.opacity(0.15)
        static let chipBorder = Color(white: 0.20)
        static let chipBorderSelected = accent
    }
    
    // MARK: - Gradients
    
    struct Gradients {
        static let accentButton = LinearGradient(
            colors: [Colors.accent, Colors.accentSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cardHighlight = LinearGradient(
            colors: [Colors.cardBackgroundElevated, Colors.cardBackground],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let backgroundFade = LinearGradient(
            colors: [Colors.background.opacity(0), Colors.background],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let glassGradient = LinearGradient(
            colors: [
                Color.white.opacity(0.15),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Typography
    
    struct Typography {
        // Display
        static func displayLarge() -> Font {
            .system(size: 34, weight: .bold, design: .rounded)
        }
        
        static func displayMedium() -> Font {
            .system(size: 28, weight: .bold, design: .rounded)
        }
        
        // Headlines
        static func headline() -> Font {
            .system(size: 20, weight: .semibold, design: .rounded)
        }
        
        static func headlineSmall() -> Font {
            .system(size: 17, weight: .semibold, design: .rounded)
        }
        
        // Body
        static func body() -> Font {
            .system(size: 16, weight: .regular, design: .rounded)
        }
        
        static func bodyMedium() -> Font {
            .system(size: 16, weight: .medium, design: .rounded)
        }
        
        // Captions
        static func caption() -> Font {
            .system(size: 13, weight: .regular, design: .rounded)
        }
        
        static func captionMedium() -> Font {
            .system(size: 13, weight: .medium, design: .rounded)
        }
        
        // Labels
        static func label() -> Font {
            .system(size: 12, weight: .medium, design: .rounded)
        }
        
        static func labelSmall() -> Font {
            .system(size: 11, weight: .medium, design: .rounded)
        }
        
        // Numbers/Stats
        static func statLarge() -> Font {
            .system(size: 42, weight: .bold, design: .rounded)
        }
        
        static func statMedium() -> Font {
            .system(size: 28, weight: .bold, design: .rounded)
        }
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
        static let pill: CGFloat = 50
    }
    
    // MARK: - Shadows
    
    struct Shadows {
        static let buttonGlow = Color(red: 0.20, green: 0.78, blue: 0.60).opacity(0.35)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies the app's primary background
    func appBackground() -> some View {
        self.background(AppTheme.Colors.background.ignoresSafeArea())
    }
    
    /// Applies card styling
    func cardStyle() -> some View {
        self
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    /// Applies elevated card styling
    func elevatedCardStyle() -> some View {
        self
            .background(AppTheme.Colors.cardBackgroundElevated)
            .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    /// Applies glassmorphism effect
    func glassStyle() -> some View {
        self
            .background(.ultraThinMaterial)
            .background(AppTheme.Colors.glassBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.extraLarge)
                    .stroke(AppTheme.Colors.glassBorder, lineWidth: 0.5)
            )
            .cornerRadius(AppTheme.CornerRadius.extraLarge)
    }
}

// MARK: - Button Styles

struct AccentButtonStyle: ButtonStyle {
    var isFullWidth: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.bodyMedium())
            .foregroundStyle(AppTheme.Colors.background)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.vertical, AppTheme.Spacing.lg)
            .padding(.horizontal, AppTheme.Spacing.xl)
            .background(AppTheme.Colors.accent)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var isFullWidth: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.bodyMedium())
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.vertical, AppTheme.Spacing.lg)
            .padding(.horizontal, AppTheme.Spacing.xl)
            .background(AppTheme.Colors.cardBackgroundElevated)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.Colors.chipBorder, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

// MARK: - Chip Style

struct ChipView: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                }
                Text(text)
            }
            .font(AppTheme.Typography.caption())
            .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.textSecondary)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(isSelected ? AppTheme.Colors.chipBackgroundSelected : AppTheme.Colors.chipBackground)
            .cornerRadius(AppTheme.CornerRadius.pill)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.pill)
                    .stroke(isSelected ? AppTheme.Colors.chipBorderSelected : AppTheme.Colors.chipBorder, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("FitAi")
            .font(AppTheme.Typography.displayLarge())
            .foregroundStyle(AppTheme.Colors.textPrimary)
        
        Text("Premium Design")
            .font(AppTheme.Typography.headline())
            .foregroundStyle(AppTheme.Colors.accent)
        
        HStack {
            ChipView(text: "Selected", isSelected: true) {}
            ChipView(text: "Normal", isSelected: false) {}
        }
        
        Button("Primary Action") {}
            .buttonStyle(AccentButtonStyle())
        
        Button("Secondary Action") {}
            .buttonStyle(SecondaryButtonStyle())
    }
    .padding()
    .appBackground()
}
