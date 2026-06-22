import SwiftUI
import SwiftData

struct DailyChallengeView: View {
    @Environment(\.modelContext) private var context
    @State private var dailyCharacter: Character?
    @State private var isLoading = true
    @State private var alreadyPlayed = false

    var body: some View {
        ZStack {
            AppTheme.mainGradient.ignoresSafeArea()

            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Preparando desafío...")
                        .tint(.white)
                } else if let character = dailyCharacter {
                    VStack(spacing: 16) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.primaryGold)

                        Text("Desafío Diario")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.primaryText)

                        Text("Responde pensando en el personaje de hoy.\n¡Menos preguntas = mejor puntaje!")
                            .font(.body)
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        if alreadyPlayed {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(AppTheme.successGreen)
                                Text("Ya participaste hoy")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.primaryText)
                                Text("Vuelve mañana para un nuevo desafío")
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding()
                            .background(AppTheme.cardSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.cardBorder, lineWidth: 1)
                            )
                            .cornerRadius(16)

                            NavigationLink {
                                DailyLeaderboardView()
                            } label: {
                                Text("Ver ranking del día")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.buttonGradient)
                                    .cornerRadius(18)
                            }
                            .padding(.horizontal, 30)
                        } else {
                            NavigationLink {
                                QuestionView(
                                    preloadedCharacters: [character],
                                    isDailyChallenge: true,
                                    dailyCharacterName: character.name
                                )
                            } label: {
                                Text("Comenzar desafío")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.buttonGradient)
                                    .cornerRadius(18)
                            }
                            .padding(.horizontal, 30)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No hay personajes",
                        systemImage: "person.slash",
                        description: Text("Agrega personajes primero")
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Desafío Diario")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            loadCharacter()
        }
    }

    private func loadCharacter() {
        let character = DailyChallengeService.shared.characterForToday(context: context)
        dailyCharacter = character
        isLoading = false

        if let c = character {
            Task {
                let uid = AuthViewModel.shared.effectiveUserId
                alreadyPlayed = await DailyChallengeService.shared.hasPlayedToday(userId: uid)
            }
        }
    }
}

struct DailyLeaderboardView: View {
    @State private var scores: [DailyScore] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            AppTheme.mainGradient.ignoresSafeArea()

            List {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                } else if scores.isEmpty {
                    ContentUnavailableView(
                        "Sin resultados",
                        systemImage: "trophy",
                        description: Text("Sé el primero en participar hoy")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(Array(scores.enumerated()), id: \.element.id) { index, score in
                        NavigationLink {
                            PublicProfileView(userId: score.userId, userName: score.userName, userAvatar: score.userAvatar)
                        } label: {
                            HStack {
                                Text("#\(index + 1)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(rankColor(index))
                                    .frame(width: 50)

                                AvatarView(avatar: score.userAvatar, size: 30)
                                    .foregroundColor(rankColor(index))

                                VStack(alignment: .leading) {
                                    Text(score.userName)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppTheme.primaryText)
                                    Text(score.characterName)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.mutedText)
                                }

                                Spacer()

                                VStack(alignment: .trailing) {
                                    Text("\(score.score)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppTheme.primaryGold)
                                    Text("\(score.questionsAsked) preg")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.mutedText)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(AppTheme.cardSurface)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Ranking del Día")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .refreshable {
            await refresh()
        }
        .task {
            await refresh()
        }
    }

    private func refresh() async {
        isLoading = true
        scores = await DailyChallengeService.shared.leaderboard()
        isLoading = false
    }

    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: return AppTheme.primaryGold
        case 1: return Color.gray
        case 2: return Color.brown
        default: return AppTheme.mutedText
        }
    }
}
