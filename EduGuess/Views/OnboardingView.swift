import SwiftUI

/// Pantallas de onboarding mostradas la primera vez que se abre la app.
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var animateLogo = false
    @Environment(\.dismiss) private var dismiss

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "brain.head.profile",
            title: "Bienvenido a EduGuess",
            description: "Piensa en un personaje histórico, científico o cultural. La IA intentará adivinar quién es haciéndote preguntas inteligentes."
        ),
        OnboardingPage(
            icon: "questionmark.bubble.fill",
            title: "Responde con honestidad",
            description: "Responde Sí, No o No sé a cada pregunta. Cuanta más información des, más rápido adivinará."
        ),
        OnboardingPage(
            icon: "trophy.fill",
            title: "Compite y mejora",
            description: "Acumula puntos, desbloquea logros, compite en el ranking global y supera el desafío diario."
        ),
        OnboardingPage(
            icon: "person.3.fill",
            title: "Multijugador y Social",
            description: "Crea tu perfil, comparte tus victorias y compite con jugadores de todo el mundo."
        )
    ]

    var body: some View {
        ZStack {
            AppTheme.mainGradient.ignoresSafeArea()
            PetFloatingBackground()

            VStack(spacing: 0) {
                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageContent(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 420)

                Spacer()

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? AppTheme.primaryGold : AppTheme.primaryText.opacity(0.4))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 20)

                // Action button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        hasCompletedOnboarding = true
                        dismiss()
                    }
                } label: {
                    HStack {
                        Text(currentPage < pages.count - 1 ? "Siguiente" : "¡Empezar!")
                            .font(.headline)
                        Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "play.fill")
                    }
                    .foregroundColor(AppTheme.backgroundTop)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.buttonGradient)
                    .cornerRadius(18)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }

    private func pageContent(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(AppTheme.primaryGold)
                .symbolEffect(.bounce, options: .repeat(1), value: currentPage)
                .padding(.bottom, 8)

            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)

            Text(page.description)
                .font(.body)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .lineSpacing(4)
        }
        .padding(.top, 20)
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
}

#Preview {
    OnboardingView()
}
