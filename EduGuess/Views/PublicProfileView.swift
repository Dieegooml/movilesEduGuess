import SwiftUI

struct PublicProfileView: View {
    let userId: String
    let userName: String
    let userAvatar: String

    @State private var stats: UserStats?
    @State private var avatarName: String
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorText = ""

    init(userId: String, userName: String, userAvatar: String = "person.circle.fill") {
        self.userId = userId
        self.userName = userName
        self.userAvatar = userAvatar
        _avatarName = State(initialValue: userAvatar)
    }

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
                        CommentsView(profileUserId: userId)
                            .padding(.top, 8)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(userName)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadData() }
        .refreshable { await loadData() }
        .toast(message: errorText, icon: "exclamationmark.circle.fill", isShowing: $showError)
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            AvatarView(avatar: avatarName, size: 90)

            Text(userName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
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
            if let avatar = fbUser?.avatar, !avatar.isEmpty {
                avatarName = avatar
            }
        } catch {
            errorText = "Error al cargar perfil"
            showError = true
        }
        isLoading = false
    }
}
