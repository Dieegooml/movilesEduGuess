//
//  QuestionCard.swift
//  EduGuess
//

import SwiftUI

struct QuestionCard: View {
    let question: String
    @State private var appear = false
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        Text(question)
            .font(.title3.weight(.bold))
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Gradient background
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "3B82F6").opacity(0.95),
                                    Color(hex: "7C3AED").opacity(0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Shimmer effect – clipped so it never spills outside
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0),
                                        Color.white.opacity(0.25),
                                        Color.white.opacity(0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * 0.6)
                            .offset(x: shimmerOffset * geo.size.width)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.25), lineWidth: 2)
            )
            .shadow(
                color: Color(hex: "3B82F6").opacity(0.35),
                radius: 14,
                x: 0,
                y: 8
            )
            .padding(.horizontal)
            .scaleEffect(appear ? 1.0 : 0.85)
            .opacity(appear ? 1.0 : 0.0)
            .offset(y: appear ? 0 : 20)
            .rotationEffect(.degrees(appear ? 0 : -3))
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    appear = true
                }
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 2
                }
            }
            .onChange(of: question) { _ in
                appear = false
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    appear = true
                }
            }
    }
}

#Preview {
    ZStack {
        AppTheme.mainGradient.ignoresSafeArea()
        VStack(spacing: 16) {
            QuestionCard(question: "¿Tu personaje utiliza magia o poderes sobrenaturales?")
            QuestionCard(question: "¿Tu personaje es una figura histórica que vivió durante el siglo XX y es conocido por sus contribuciones a la física teórica?")
        }
        .padding()
    }
}
