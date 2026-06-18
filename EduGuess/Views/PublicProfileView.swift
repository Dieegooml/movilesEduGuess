import SwiftUI

struct PublicProfileView: View {
    let userId: String
    let userName: String

    @State private var stats: UserStats?
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
                        CommentsView(profileUserId: userId)
                            .padding(.top, 8)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(userName)
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

            Text(userName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
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

    private func loadData() async {
        do {
            let fbUser = try await FirestoreService.shared.fetchUser(uid: userId)
            stats = fbUser?.stats
        } catch {
            print("Failed to load user: \(error)")
        }
        isLoading = false
    }
}
