import SwiftUI

struct CorrectGuessView: View {

    let characterName: String
    let profile: [String: Bool]
    let askedAttributes: [String]
    let answers: [Bool]

    @Environment(\.modelContext) private var modelContext
    @State private var authVM = AuthViewModel.shared
    @State private var showContent = false

    private var score: Int {
        GameScoring.calculateScore(questionsAsked: askedAttributes.count, won: true)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.green, Color.teal],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .foregroundColor(.white)
                    .scaleEffect(showContent ? 1 : 0.3)
                    .opacity(showContent ? 1 : 0)

                Text("¡Lo adiviné!")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.white)
                    .offset(y: showContent ? 0 : 20)
                    .opacity(showContent ? 1 : 0)

                Text("Tu personaje es \(characterName)")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.95))
                    .padding(.horizontal)
                    .offset(y: showContent ? 0 : 20)
                    .opacity(showContent ? 1 : 0)

                Text("Me tomó \(askedAttributes.count) preguntas")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .offset(y: showContent ? 0 : 20)
                    .opacity(showContent ? 1 : 0)

                Text("+\(score) puntos")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                    .padding(.top, 8)
                    .scaleEffect(showContent ? 1 : 1.5)
                    .opacity(showContent ? 1 : 0)

                Spacer()

                NavigationLink {
                    HomeView()
                } label: {
                    Text("Jugar otra vez")
                        .font(.headline)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(18)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
            saveSession()
        }
    }

    private func saveSession() {
        let service = DataService()
        service.saveGameSession(
            characterName: characterName,
            characterAttributes: profile,
            questionsAsked: askedAttributes,
            answers: answers,
            won: true,
            userId: authVM.userUID ?? "",
            userName: authVM.userName,
            score: score,
            context: modelContext
        )
        guard let uid = authVM.userUID else { return }
        service.saveSessionToFirestore(
            characterName: characterName,
            characterAttributes: profile,
            questionsAsked: askedAttributes,
            answers: answers,
            won: true,
            userId: uid,
            userName: authVM.userName,
            score: score
        )
    }
}

struct CorrectGuessView_Previews: PreviewProvider {
    static var previews: some View {
        CorrectGuessView(
            characterName: "Harry Potter",
            profile: ["usesMagic": true],
            askedAttributes: ["usesMagic"],
            answers: [true]
        )
    }
}
