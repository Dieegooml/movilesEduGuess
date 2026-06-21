import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    private let steps: [(icon: String, title: String, text: String)] = [
        ("person.fill.questionmark",
         "Piensa en un personaje",
         "Elige un personaje real o ficticio que la IA intentará adivinar. Puede ser peruano, latinoamericano o de cualquier parte del mundo."),
        ("hand.raised.fill",
         "Responde Sí / No / No sé",
         "La IA te hará preguntas sobre tu personaje. Responde con sinceridad. Si no estás seguro, usa 'No sé' para saltar la pregunta."),
        ("brain.head.profile",
         "La IA intenta adivinar",
         "Cuando la IA crea tener suficiente información, hará un intento de adivinanza. Si acierta, ¡ganas puntos! Si no, puedes enseñarle el personaje correcto."),
        ("trophy.fill",
         "Gana puntos y sube en el ranking",
         "Cada victoria te da puntos. Mientras menos preguntas necesite la IA, más puntos ganas. Revisa tu progreso en Mi Perfil y el Ranking."),
    ]

    var body: some View {
        ZStack {
            AppTheme.mainGradient
                .ignoresSafeArea()

            TabView {
                ForEach(steps.indices, id: \.self) { index in
                    stepView(step: steps[index], isLast: index == steps.count - 1)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .navigationTitle("¿Cómo jugar?")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Listo") { dismiss() }
                    .foregroundColor(AppTheme.primaryYellow)
            }
        }
    }

    private func stepView(step: (icon: String, title: String, text: String), isLast: Bool) -> some View {
        VStack(spacing: 30) {
            Spacer()

            PetAvatarView(emotion: .idea, size: 120)

            Image(systemName: step.icon)
                .font(.system(size: 70))
                .foregroundColor(AppTheme.primaryYellow)

            Text(step.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(step.text)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.secondaryText)
                .padding(.horizontal, 40)

            Spacer()

            if isLast {
                Button {
                    dismiss()
                } label: {
                    Text("¡Empezar a jugar!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.primaryOrange)
                        .frame(maxWidth: 220)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                }
                .padding(.bottom, 40)
            }
        }
    }
}
