import SwiftUI
import SwiftData

struct QuestionView: View {

    @StateObject private var viewModel = GameViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var correctDestinationActive = false
    @State private var wrongDestinationActive = false
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            if isLoading {
                loadingContent
            } else {
                gameContent
            }
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
        .navigationBarBackButtonHidden(false)
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

            navigationDestinations
        }
        .padding()
    }

    // MARK: - Normal Question Mode

    private var questionContent: some View {
        VStack(spacing: 16) {
            QuestionCard(question: viewModel.currentQuestion)

            VStack(spacing: 12) {
                AnswerButton(title: "Sí", color: .green) {
                    viewModel.answerQuestion(answer: .yes)
                }

                AnswerButton(title: "No", color: .red) {
                    viewModel.answerQuestion(answer: .no)
                }

                Button {
                    viewModel.answerQuestion(answer: .unknown)
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

            Text("Pregunta \(viewModel.questionsAskedCount + 1) de \(viewModel.maxQuestions)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    // MARK: - Guess Attempt Mode

    private var guessContent: some View {
        VStack(spacing: 16) {
            QuestionCard(question: "¿Es \(viewModel.guessCandidate?.name ?? "...")?")

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
    }

    // MARK: - Navigation

    @ViewBuilder
    private var navigationDestinations: some View {
        NavigationLink(
            destination: CorrectGuessView(
                characterName: viewModel.guessedCharacter?.name ?? "Desconocido",
                profile: viewModel.finalProfile,
                askedAttributes: viewModel.askedAttributeKeys,
                answers: viewModel.givenAnswers,
                maxQuestions: viewModel.maxQuestions
            ),
            isActive: $correctDestinationActive
        ) { EmptyView() }

        NavigationLink(
            destination: WrongGuessView(
                profile: viewModel.finalProfile,
                askedAttributes: viewModel.askedAttributeKeys,
                answers: viewModel.givenAnswers
            ),
            isActive: $wrongDestinationActive
        ) { EmptyView() }
    }

    // MARK: - Data

    private func loadDataFromSwiftData() {
        let dataService = DataService()
        let characters = dataService.fetchCharacters(context: modelContext)

        isLoading = false
        viewModel.startNewGame(characters: characters)
    }

    private var progressValue: CGFloat {
        let total = CGFloat(max(viewModel.maxQuestions, 1))
        return CGFloat(viewModel.questionsAskedCount) / total
    }
}

struct QuestionView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionView()
    }
}
