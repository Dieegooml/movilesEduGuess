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
            .font(.title2.weight(.bold))
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .minimumScaleFactor(0.6)
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Gradient background
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.9),
                                    Color.red.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Shimmer effect
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset * 400)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
            )
            .shadow(
                color: Color.orange.opacity(0.3),
                radius: 12,
                x: 0,
                y: 6
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
    QuestionCard(question: "¿Tu personaje utiliza magia o poderes sobrenaturales?")
        .padding()
}
