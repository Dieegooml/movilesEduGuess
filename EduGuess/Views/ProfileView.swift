import SwiftUI
import SwiftData

struct ProfileView: View {
    @State private var authVM = AuthViewModel.shared
    @State private var stats: UserStats?
    @State private var avatarName = "person.circle.fill"
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
                        AchievementListView(isOwnProfile: true)
                            .padding(.top, 8)
                        adminSection
                        historySection
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Mi Perfil")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await loadData() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.white)
                }
                .disabled(isLoading)
            }
        }
        .task { await loadData() }
        .refreshable { await loadData() }
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
            NavigationLink {
                SettingsView()
            } label: {
                AvatarView(avatar: avatarName, size: 80)
            }
            .buttonStyle(.plain)

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

    private var adminSection: some View {
        VStack(spacing: 12) {
            NavigationLink {
                CharacterListView()
            } label: {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.title3)
                    Text("Personajes")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
            }

            NavigationLink {
                GameHistoryView()
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title3)
                    Text("Historial de partidas")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
            }
        }
    }

    private var historySection: some View {
        HistoryPreviewView()
    }

    private func loadData() async {
        guard let uid = authVM.userUID else { return }
        do {
            let fbUser = try await FirestoreService.shared.fetchUser(uid: uid)
            stats = fbUser?.stats
            avatarName = fbUser?.avatar ?? "person.circle.fill"
        } catch {
            print("Failed to load profile: \(error)")
        }
        isLoading = false
    }
}

private struct HistoryPreviewView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var recentSessions: [SDGameSession] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Últimas partidas")
                .font(.headline)
                .foregroundColor(.white)

            if recentSessions.isEmpty {
                Text("Aún no has jugado")
                    .foregroundColor(.white.opacity(0.7))
            } else {
                ForEach(recentSessions) { session in
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
                        if session.won {
                            Text("+\(session.score)")
                                .font(.subheadline)
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                }
            }
        }
        .onAppear(perform: loadSessions)
    }

    private func loadSessions() {
        let uid = AuthViewModel.shared.userUID ?? ""
        let predicate = #Predicate<SDGameSession> { session in
            session.userId == uid
        }
        var descriptor = FetchDescriptor<SDGameSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\SDGameSession.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 5
        recentSessions = (try? modelContext.fetch(descriptor)) ?? []
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
