import SwiftUI

struct GameSessionDetailView: View {
    let session: SDGameSession

    private var pairedQA: [(String, String)] {
        Array(zip(session.questionsAsked, session.answers))
    }

    private func answerIconAndColor(for rawValue: String) -> (String, Color) {
        switch rawValue {
        case "yes": return ("checkmark.circle.fill", AppTheme.successGreen)
        case "probably_yes": return ("hand.thumbsup.fill", AppTheme.successGreen.opacity(0.7))
        case "unknown": return ("questionmark.circle.fill", AppTheme.mutedText)
        case "probably_no": return ("hand.thumbsdown.fill", AppTheme.warningOrange)
        case "no": return ("xmark.circle.fill", AppTheme.errorRed)
        default: return ("questionmark.circle", AppTheme.mutedText)
        }
    }

    var body: some View {
        ZStack {
            AppTheme.mainGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    scoreSection
                    questionsSection
                }
                .padding()
            }
        }
        .navigationTitle(session.characterName)
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: session.won ? "trophy.fill" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(session.won ? AppTheme.primaryGold : AppTheme.mutedText)

            Text(session.characterName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)

            Label(session.won ? "Adivinado" : "No adivinado",
                  systemImage: session.won ? "checkmark.circle" : "xmark.circle")
                .foregroundColor(session.won ? AppTheme.successGreen : AppTheme.errorRed)
        }
    }

    private var scoreSection: some View {
        VStack(spacing: 8) {
            if session.won {
                Text("Puntaje")
                    .font(.headline)
                    .foregroundColor(AppTheme.secondaryText)

                Text("+\(session.score)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(AppTheme.primaryGold)
            }

            HStack(spacing: 24) {
                statItem(title: "Preguntas", value: "\(session.questionsAsked.count)")
                statItem(title: "Fecha", value: session.timestamp.formatted(date: .numeric, time: .shortened))
            }
        }
        .padding()
        .background(AppTheme.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
        .cornerRadius(16)
    }

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preguntas realizadas")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
                .padding(.bottom, 4)

            ForEach(pairedQA.indices, id: \.self) { index in
                let (key, answerRaw) = pairedQA[index]
                let questionText = AttributeDefinition.pool
                    .first(where: { $0.key == key })?
                    .questionTemplates.first ?? key
                let (icon, color) = answerIconAndColor(for: answerRaw)

                HStack(alignment: .top) {
                    Text("\(index + 1).")
                        .foregroundColor(AppTheme.mutedText)
                        .frame(width: 24, alignment: .leading)

                    Text(questionText)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: icon)
                        .foregroundColor(color)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(AppTheme.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
                .cornerRadius(8)
            }
        }
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.primaryText)
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
    }
}
