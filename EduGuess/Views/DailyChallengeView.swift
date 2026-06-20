import SwiftUI
import SwiftData

struct DailyChallengeView: View {
    @Environment(\.modelContext) private var context
    @State private var dailyCharacter: Character?
    @State private var isLoading = true
    @State private var alreadyPlayed = false

    var body: some View {
        VStack(spacing: 24) {
            if isLoading {
                ProgressView("Preparando desafío...")
            } else if let character = dailyCharacter {
                VStack(spacing: 16) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)

                    Text("Desafío Diario")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Responde pensando en el personaje de hoy.\n¡Menos preguntas = mejor puntaje!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    if alreadyPlayed {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                            Text("Ya participaste hoy")
                                .font(.headline)
                            Text("Vuelve mañana para un nuevo desafío")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)

                        NavigationLink {
                            DailyLeaderboardView()
                        } label: {
                            Text("Ver ranking del día")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
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
                                .background(Color.orange)
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
        .navigationTitle("Desafío Diario")
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
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if scores.isEmpty {
                ContentUnavailableView(
                    "Sin resultados",
                    systemImage: "trophy",
                    description: Text("Sé el primero en participar hoy")
                )
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
                                Text(score.characterName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("\(score.score)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                Text("\(score.questionsAsked) preg")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Ranking del Día")
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
        case 0: return .yellow
        case 1: return .gray
        case 2: return .brown
        default: return .secondary
        }
    }
}
