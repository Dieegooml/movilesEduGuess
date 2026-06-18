import SwiftUI

struct LeaderboardView: View {
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = true
    @State private var selectedTab: Tab = .allTime
    @State private var pageSize = 20

    enum Tab: String, CaseIterable {
        case allTime = "Todos"
        case weekly = "Semanal"
    }

    var body: some View {
        ZStack {
            backgroundGradient
            VStack(spacing: 16) {
                Picker("Tipo", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedTab) { _, _ in
                    Task { await loadLeaderboard() }
                }

                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                } else if !NetworkMonitor.shared.isConnected {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.slash")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.7))
                        Text("Sin conexión")
                            .foregroundColor(.white.opacity(0.7))
                        Text("Conéctate a internet para ver el ranking")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                } else if entries.isEmpty {
                    Spacer()
                    Text("Aún no hay datos")
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                } else {
                    List {
                        ForEach(Array(entries.prefix(pageSize).enumerated()), id: \.element.id) { index, entry in
                            NavigationLink {
                                PublicProfileView(userId: entry.userId, userName: entry.name, userAvatar: entry.avatar)
                            } label: {
                                leaderboardRow(rank: index + 1, entry: entry)
                            }
                            .listRowBackground(Color.clear)
                        }
                        if pageSize < entries.count {
                            Button {
                                pageSize += 20
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("Cargar más (\(entries.count - pageSize) restantes)")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .padding(.top)
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
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.orange.opacity(0.9), Color.red.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func leaderboardRow(rank: Int, entry: LeaderboardEntry) -> some View {
        HStack(spacing: 16) {
            Text("#\(rank)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(rank <= 3 ? .yellow : .white)
                .frame(width: 40)

            AvatarView(avatar: entry.avatar, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text("\(entry.wins)V / \(entry.games)P")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Text("\(entry.score)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }

    private func loadLeaderboard() async {
        isLoading = true
        pageSize = 20
        do {
            switch selectedTab {
            case .allTime:
                entries = try await FirestoreService.shared.fetchLeaderboard()
            case .weekly:
                entries = try await FirestoreService.shared.fetchTopWeekly()
            }
        } catch {
            print("Failed to load leaderboard: \(error)")
        }
        isLoading = false
    }
}
