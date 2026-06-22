import SwiftUI
import SwiftData

struct ProfileView: View {
    @State private var authVM = AuthViewModel.shared
    @State private var stats: UserStats?
    @State private var avatarName = "person.circle.fill"
    @State private var isLoading = true
    @State private var showSignOutAlert = false
    @State private var showError = false
    @State private var errorText = ""

    var body: some View {
        ZStack {
            AppTheme.mainGradient.ignoresSafeArea()
            PetFloatingBackground()

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
        .toolbarColorScheme(.dark, for: .navigationBar)
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
        .toast(message: errorText, icon: "exclamationmark.circle.fill", isShowing: $showError)
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            NavigationLink {
                SettingsView()
            } label: {
                AvatarView(avatar: avatarName, size: 90)
            }
            .buttonStyle(.plain)

            Text(authVM.userName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)

            Text(authVM.userEmail)
                .foregroundColor(AppTheme.secondaryText)

            Button("Cerrar sesión", role: .destructive) {
                showSignOutAlert = true
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accentRed.opacity(0.85))
            .foregroundColor(.white)
            .padding(.top, 8)
            .alert("Cerrar sesión", isPresented: $showSignOutAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Cerrar sesión", role: .destructive) { authVM.signOut() }
            } message: {
                Text("¿Estás seguro de que quieres cerrar sesión?")
            }
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
                StatisticsView()
            } label: {
                menuRow(icon: "chart.bar.fill", title: "Estadísticas detalladas")
            }

            NavigationLink {
                CharacterListView()
            } label: {
                menuRow(icon: "person.3.fill", title: "Personajes")
            }

            NavigationLink {
                GameHistoryView()
            } label: {
                menuRow(icon: "clock.arrow.circlepath", title: "Historial de partidas")
            }
        }
    }

    private func menuRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppTheme.primaryGold)
            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.mutedText)
        }
        .padding()
        .background(AppTheme.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private var historySection: some View {
        HistoryPreviewView()
    }

    private func loadData() async {
        guard let uid = authVM.userUID else {
            isLoading = false
            return
        }
        do {
            let fbUser = try await FirestoreService.shared.fetchUser(uid: uid)
            stats = fbUser?.stats
            avatarName = fbUser?.avatar ?? "person.circle.fill"
        } catch {
            errorText = "Error al cargar perfil: \(error.localizedDescription)"
            showError = true
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
                .foregroundColor(AppTheme.primaryText)

            if recentSessions.isEmpty {
                Text("Aún no has jugado")
                    .foregroundColor(AppTheme.secondaryText)
            } else {
                ForEach(recentSessions) { session in
                    HStack {
                        Image(systemName: session.won ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(session.won ? AppTheme.successGreen : AppTheme.errorRed)
                        VStack(alignment: .leading) {
                            Text(session.characterName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.primaryText)
                            Text("\(session.questionsAsked.count) preguntas")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        Spacer()
                        if session.won {
                            Text("+\(session.score)")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.primaryGold)
                        }
                    }
                    .padding()
                    .background(AppTheme.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
            }
        }
        .onAppear(perform: loadSessions)
    }

    private func loadSessions() {
        let uid = AuthViewModel.shared.effectiveUserId
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
                .foregroundColor(AppTheme.primaryText)
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
        .cornerRadius(12)
    }
}
