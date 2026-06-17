import SwiftUI
import SwiftData

struct QuestionView: View {

    @StateObject private var viewModel = GameViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var correctDestinationActive = false
    @State private var wrongDestinationActive = false
    @State private var isLoading = true

    let preloadedCharacters: [Character]?

    init(preloadedCharacters: [Character]? = nil) {
        self.preloadedCharacters = preloadedCharacters
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
                answers: viewModel.givenAnswers
            )
        }
        .navigationDestination(isPresented: $wrongDestinationActive) {
            WrongGuessView(
                profile: viewModel.finalProfile,
                askedAttributes: viewModel.askedAttributeKeys,
                answers: viewModel.givenAnswers
            )
        }
        .onAppear {
            loadDataFromSwiftData()
        }
        .onChange(of: viewModel.gameState) { newState in
            switch newState {
            case .guessed:
                correctDestinationActive = true
            case .failed:
                wrongDestinationActive = true
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
                .foregroundColor(.gray)
            Spacer()
        }
    }

    private var gameContent: some View {
        VStack(spacing: 24) {
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
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.answerQuestion(answer: .yes)
                    }
                }

                AnswerButton(title: "No", color: .red) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.answerQuestion(answer: .no)
                    }
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.answerQuestion(answer: .unknown)
                    }
                } label: {
                    Text("No sé")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1.5)
                        )
                }
            }
            .padding(.horizontal)

            Text("Pregunta \(viewModel.questionsAskedCount + 1)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.questionsAskedCount)
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
                .foregroundColor(.gray)
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
        viewModel.startNewGame(characters: characters)
    }

    private var progressValue: CGFloat {
        let asked = viewModel.questionsAskedCount
        let total = asked + viewModel.remainingAttributes
        guard total > 0 else { return 0 }
        return CGFloat(asked) / CGFloat(total)
    }
}

struct QuestionView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionView()
    }
}
