import SwiftUI

struct CorrectGuessView: View {

    let characterName: String
    let profile: [String: Bool]
    let askedAttributes: [String]
    let answers: [Bool]
    var isDailyChallenge: Bool = false
    var dailyCharacterName: String? = nil

    @Environment(\.modelContext) private var modelContext
    @State private var authVM = AuthViewModel.shared
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var celebratePulse = false
    @State private var toastMessage = ""
    @State private var toastIcon = "checkmark.circle.fill"
    @State private var showToast = false

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

            if showConfetti {
                ConfettiView(count: 40)
                    .transition(.opacity)
            }

            VStack(spacing: 25) {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .foregroundColor(.white)
                    .scaleEffect(celebratePulse ? 1.15 : (showContent ? 1 : 0.3))
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
            withAnimation(.interpolatingSpring(stiffness: 150, damping: 10)) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.3).repeatCount(2, autoreverses: true)) {
                    celebratePulse = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeIn(duration: 0.5)) {
                    showConfetti = true
                }
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
            profile: ["usesMagic": true],
            askedAttributes: ["usesMagic"],
            answers: [true]
        )
    }
}

// MARK: - Confetti Celebration Animation

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let x: CGFloat
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let spin: Double
    let delay: Double
    let shape: Int
}

struct ConfettiView: View {
    private let pieces: [ConfettiPiece]

    init(count: Int = 40) {
        let screenWidth = UIScreen.main.bounds.width
        var generated: [ConfettiPiece] = []
        let colors: [Color] = [
            .red, .blue, .green, .yellow, .orange, .purple,
            .pink, .teal, .mint, .cyan, .indigo
        ]
        for i in 0..<count {
            generated.append(ConfettiPiece(
                x: CGFloat.random(in: 0...screenWidth),
                color: colors[i % colors.count],
                width: CGFloat.random(in: 6...12),
                height: CGFloat.random(in: 6...18),
                spin: Double.random(in: -720...720),
                delay: Double(i) * 0.06,
                shape: Int.random(in: 0...2)
            ))
        }
        pieces = generated
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(pieces) { piece in
                PieceView(piece: piece, screenHeight: geo.size.height)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct PieceView: View {
    let piece: ConfettiPiece
    let screenHeight: CGFloat

    @State private var isAnimating = false

    var body: some View {
        shapeView
            .foregroundColor(piece.color)
            .frame(width: piece.width, height: piece.height)
            .position(x: piece.x, y: isAnimating ? screenHeight + 60 : -30)
            .rotationEffect(.degrees(isAnimating ? piece.spin : 0))
            .opacity(isAnimating ? 0.15 : 1)
            .animation(
                .easeOut(duration: 2.8 + Double.random(in: 0...0.5))
                .delay(piece.delay),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }

    @ViewBuilder
    private var shapeView: some View {
        switch piece.shape % 3 {
        case 0:
            Rectangle()
        case 1:
            RoundedRectangle(cornerRadius: piece.width / 2)
        default:
            Rectangle()
                .rotationEffect(.degrees(45))
        }
    }
}
