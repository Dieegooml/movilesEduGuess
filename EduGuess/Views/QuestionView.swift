import SwiftUI
import SwiftData
import UIKit

struct QuestionView: View {

    @StateObject private var viewModel = GameViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var correctDestinationActive = false
    @State private var wrongDestinationActive = false
    @State private var isLoading = true

    let preloadedCharacters: [Character]?
    let isDailyChallenge: Bool
    let dailyCharacterName: String?

    init(preloadedCharacters: [Character]? = nil, isDailyChallenge: Bool = false, dailyCharacterName: String? = nil) {
        self.preloadedCharacters = preloadedCharacters
        self.isDailyChallenge = isDailyChallenge
        self.dailyCharacterName = dailyCharacterName
    }

    var body: some View {
        ZStack {
            if isLoading {
                loadingContent
            } else {
                gameContent
            }
        }
        .navigationDestination(isPresented: $correctDestinationActive) {
            CorrectGuessView(
                characterName: viewModel.guessedCharacter?.name ?? "Desconocido",
                characterImage: viewModel.guessedCharacter?.image ?? "",
                profile: viewModel.finalProfile,
                askedAttributes: viewModel.askedAttributeKeys,
                answers: viewModel.givenAnswers,
                isDailyChallenge: isDailyChallenge,
                dailyCharacterName: dailyCharacterName
            )
        }
        .navigationDestination(isPresented: $wrongDestinationActive) {
            WrongGuessView(
                profile: viewModel.finalProfile,
                askedAttributes: viewModel.askedAttributeKeys,
                answers: viewModel.givenAnswers,
                isDailyChallenge: isDailyChallenge,
                dailyCharacterName: dailyCharacterName
            )
        }
        .onAppear {
            loadDataFromSwiftData()
        }
        .onChange(of: viewModel.gameState) { newState in
            switch newState {
            case .guessed:
                correctDestinationActive = true
                saveDailyIfNeeded()
            case .failed:
                wrongDestinationActive = true
                saveDailyIfNeeded()
            default:
                break
            }
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Preparando el juego...")
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var gameContent: some View {
        VStack(spacing: 24) {
            if isDailyChallenge {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Desafío Diario: \(dailyCharacterName ?? "")")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(20)
                .transition(.slide.combined(with: .opacity))
            }

            Spacer()

            RobotAvatar()

            ProgressBar(progress: progressValue)
                .frame(height: 40)

            if viewModel.isAttemptingGuess {
                guessContent
            } else {
                questionContent
            }

            Spacer()

        }
        .padding()
    }

    // MARK: - Normal Question Mode

    private var questionContent: some View {
        VStack(spacing: 16) {
            QuestionCard(question: viewModel.currentQuestion)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(viewModel.currentQuestion)

            VStack(spacing: 12) {
                AnswerButton(title: "Sí", color: .green) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.answerQuestion(answer: .yes)
                    }
                }

                AnswerButton(title: "No", color: .red) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.answerQuestion(answer: .no)
                    }
                }

                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.answerQuestion(answer: .unknown)
                    }
                } label: {
                    Text("No sé")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.secondary.opacity(0.5), lineWidth: 1.5)
                        )
                }
            }
            .padding(.horizontal)

            Text("Pregunta \(viewModel.questionsAskedCount + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.questionsAskedCount)
    }

    // MARK: - Guess Attempt Mode

    private var guessContent: some View {
        VStack(spacing: 16) {
            if let candidate = viewModel.guessCandidate, !candidate.image.isEmpty {
                guessImage(candidate)
            }
            QuestionCard(question: "¿Es \(viewModel.guessCandidate?.name ?? "...")?")
                .transition(.scale.combined(with: .opacity))
                .id("guess-\(viewModel.guessCandidate?.name ?? "")")

            VStack(spacing: 12) {
                AnswerButton(title: "Sí, es correcto", color: .green) {
                    viewModel.respondToGuess(correct: true)
                }

                AnswerButton(title: "No, no es", color: .red) {
                    viewModel.respondToGuess(correct: false)
                }
            }
            .padding(.horizontal)

            Text("Intento de adivinanza")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .opacity
        ))
    }

    @ViewBuilder
    private func guessImage(_ character: Character) -> some View {
        if let url = URL(string: character.image) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.orange, lineWidth: 2))
                case .failure, .empty:
                    EmptyView()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 80, height: 80)
        }
    }

    // MARK: - Data

    private func loadDataFromSwiftData() {
        let dataService = DataService()
        let characters = preloadedCharacters ?? dataService.fetchCharacters(context: modelContext)

        isLoading = false
        viewModel.startNewGame(characters: characters)
    }

    private var progressValue: CGFloat {
        CGFloat(min(viewModel.progressRatio, 1.0))
    }

    private func saveDailyIfNeeded() {
        guard isDailyChallenge, let name = dailyCharacterName else { return }
        let won = viewModel.gameState == .guessed
        let score = GameScoring.calculateScore(questionsAsked: viewModel.questionsAskedCount, won: won)
        let uid = AuthViewModel.shared.userUID ?? ""
        let userName = AuthViewModel.shared.userName
        let questions = viewModel.questionsAskedCount

        let avatar = UserDefaults.standard.string(forKey: "avatarName") ?? "person.circle.fill"
        Task {
            await DailyChallengeService.shared.saveScore(
                userId: uid,
                userName: userName,
                avatar: avatar,
                characterName: name,
                questionsAsked: questions,
                score: score
            )
        }
    }
}

struct QuestionView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionView()
    }
}
