//
//  ViewModifiers.swift
//  ZeroDevCleaner
//
//  Created on 2025-10-30.
//

import SwiftUI

// MARK: - Hover Effect Modifier

struct HoverEffect: ViewModifier {
    @State private var isHovered = false

    let scale: CGFloat
    let brightness: Double

    init(scale: CGFloat = 1.02, brightness: Double = 0.05) {
        self.scale = scale
        self.brightness = brightness
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .brightness(isHovered ? brightness : 0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Button Hover Effect

struct ButtonHoverEffect: ViewModifier {
    @State private var isHovered = false

    let scale: CGFloat
    let shadowRadius: CGFloat

    init(scale: CGFloat = 0.98, shadowRadius: CGFloat = 2) {
        self.scale = scale
        self.shadowRadius = shadowRadius
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .shadow(color: .black.opacity(isHovered ? 0.15 : 0), radius: shadowRadius)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Row Hover Effect

struct RowHoverEffect: ViewModifier {
    @State private var isHovered = false

    let cornerRadius: CGFloat

    init(cornerRadius: CGFloat = 6) {
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.accentColor.opacity(isHovered ? 0.08 : 0))
            )
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Card Style Effect

struct CardStyle: ViewModifier {
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let padding: CGFloat

    init(cornerRadius: CGFloat = 8, shadowRadius: CGFloat = 2, padding: CGFloat = 16) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.padding = padding
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: shadowRadius, y: 1)
            )
    }
}

// MARK: - Smooth Transition Effect

struct SmoothTransition: ViewModifier {
    let duration: Double

    init(duration: Double = 0.3) {
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .animation(.easeInOut(duration: duration), value: UUID())
    }
}

// MARK: - Icon Animation Effect

struct IconPulse: ViewModifier {
    @State private var isPulsing = false

    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double

    init(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.0) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? maxScale : minScale)
            .animation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Adds a hover effect with scale and brightness changes
    func hoverEffect(scale: CGFloat = 1.02, brightness: Double = 0.05) -> some View {
        modifier(HoverEffect(scale: scale, brightness: brightness))
    }

    /// Adds a button-specific hover effect with scale and shadow
    func buttonHoverEffect(scale: CGFloat = 0.98, shadowRadius: CGFloat = 2) -> some View {
        modifier(ButtonHoverEffect(scale: scale, shadowRadius: shadowRadius))
    }

    /// Adds a row hover effect with background highlight
    func rowHoverEffect(cornerRadius: CGFloat = 6) -> some View {
        modifier(RowHoverEffect(cornerRadius: cornerRadius))
    }

    /// Applies card-style with padding, background, and shadow
    func cardStyle(cornerRadius: CGFloat = 8, shadowRadius: CGFloat = 2, padding: CGFloat = 16) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius, shadowRadius: shadowRadius, padding: padding))
    }

    /// Adds a smooth transition effect for view appearance
    func smoothTransition(duration: Double = 0.3) -> some View {
        modifier(SmoothTransition(duration: duration))
    }

    /// Adds a pulsing animation to icons
    func iconPulse(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.0) -> some View {
        modifier(IconPulse(minScale: minScale, maxScale: maxScale, duration: duration))
    }
}
