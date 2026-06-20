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
            LinearGradient(
                colors: [Color.orange.opacity(0.05), Color.red.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

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

            if viewModel.isRevealing {
                revealContent
            } else if viewModel.isAttemptingGuess {
                guessContent
            } else {
                questionContent
            }

            Spacer()

        }
        .padding()
    }

    // MARK: - Reveal Animation (before showing correct guess)

    private var revealContent: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .scaleEffect(1 + 0.1 * sin(Date().timeIntervalSince1970 * 3))

                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 55))
                    .foregroundColor(.green)
            }
            .frame(height: 150)

            Text("Estoy pensando en el personaje...")
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text("Analizando todas tus respuestas")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ThinkingDots()
                .padding(.top, 8)

            Spacer()
        }
        .padding()
        .onAppear {
            HapticManager.shared.impact(.medium)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                viewModel.confirmGuess()
            }
        }
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

                    VStack(spacing: 10) {
                        fuzzyAnswerButton(
                            title: "Sí",
                            icon: "checkmark.circle.fill",
                            color: .green,
                            answer: .yes
                        )

                        fuzzyAnswerButton(
                            title: "Probablemente sí",
                            icon: "hand.thumbsup.fill",
                            color: Color.green.opacity(0.7),
                            answer: .probablyYes
                        )

                        fuzzyAnswerButton(
                            title: "No sé",
                            icon: "questionmark.circle.fill",
                            color: .gray,
                            answer: .unknown
                        )

                        fuzzyAnswerButton(
                            title: "Probablemente no",
                            icon: "hand.thumbsdown.fill",
                            color: Color.orange,
                            answer: .probablyNo
                        )

                        fuzzyAnswerButton(
                            title: "No",
                            icon: "xmark.circle.fill",
                            color: .red,
                            answer: .no
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            if viewModel.questionsAskedCount < 15 {
                Text("Pregunta \(viewModel.questionsAskedCount + 1) de mínimo 15")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Pregunta \(viewModel.questionsAskedCount + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.isGenerating)
        .animation(.easeInOut(duration: 0.3), value: viewModel.questionsAskedCount)
    }

    private var errorContent: some View {
        VStack(spacing: 20) {
            Image(systemName: NetworkMonitor.shared.isConnected ? "exclamationmark.triangle" : "wifi.slash")
                .font(.system(size: 48))
                .foregroundColor(NetworkMonitor.shared.isConnected ? .orange : .red)
                .symbolEffect(.bounce, options: .nonRepeating)

            Text(NetworkMonitor.shared.isConnected ? "No se pudo generar la pregunta" : "Sin conexión")
                .font(.headline)

            Text(NetworkMonitor.shared.isConnected
                 ? "Hubo un problema al generar la pregunta. Inténtalo de nuevo."
                 : "Necesitas conexión a internet para generar preguntas con IA.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                HapticManager.shared.impact(.light)
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
                    HapticManager.shared.notification(.success)
                    viewModel.respondToGuess(correct: true)
                }

                AnswerButton(title: "No, no es", color: .red) {
                    HapticManager.shared.notification(.error)
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

    private func fuzzyAnswerButton(title: String, icon: String, color: Color, answer: AnswerType) -> some View {
        Button {
            HapticManager.shared.impact(.light)
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.answerQuestion(answer: answer)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
            )
        }
        .pressEffect()
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

// MARK: - Thinking Dots (for reveal animation)

private struct ThinkingDots: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .opacity(animating ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}
