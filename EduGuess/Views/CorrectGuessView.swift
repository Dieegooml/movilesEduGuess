import SwiftUI

struct CorrectGuessView: View {

    let characterName: String
    let characterImage: String
    let profile: [String: Bool]
    let askedAttributes: [String]
    let answers: [Bool]
    var isDailyChallenge: Bool = false
    var dailyCharacterName: String? = nil

    @Environment(\.modelContext) private var modelContext
    @State private var authVM = AuthViewModel.shared
    @State private var showContent = false
    @State private var toastMessage = ""
    @State private var toastIcon = "checkmark.circle.fill"
    @State private var showToast = false

    private var score: Int {
        GameScoring.calculateScore(questionsAsked: askedAttributes.count, won: true)
    }

    private var fallbackIcon: some View {
        Image(systemName: "checkmark.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 130, height: 130)
            .foregroundColor(.white)
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

                if !characterImage.isEmpty, let url = URL(string: characterImage) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 130, height: 130)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white, lineWidth: 3))
                                .shadow(radius: 6)
                        case .failure, .empty:
                            fallbackIcon
                        @unknown default:
                            fallbackIcon
                        }
                    }
                    .frame(width: 130, height: 130)
                    .scaleEffect(showContent ? 1 : 0.3)
                    .opacity(showContent ? 1 : 0)
                } else {
                    fallbackIcon
                }

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

                ShareLink(
                    item: "¡EduGuess adivinó a \(characterName) en \(askedAttributes.count) preguntas! 🎯\n\nDescarga la app: https://github.com/Dieegooml/movilesEduGuess",
                    subject: Text("EduGuess - adiviné a \(characterName)"),
                    message: Text("¡La IA adivinó a \(characterName) en \(askedAttributes.count) preguntas!")
                ) {
                    Label("Compartir", systemImage: "square.and.arrow.up")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.25))
                        .cornerRadius(18)
                }
                .offset(y: showContent ? 0 : 20)
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
                .padding(.bottom, isDailyChallenge ? 8 : 40)
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)

            if isDailyChallenge {
                NavigationLink {
                    DailyLeaderboardView()
                } label: {
                    Text("Ver ranking del día")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(18)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)
            }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
        }
        .navigationBarBackButtonHidden(true)
        .toast(message: toastMessage, icon: toastIcon, isShowing: $showToast)
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
        toastMessage = "Partida guardada"
        toastIcon = "checkmark.circle.fill"
        guard let uid = authVM.userUID else {
            withAnimation { showToast = true }
            return
        }
        Task {
            let ok = await service.saveSessionToFirestore(
                characterName: characterName,
                characterAttributes: profile,
                questionsAsked: askedAttributes,
                answers: answers,
                won: true,
                userId: uid,
                userName: authVM.userName,
                score: score
            )
            await MainActor.run {
                if !ok {
                    toastMessage = "Error al guardar en la nube"
                    toastIcon = "exclamationmark.circle.fill"
                }
                withAnimation { showToast = true }
            }
        }
    }
}

struct CorrectGuessView_Previews: PreviewProvider {
    static var previews: some View {
        CorrectGuessView(
            characterName: "Harry Potter",
            characterImage: "",
            profile: ["usesMagic": true],
            askedAttributes: ["usesMagic"],
            answers: [true]
        )
    }
}
