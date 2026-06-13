//
//  QuestionView.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import SwiftUI
import SwiftData

struct QuestionView: View {

    @StateObject private var viewModel = GameViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var correctDestinationActive = false
    @State private var wrongDestinationActive = false
    @State private var errorMessage: String = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            if viewModel.hasValidData {
                gameContent
            } else {
                emptyStateContent
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
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .navigationBarBackButtonHidden(false)
    }

    private var gameContent: some View {
        VStack(spacing: 24) {
            Spacer()

            RobotAvatar()

            ProgressBar(progress: progressValue)
                .frame(height: 40)

            QuestionCard(question: viewModel.currentQuestion.text)

            VStack(spacing: 12) {
                AnswerButton(title: "Sí", color: .green) {
                    viewModel.answerQuestion(answer: true)
                }

                AnswerButton(title: "No", color: .red) {
                    viewModel.answerQuestion(answer: false)
                }
            }
            .padding(.horizontal)

            Spacer()

            navigationDestinations
        }
        .padding()
    }

    private var emptyStateContent: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.orange)

            Text("No hay datos disponibles")
                .font(.headline)
                .foregroundColor(.black)

            Text("Debes agregar personajes y preguntas desde la base de datos antes de jugar.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            NavigationLink {
                HomeView()
            } label: {
                Text("Volver al inicio")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(18)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }

    @ViewBuilder
    private var navigationDestinations: some View {
        NavigationLink(
            destination: CorrectGuessView(characterName: viewModel.guessedCharacter?.name ?? "Desconocido"),
            isActive: $correctDestinationActive
        ) { EmptyView() }

        NavigationLink(
            destination: WrongGuessView(),
            isActive: $wrongDestinationActive
        ) { EmptyView() }
    }

    private func loadDataFromSwiftData() {
        let dataService = DataService()

        // Fetch data from SwiftData
        let characters = dataService.fetchCharacters(context: modelContext)
        let questions = dataService.fetchQuestions(context: modelContext)

        if characters.isEmpty || questions.isEmpty {
            errorMessage = "Base de datos vacía. Agrega personajes y preguntas primero."
            showError = false // No mostramos alert, el UI muestra el mensaje
        } else {
            viewModel.loadData(characters: characters, questions: questions)
        }
    }

    private var progressValue: CGFloat {
        let total = CGFloat(max(viewModel.questions.count, 1))
        return CGFloat(viewModel.currentQuestionIndex) / total
    }
}

struct QuestionView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionView()
    }
}
 
