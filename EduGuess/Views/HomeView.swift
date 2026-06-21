import SwiftUI

struct HomeView: View {
    @State private var authVM = AuthViewModel.shared
    @State private var buttonsAppeared = false
    @State private var showTutorial = false
    @State private var showSignOutAlert = false
    @State private var showOnboarding = false
    @State private var showOfflineBanner = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false

    var body: some View {
        ZStack {
            AppTheme.mainGradient
                .ignoresSafeArea()

            PetFloatingBackground()
                .offset(x: 80, y: -80)

            VStack(spacing: 0) {
                if showOfflineBanner {
                    OfflineBanner(onRetry: {})
                        .monitor()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                mainContent
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 16) {
                    NavigationLink {
                        HowToPlayView()
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.title3)
                            .foregroundColor(AppTheme.primaryYellow)
                    }
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundColor(AppTheme.primaryYellow)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title3)
                            .foregroundColor(AppTheme.primaryYellow)
                    }

                    if authVM.isAuthenticated {
                        Button {
                            showSignOutAlert = true
                        } label: {
                            Text("Salir")
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.primaryYellow)
                        }
                    }
                }
            }
        }
        .alert("Cerrar sesión", isPresented: $showSignOutAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Cerrar sesión", role: .destructive) { authVM.signOut() }
        } message: {
            Text("¿Estás seguro de que quieres cerrar sesión?")
        }
        .fullScreenCover(isPresented: $showTutorial) {
            NavigationStack {
                HowToPlayView()
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
                hasCompletedOnboarding = true
            }

            buttonsAppeared = false
            withAnimation(.easeOut(duration: 0.1)) {
                buttonsAppeared = true
            }

            if authVM.isAuthenticated && !hasSeenTutorial && hasCompletedOnboarding {
                showTutorial = true
                hasSeenTutorial = true
            }

            NetworkMonitor.shared.onChange { isConnected in
                DispatchQueue.main.async {
                    withAnimation(.spring(duration: 0.3)) {
                        showOfflineBanner = !isConnected
                    }
                }
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 16) {
                PetAvatarView(emotion: .welcome, size: 150)
                    .shadow(color: AppTheme.primaryYellow.opacity(0.35), radius: 30, x: 0, y: 15)

                Text("EduGuess")
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, AppTheme.primaryYellow],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("Piensa en un personaje y la IA intentará adivinarlo")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.horizontal)
            }

            if authVM.isAuthenticated {
                Text("Bienvenido, \(authVM.userName)")
                    .foregroundColor(AppTheme.primaryYellow)
                    .font(.subheadline.weight(.semibold))
            }

            VStack(spacing: 14) {
                menuButton(
                    icon: "star.fill",
                    title: "Desafío Diario",
                    subtitle: "Un personaje nuevo cada día",
                    style: .card,
                    offset: buttonsAppeared ? 0 : -200
                ) {
                    DailyChallengeView()
                }

                menuButton(
                    icon: "play.fill",
                    title: "Comenzar",
                    subtitle: "La IA intentará adivinar tu personaje",
                    style: .gradient,
                    offset: buttonsAppeared ? 0 : 200
                ) {
                    QuestionView()
                }

                menuButton(
                    icon: "trophy.fill",
                    title: "Ranking",
                    subtitle: "Compara tus puntajes",
                    style: .outline,
                    offset: buttonsAppeared ? 0 : 200
                ) {
                    LeaderboardView()
                }
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    private enum ButtonStyle {
        case card, gradient, outline
    }

    private func menuButton<V: View>(
        icon: String,
        title: String,
        subtitle: String,
        style: ButtonStyle,
        offset: CGFloat,
        @ViewBuilder destination: () -> V
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    switch style {
                    case .card:
                        Circle()
                            .fill(AppTheme.cardSurfaceSolid)
                            .overlay(Circle().stroke(AppTheme.primaryYellow, lineWidth: 1.5))
                            .frame(width: 44, height: 44)
                    case .gradient:
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                    case .outline:
                        Circle()
                            .stroke(AppTheme.primaryYellow, lineWidth: 1.5)
                            .frame(width: 44, height: 44)
                    }
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(style == .gradient ? AppTheme.primaryOrange : AppTheme.primaryYellow)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(subtitle)
                        .font(.caption)
                        .opacity(0.85)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .foregroundColor(style == .card ? .primary : .white)
            .padding(16)
            .background(
                Group {
                    switch style {
                    case .card:
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppTheme.cardSurface)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.cardBorder, lineWidth: 1))
                            .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5)
                    case .gradient:
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppTheme.buttonGradient)
                            .shadow(color: AppTheme.primaryOrange.opacity(0.45), radius: 12, x: 0, y: 6)
                    case .outline:
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.primaryYellow.opacity(0.6), lineWidth: 1.5)
                            .background(RoundedRectangle(cornerRadius: 20).fill(AppTheme.cardSurface))
                    }
                }
            )
        }
        .offset(x: offset)
        .opacity(offset == 0 ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: buttonsAppeared)
        .pressEffect()
    }
}

// MARK: - Press Effect Modifier

struct PressEffectModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isPressed = true
                        HapticManager.shared.impact(.light)
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

extension View {
    func pressEffect() -> some View {
        modifier(PressEffectModifier())
    }
}

// MARK: - Haptic Manager

final class HapticManager {
    static let shared = HapticManager()

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}
