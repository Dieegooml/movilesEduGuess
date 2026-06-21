import SwiftUI

struct LeaderboardView: View {
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = true
    @State private var selectedTab: Tab = .score
    @State private var pageSize = 20
    @State private var selectedEntry: LeaderboardEntry?
    @State private var showStatsSheet = false

    private let currentUserId = AuthViewModel.shared.effectiveUserId

    enum Tab: String, CaseIterable {
        case score = "Score"
        case winRate = "Win Rate"
        case streak = "Racha"
        case wins = "Victorias"
    }

    var sortedEntries: [LeaderboardEntry] {
        switch selectedTab {
        case .score:
            return entries.sorted { $0.score > $1.score }
        case .winRate:
            return entries.sorted {
                if $0.winRate == $1.winRate {
                    return $0.games > $1.games
                }
                return $0.winRate > $1.winRate
            }
        case .streak:
            return entries.sorted { $0.streak > $1.streak }
        case .wins:
            return entries.sorted { $0.wins > $1.wins }
        }
    }

    var currentUserEntry: LeaderboardEntry? {
        sortedEntries.first { $0.userId == currentUserId }
    }

    var currentUserRank: Int? {
        guard let entry = currentUserEntry else { return nil }
        return sortedEntries.firstIndex(where: { $0.userId == entry.userId }).map { $0 + 1 }
    }

    var body: some View {
        ZStack {
            backgroundGradient
            VStack(spacing: 0) {
                Picker("Tipo", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)
                .onChange(of: selectedTab) { _, _ in
                    pageSize = 20
                }

                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                } else if !NetworkMonitor.shared.isConnected {
                    EmptyStateView(
                        icon: "wifi.slash",
                        title: "Sin conexión",
                        description: "Conéctate a internet para ver el ranking global.",
                        buttonTitle: "Reintentar",
                        buttonAction: {
                            Task { await loadLeaderboard() }
                        }
                    )
                } else if entries.isEmpty {
                    EmptyStateView(
                        icon: "trophy.fill",
                        title: "Aún no hay datos",
                        description: "Sé el primero en jugar y aparecer en la tabla de líderes.",
                        buttonTitle: "Jugar ahora",
                        buttonAction: {}
                    )
                } else {
                    leaderboardList

                    if let entry = currentUserEntry, let rank = currentUserRank,
                       !sortedEntries.prefix(pageSize).contains(where: { $0.userId == currentUserId }) {
                        currentUserBanner(entry: entry, rank: rank)
                    }
                }
            }
        }
        .navigationTitle("Ranking")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await loadLeaderboard() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.white)
                }
                .disabled(isLoading)
            }
        }
        .task { await loadLeaderboard() }
        .refreshable { await loadLeaderboard() }
        .sheet(isPresented: $showStatsSheet) {
            if let entry = selectedEntry {
                LeaderboardStatsSheet(entry: entry)
            }
        }
    }

    private var leaderboardList: some View {
        List {
            ForEach(Array(sortedEntries.prefix(pageSize).enumerated()), id: \.element.id) { index, entry in
                Button {
                    selectedEntry = entry
                    showStatsSheet = true
                } label: {
                    leaderboardRow(rank: index + 1, entry: entry, isCurrentUser: entry.userId == currentUserId)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if pageSize < sortedEntries.count {
                Button {
                    pageSize += 20
                } label: {
                    HStack {
                        Spacer()
                        Text("Cargar más (\(sortedEntries.count - pageSize) restantes)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func leaderboardRow(rank: Int, entry: LeaderboardEntry, isCurrentUser: Bool) -> some View {
        HStack(spacing: 16) {
            Text("#\(rank)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(rank <= 3 ? .yellow : .white)
                .frame(width: 40)

            AvatarView(avatar: entry.avatar, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text("\(entry.wins)V / \(entry.games)P • \(entry.winRateText)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(tabValue(for: entry))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                if entry.streak > 0 {
                    Text("🔥 \(entry.streak)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser ? Color.yellow.opacity(0.25) : Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrentUser ? Color.yellow.opacity(0.6) : Color.clear, lineWidth: 1.5)
                )
        )
    }

    private func tabValue(for entry: LeaderboardEntry) -> String {
        switch selectedTab {
        case .score:
            return "\(entry.score)"
        case .winRate:
            return entry.winRateText
        case .streak:
            return "\(entry.streak)"
        case .wins:
            return "\(entry.wins)"
        }
    }

    private func currentUserBanner(entry: LeaderboardEntry, rank: Int) -> some View {
        HStack(spacing: 12) {
            AvatarView(avatar: entry.avatar, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text("Tú")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                Text("#\(rank) • \(tabValue(for: entry))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.yellow.opacity(0.5)),
            alignment: .top
        )
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.orange.opacity(0.9), Color.red.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func loadLeaderboard() async {
        isLoading = true
        pageSize = 20
        do {
            entries = try await FirestoreService.shared.fetchLeaderboard()
        } catch {
            print("Failed to load leaderboard: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Stats Sheet

struct LeaderboardStatsSheet: View {
    let entry: LeaderboardEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.orange.opacity(0.9), Color.red.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            AvatarView(avatar: entry.avatar, size: 90)
                            Text(entry.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            StatCard(label: "Partidas", value: "\(entry.games)")
                            StatCard(label: "Victorias", value: "\(entry.wins)")
                            StatCard(label: "Derrotas", value: "\(entry.losses)")
                            StatCard(label: "Win Rate", value: entry.winRateText)
                            StatCard(label: "Puntaje total", value: "\(entry.score)")
                            StatCard(label: "Mejor score", value: "\(entry.bestScore)")
                            StatCard(label: "Racha actual", value: "\(entry.streak) 🔥")
                        }

                        NavigationLink {
                            PublicProfileView(userId: entry.userId, userName: entry.name, userAvatar: entry.avatar)
                        } label: {
                            HStack {
                                Spacer()
                                Text("Ver perfil completo")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Estadísticas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}
