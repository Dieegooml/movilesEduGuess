import SwiftUI
import SwiftData

struct WrongGuessView: View {

    let profile: [String: Bool]
    let askedAttributes: [String]
    let answers: [AnswerType]
    var isDailyChallenge: Bool = false
    var dailyCharacterName: String? = nil

    @Environment(\.modelContext) private var modelContext
    @State private var authVM = AuthViewModel.shared
    @State private var characterName: String = ""
    @State private var didSave = false
    @State private var toastMessage = "Personaje aprendido"
    @State private var toastIcon = "book.fill"
    @State private var showToast = false
    @State private var savedName = ""
    @State private var savedAttributes: [String: Bool] = [:]
    @State private var showCompletionForm = false
    @State private var isSaving = false

    @State private var showContent = false

    var body: some View {

        ZStack {

            AppTheme.errorGradient
                .ignoresSafeArea()
                .onTapGesture { UIApplication.shared.endEditing() }

            PetFloatingBackground()
                .offset(x: 80, y: 80)

            VStack(spacing: 25) {

                Spacer()

                PetAvatarView(emotion: .angry, size: 160)
                    .scaleEffect(showContent ? 1 : 0.5)
                    .opacity(showContent ? 1 : 0)

                Text("No pude adivinar")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .offset(y: showContent ? 0 : 20)
                    .opacity(showContent ? 1 : 0)

                Text("Ayúdame a aprender")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .offset(y: showContent ? 0 : 20)
                    .opacity(showContent ? 1 : 0)

                if isDailyChallenge, let name = dailyCharacterName {
                    VStack(spacing: 12) {
                        Text("El personaje era:")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Text(name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                } else if !didSave {
                    VStack(spacing: 12) {
                        TextField("¿Qué personaje era?", text: $characterName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                            .disableAutocorrection(false)
                            .padding(.horizontal, 30)

                        Button {
                            saveLearnedCharacter()
                        } label: {
                            Text(isSaving ? "Guardando..." : "Guardar y aprender")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "BE123C"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(18)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .disabled(characterName.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                        .padding(.horizontal, 30)
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("¡Gracias! Lo recordaré para la próxima 🧠")
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button {
                            showCompletionForm = true
                        } label: {
                            Text("Completar perfil del personaje")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.25))
                                .cornerRadius(18)
                        }
                        .padding(.horizontal, 30)
                    }
                }

                Spacer()

                NavigationLink {
                    HomeView()
                } label: {
                    Text("Intentar otra vez")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "BE123C"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 30)

                if didSave && !isDailyChallenge {
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
        .toast(message: toastMessage, icon: toastIcon, isShowing: $showToast)
        .onAppear {
            HapticManager.shared.notification(.error)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
        .sheet(isPresented: $showCompletionForm) {
            NavigationStack {
                CharacterFormView(
                    initialName: savedName,
                    initialAttributes: savedAttributes,
                    onSave: { name, attrs in
                        updateCharacterAttributes(name: name, attributes: attrs)
                        showCompletionForm = false
                    }
                )
            }
        }
    }

    private func saveLearnedCharacter() {
        guard !isSaving else { return }
        let name = characterName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        isSaving = true
        let service = DataService()
        service.saveLearnedCharacter(name: name, attributes: profile, context: modelContext)

        service.saveGameSession(
            characterName: name,
            characterAttributes: profile,
            questionsAsked: askedAttributes,
            answers: answers.map { $0.rawValue },
            won: false,
            userId: authVM.userUID ?? "",
            userName: authVM.userName,
            score: 0,
            context: modelContext
        )

        savedName = name
        savedAttributes = profile
        toastMessage = "Personaje aprendido"
        toastIcon = "book.fill"

        guard let uid = authVM.userUID else {
            withAnimation { didSave = true; showToast = true }
            isSaving = false
            return
        }
        Task {
            let ok = await service.saveSessionToFirestore(
                characterName: name,
                characterAttributes: profile,
                questionsAsked: askedAttributes,
                answers: answers.map { $0.rawValue },
                won: false,
                userId: uid,
                userName: authVM.userName,
                score: 0
            )
            await MainActor.run {
                if !ok {
                    toastMessage = "Error al guardar en la nube"
                    toastIcon = "exclamationmark.circle.fill"
                }
                withAnimation { didSave = true; showToast = true }
                isSaving = false
            }
        }
    }

    private func updateCharacterAttributes(name: String, attributes: [String: Bool]) {
        let service = DataService()
        let descriptor = FetchDescriptor<SDCharacter>(
            predicate: #Predicate { $0.name == name }
        )
        guard let existing = try? modelContext.fetch(descriptor),
              let sdCharacter = existing.first else { return }
        sdCharacter.attributes = attributes
        try? modelContext.save()
    }
}

struct WrongGuessView_Previews: PreviewProvider {
    static var previews: some View {
        WrongGuessView(
            profile: ["isReal": false, "usesMagic": true],
            askedAttributes: ["isReal", "usesMagic"],
            answers: [.no, .yes]
        )
    }
}
