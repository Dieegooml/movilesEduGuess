import SwiftUI

struct ProfileView: View {
    @State private var authVM = AuthViewModel.shared
    @State private var stats: UserStats?
    @State private var recentSessions: [FirebaseGameSession] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            backgroundGradient
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        statsCards
                        recentGames
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Perfil")
        .task { await loadData() }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.orange.opacity(0.9), Color.red.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.white)

            Text(authVM.userName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(authVM.userEmail)
                .foregroundColor(.white.opacity(0.8))

            Button("Cerrar sesión", role: .destructive) {
                authVM.signOut()
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.3))
            .padding(.top, 8)
        }
    }

    private var statsCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(label: "Partidas", value: "\(stats?.totalGames ?? 0)")
            StatCard(label: "Victorias", value: "\(stats?.wins ?? 0)")
            StatCard(label: "Derrotas", value: "\(stats?.losses ?? 0)")
            StatCard(label: "Puntaje total", value: "\(stats?.totalScore ?? 0)")
            StatCard(label: "Mejor score", value: "\(stats?.bestScore ?? 0)")
            StatCard(label: "% Victorias", value: winRateText)
        }
    }

    private var winRateText: String {
        guard let s = stats, s.totalGames > 0 else { return "0%" }
        return "\(Int(s.winRate * 100))%"
    }

    private var recentGames: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Últimas partidas")
                .font(.headline)
                .foregroundColor(.white)

            if recentSessions.isEmpty {
                Text("Aún no has jugado")
                    .foregroundColor(.white.opacity(0.7))
            } else {
                ForEach(recentSessions, id: \.timestamp) { session in
                    HStack {
                        Image(systemName: session.won ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(session.won ? .green : .red)
                        VStack(alignment: .leading) {
                            Text(session.characterName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text("\(session.questionsAsked.count) preguntas")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                        Text("\(session.score) pts")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                }
            }
        }
    }

    private func loadData() async {
        guard let uid = authVM.userUID else { return }
        do {
            let fbUser = try await FirestoreService.shared.fetchUser(uid: uid)
            stats = fbUser?.stats
            recentSessions = try await FirestoreService.shared.fetchUserSessions(uid: uid)
        } catch {
            print("Failed to load profile: \(error)")
        }
        isLoading = false
    }
}

struct StatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
}
