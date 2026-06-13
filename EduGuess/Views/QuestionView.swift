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

    var body: some View {

        NavigationStack {
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
            }
            .padding()
            .navigationDestination(isPresented: $correctDestinationActive) {
                CorrectGuessView(characterName: viewModel.guessedCharacter?.name ?? "Desconocido")
            }
            .navigationDestination(isPresented: $wrongDestinationActive) {
                WrongGuessView()
            }
        }
        .onAppear {
            // load data from SwiftData
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

    private func loadDataFromSwiftData() {
        let dataService = DataService()
        
        // ensure default data exists
        dataService.saveDefaultDataIfNeeded(context: modelContext)
        
        // fetch and load data
        let characters = dataService.fetchCharacters(context: modelContext)
        let questions = dataService.fetchQuestions(context: modelContext)
        
        if !characters.isEmpty && !questions.isEmpty {
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
 
