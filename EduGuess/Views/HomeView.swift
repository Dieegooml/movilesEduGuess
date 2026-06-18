import SwiftUI

struct HomeView: View {
    @State private var authVM = AuthViewModel.shared
    @State private var buttonsAppeared = false

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
                            Image(systemName: "star.fill")
                            Text("Desafío Diario")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .foregroundColor(.orange)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(18)
                    }
                    .offset(x: buttonsAppeared ? 0 : -200)
                    .opacity(buttonsAppeared ? 1 : 0)

                    NavigationLink {
                        CategorySelectView()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Comenzar")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(18)
                    }
                    .offset(x: buttonsAppeared ? 0 : 200)
                    .opacity(buttonsAppeared ? 1 : 0)

                    NavigationLink {
                        CharacterListView()
                    } label: {
                        HStack {
                            Image(systemName: "person.3.fill")
                            Text("Personajes")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white, lineWidth: 2)
                        )
                    }
                    .offset(x: buttonsAppeared ? 0 : -200)
                    .opacity(buttonsAppeared ? 1 : 0)

                    NavigationLink {
                        LeaderboardView()
                    } label: {
                        HStack {
                            Image(systemName: "trophy.fill")
                            Text("Ranking")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white, lineWidth: 2)
                        )
                    }
                    .offset(x: buttonsAppeared ? 0 : 200)
                    .opacity(buttonsAppeared ? 1 : 0)
                }
                .padding(.horizontal, 30)

                Spacer()

                Text("Powered by AI")
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 25)
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
                            authVM.signOut()
                        } label: {
                            Text("Salir")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .onAppear {
            buttonsAppeared = false
            withAnimation(.easeOut(duration: 0.1)) {
                buttonsAppeared = true
            }
        }
    }
}
