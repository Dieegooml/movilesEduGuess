import SwiftUI

struct HomeView: View {
    @State private var authVM = AuthViewModel.shared
    @State private var buttonsAppeared = false
    @State private var showTutorial = false
    @State private var showSignOutAlert = false
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange.opacity(0.9), Color.red.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                VStack(spacing: 20) {
                    Image(systemName: "brain")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)

                    Text("EduGuess")
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundColor(.white)

                    Text("Piensa en un personaje y la IA intentará adivinarlo")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal)
                }

                if authVM.isAuthenticated {
                    Text("Bienvenido, \(authVM.userName)")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.subheadline)
                }

                VStack(spacing: 16) {
                    NavigationLink {
                        DailyChallengeView()
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "star.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Desafío Diario")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Un personaje nuevo cada día")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.orange)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        )
                    }
                    .offset(x: buttonsAppeared ? 0 : -200)
                    .opacity(buttonsAppeared ? 1 : 0)

                    NavigationLink {
                        QuestionView()
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "play.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Comenzar")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("La IA intentará adivinar tu personaje")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)
                        )
                    }
                    .offset(x: buttonsAppeared ? 0 : 200)
                    .opacity(buttonsAppeared ? 1 : 0)

                    NavigationLink {
                        LeaderboardView()
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 1.5)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "trophy.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Ranking")
                                    .font(.headline)
                                Text("Compara tus puntajes")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                        )
                    }
                    .offset(x: buttonsAppeared ? 0 : 200)
                    .opacity(buttonsAppeared ? 1 : 0)
                }
                .padding(.horizontal, 30)

                Spacer()

            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    NavigationLink {
                        HowToPlayView()
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.white)
                    }
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.white)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title3)
                            .foregroundColor(.white)
                    }

                    if authVM.isAuthenticated {
                        Button {
                            showSignOutAlert = true
                        } label: {
                            Text("Salir")
                                .foregroundColor(.white)
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
        .onAppear {
            buttonsAppeared = false
            withAnimation(.easeOut(duration: 0.1)) {
                buttonsAppeared = true
            }
            if authVM.isAuthenticated && !hasSeenTutorial {
                showTutorial = true
                hasSeenTutorial = true
            }
        }
    }
}
