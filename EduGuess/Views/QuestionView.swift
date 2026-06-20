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
            Group {
                if viewModel.isGenerating {
                    generatingContent
                } else if viewModel.generationError {
                    errorContent
                } else {
                    QuestionCard(question: viewModel.currentQuestion)
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
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            Text("Pregunta \(viewModel.questionsAskedCount + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.isGenerating)
        .animation(.easeInOut(duration: 0.3), value: viewModel.questionsAskedCount)
    }

    private var errorContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("No se pudo generar la pregunta")
                .font(.headline)

            Text("Revisa tu conexión a internet y vuelve a intentarlo")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                viewModel.retryQuestion()
            } label: {
                Label("Reintentar", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }

    private var generatingContent: some View {
        ThinkingAnimation()
            .padding(.vertical, 60)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .opacity
            ))
    }

    // MARK: - Guess Attempt Mode

    private var guessContent: some View {
        VStack(spacing: 16) {
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

    // MARK: - Data

    private func loadDataFromSwiftData() {
        let dataService = DataService()
        let characters = preloadedCharacters ?? dataService.fetchCharacters(context: modelContext)

        isLoading = false
        viewModel.startNewGame(characters: characters, context: modelContext)
    }

    private var progressValue: CGFloat {
        CGFloat(min(viewModel.progressRatio, 1.0))
    }

    private func saveDailyIfNeeded() {
        guard isDailyChallenge, let name = dailyCharacterName else { return }
        let won = viewModel.gameState == .guessed
        let score = GameScoring.calculateScore(questionsAsked: viewModel.questionsAskedCount, won: won)
        let uid = AuthViewModel.shared.effectiveUserId
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

// MARK: - Thinking Animation

private struct DotAnimation: View {
    @State private var offset: CGFloat = 0
    let delay: Double

    var body: some View {
        Circle()
            .fill(Color.accentColor)
            .frame(width: 8, height: 8)
            .offset(y: offset)
            .opacity(1 - offset * 0.05)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    offset = -10
                }
            }
    }
}

struct ThinkingAnimation: View {
    @State private var iconScale: CGFloat = 1
    @State private var glowRadius: CGFloat = 0
    @State private var messageIndex = 0
    @State private var messageTimer: Timer?

    private let messages = [
        "Pensando...",
        "Analizando...",
        "Recordando...",
        "Conectando...",
        "Procesando..."
    ]

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(iconScale)

                Circle()
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .scaleEffect(1 + glowRadius * 0.3)
                    .opacity(1 - glowRadius)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundColor(.accentColor)
                    .scaleEffect(iconScale)
            }
            .frame(height: 130)

            HStack(spacing: 12) {
                Text(messages[messageIndex])
                    .font(.title3.weight(.medium))
                    .foregroundColor(.primary)
                    .contentTransition(.opacity)
                    .id(messageIndex)

                HStack(spacing: 5) {
                    DotAnimation(delay: 0)
                    DotAnimation(delay: 0.2)
                    DotAnimation(delay: 0.4)
                }
            }

            Text("Generando la mejor pregunta")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                iconScale = 1.12
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowRadius = 1
            }
            messageTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    messageIndex = (messageIndex + 1) % messages.count
                }
            }
        }
        .onDisappear {
            messageTimer?.invalidate()
            messageTimer = nil
        }
    }
}
