//
//  RobotAvatar.swift
//  EduGuess
//

import SwiftUI

struct RobotAvatar: View {
    @State private var breathe = false
    @State private var outerRing = false
    @State private var innerRing = false
    @State private var rotate = false

    var body: some View {
        ZStack {
            // Outer expanding ring
            Circle()
                .stroke(Color.orange.opacity(0.2), lineWidth: 3)
                .frame(width: 180, height: 180)
                .scaleEffect(outerRing ? 1.2 : 0.9)
                .opacity(outerRing ? 0 : 0.6)

            // Middle ring
            Circle()
                .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                .frame(width: 160, height: 160)
                .scaleEffect(innerRing ? 1.1 : 0.95)
                .opacity(innerRing ? 0.3 : 0.7)

            // Main background circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.orange.opacity(0.3),
                            Color.orange.opacity(0.1)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 75
                    )
                )
                .frame(width: 150, height: 150)
                .shadow(color: Color.orange.opacity(0.3), radius: 20, x: 0, y: 0)

            // Decorative dots orbiting
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.orange.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .offset(
                        x: cos(Double(i) * 2.094 + (rotate ? 6.283 : 0)) * 68,
                        y: sin(Double(i) * 2.094 + (rotate ? 6.283 : 0)) * 68
                    )
            }

            // Main brain icon
            Image(systemName: "brain.head.profile")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .symbolEffect(.bounce, options: .nonRepeating)
                .scaleEffect(breathe ? 1.08 : 1.0)
                .shadow(color: Color.orange.opacity(0.5), radius: 8, x: 0, y: 4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                breathe = true
            }
            withAnimation(.easeOut(duration: 2.5).repeatForever(autoreverses: false)) {
                outerRing = true
            }
            withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: false)) {
                innerRing = true
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotate = true
            }
        }
    }
}

#Preview {
    RobotAvatar()
        .padding()
}
