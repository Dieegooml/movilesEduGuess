import SwiftUI

/// Animated background featuring the pet mascot floating subtly behind content.
/// Adds life to screens without distracting from the main UI.
struct PetFloatingBackground: View {
    @State private var offset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Soft glow behind the mascot
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.primaryYellow.opacity(0.15),
                            AppTheme.primaryYellow.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .offset(y: offset)

            Image("pet_welcome")
                .resizable()
                .scaledToFit()
                .frame(width: 220, height: 220)
                .offset(y: offset)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
        }
        .onAppear {
            opacity = 0.12
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                offset = -30
            }
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                rotation = 6
            }
        }
    }
}

#Preview {
    ZStack {
        AppTheme.mainGradient.ignoresSafeArea()
        PetFloatingBackground()
    }
}
