//
//  AnswerButton.swift
//  EduGuess
//

import SwiftUI

struct AnswerButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false
    @State private var glowAmount: CGFloat = 0

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)

                Text(title)
                    .font(.headline.weight(.bold))

                Spacer()
            }
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(color)

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.35), lineWidth: 2)

                    // Inner glow
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(0.6), lineWidth: glowAmount)
                    .blur(radius: 4)
            )
            .shadow(
                color: color.opacity(0.4),
                radius: isPressed ? 4 : 12,
                x: 0,
                y: isPressed ? 2 : 6
            )
            .scaleEffect(isPressed ? 0.94 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowAmount = 3
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        AnswerButton(title: "Sí", icon: "checkmark.circle.fill", color: .green) {}
        AnswerButton(title: "Probablemente sí", icon: "hand.thumbsup.fill", color: Color.green.opacity(0.7)) {}
        AnswerButton(title: "No sé", icon: "questionmark.circle.fill", color: .gray) {}
        AnswerButton(title: "Probablemente no", icon: "hand.thumbsdown.fill", color: .orange) {}
        AnswerButton(title: "No", icon: "xmark.circle.fill", color: .red) {}
    }
    .padding()
}
