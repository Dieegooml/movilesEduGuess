import SwiftUI

struct WrongGuessView: View {

    let profile: [String: Bool]
    let askedAttributes: [String]
    let answers: [Bool]
    var isDailyChallenge: Bool = false
    var dailyCharacterName: String? = nil

    @Environment(\.modelContext) private var modelContext
    @State private var authVM = AuthViewModel.shared
    @State private var characterName: String = ""
    @State private var didSave = false
    @State private var showToast = false

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [Color.red, Color.orange],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {

                Spacer()

                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .foregroundColor(.white)

                Text("No pude adivinar")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Ayúdame a aprender")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))

                if !didSave {
                    VStack(spacing: 12) {
                        TextField("¿Qué personaje era?", text: $characterName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                            .disableAutocorrection(false)
                            .padding(.horizontal, 30)

                        Button {
                            saveLearnedCharacter()
                        } label: {
                            Text("Guardar y aprender")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(18)
                        }
                        .disabled(characterName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .padding(.horizontal, 30)
                    }
                } else {
                    Text("¡Gracias! Lo recordaré para la próxima 🧠")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                NavigationLink {
                    HomeView()
                } label: {
                    Text("Intentar otra vez")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(18)
                }
                .padding(.horizontal, 30)

                if didSave {
                    ShareLink(
                        item: "Jugué EduGuess y la IA no adivinó mi personaje. ¿Puedes tú hacerlo mejor? 🧠\n\nDescarga la app: https://github.com/Dieegooml/movilesEduGuess",
                        subject: Text("EduGuess - ¿puedes adivinar mi personaje?"),
                        message: Text("¡Juega EduGuess y reta a la IA!")
                    ) {
                        Label("Compartir", systemImage: "square.and.arrow.up")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.25))
                            .cornerRadius(18)
                    }
                }

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
                }

                Spacer().frame(height: 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toast(message: "Personaje aprendido", icon: "book.fill", isShowing: $showToast)
    }

    private func saveLearnedCharacter() {
        let name = characterName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let service = DataService()
        service.saveLearnedCharacter(name: name, attributes: profile, context: modelContext)

        service.saveGameSession(
            characterName: name,
            characterAttributes: profile,
            questionsAsked: askedAttributes,
            answers: answers,
            won: false,
            userId: authVM.userUID ?? "",
            userName: authVM.userName,
            score: 0,
            context: modelContext
        )

        guard let uid = authVM.userUID else {
            withAnimation { didSave = true }
            return
        }
        service.saveSessionToFirestore(
            characterName: name,
            characterAttributes: profile,
            questionsAsked: askedAttributes,
            answers: answers,
            won: false,
            userId: uid,
            userName: authVM.userName,
            score: 0
        )

        withAnimation {
            didSave = true
            showToast = true
        }
    }
}

struct WrongGuessView_Previews: PreviewProvider {
    static var previews: some View {
        WrongGuessView(
            profile: ["isReal": false, "usesMagic": true],
            askedAttributes: ["isReal", "usesMagic"],
            answers: [false, true]
        )
    }
}
