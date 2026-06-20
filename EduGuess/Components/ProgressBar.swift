//
//  ProgressBar.swift
//  EduGuess
//

import SwiftUI

struct ProgressBar: View {
    var progress: CGFloat
    var questionsAsked: Int = 0

    @State private var animatedProgress: CGFloat = 0
    @State private var pulse = false

    private var progressColor: Color {
        switch progress {
        case 0..<0.3: return .red
        case 0.3..<0.6: return .orange
        case 0.6..<0.85: return .yellow
        default: return .green
        }
    }

    private var progressText: String {
        if questionsAsked < 15 {
            return "Pregunta \(questionsAsked + 1) de mínimo 15"
        } else {
            return "Pregunta \(questionsAsked + 1)"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progreso")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.primary)

                Spacer()

                Text(progressText)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.15))
                    )
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 12)
                        .frame(height: 18)
                        .foregroundColor(Color(.systemGray5))

                    // Animated fill
                    RoundedRectangle(cornerRadius: 12)
                        .frame(
                            width: max(geometry.size.width * animatedProgress, animatedProgress > 0 ? 8 : 0),
                            height: 18
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [progressColor.opacity(0.8), progressColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: progressColor.opacity(0.5), radius: 4, x: 0, y: 2)
                        .overlay(
                            // Glowing tip
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: .white, radius: 4)
                                    .padding(.trailing, 4)
                            }
                        )

                    // Pulsing highlight
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(pulse ? 0.4 : 0.1), lineWidth: 2)
                        .frame(height: 18)
                }
            }
            .frame(height: 18)
        }
        .padding(.horizontal)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = newValue
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBar(progress: 0.2, questionsAsked: 3)
        ProgressBar(progress: 0.5, questionsAsked: 8)
        ProgressBar(progress: 0.8, questionsAsked: 15)
    }
    .padding()
}
