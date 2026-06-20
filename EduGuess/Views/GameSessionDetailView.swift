import SwiftUI

struct GameSessionDetailView: View {
    let session: SDGameSession

    private var pairedQA: [(String, String)] {
        Array(zip(session.questionsAsked, session.answers))
    }

    private func answerIconAndColor(for rawValue: String) -> (String, Color) {
        switch rawValue {
        case "yes": return ("checkmark.circle.fill", .green)
        case "probably_yes": return ("hand.thumbsup.fill", Color.green.opacity(0.7))
        case "unknown": return ("questionmark.circle.fill", .gray)
        case "probably_no": return ("hand.thumbsdown.fill", .orange)
        case "no": return ("xmark.circle.fill", .red)
        default: return ("questionmark.circle", .gray)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                scoreSection
                questionsSection
            }
            .padding()
        }
        .navigationTitle(session.characterName)
        .navigationBarTitleDisplayMode(.large)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: session.won ? "trophy.fill" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(session.won ? .yellow : .gray)

            Text(session.characterName)
                .font(.title2)
                .fontWeight(.bold)

            Label(session.won ? "Adivinado" : "No adivinado",
                  systemImage: session.won ? "checkmark.circle" : "xmark.circle")
                .foregroundColor(session.won ? .green : .red)
        }
    }

    private var scoreSection: some View {
        VStack(spacing: 8) {
            if session.won {
                Text("Puntaje")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("+\(session.score)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.orange)
            }

            HStack(spacing: 24) {
                statItem(title: "Preguntas", value: "\(session.questionsAsked.count)")
                statItem(title: "Fecha", value: session.timestamp.formatted(date: .numeric, time: .shortened))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preguntas realizadas")
                .font(.headline)
                .padding(.bottom, 4)

            ForEach(pairedQA.indices, id: \.self) { index in
                let (key, answerRaw) = pairedQA[index]
                let questionText = AttributeDefinition.pool
                    .first(where: { $0.key == key })?
                    .questionTemplates.first ?? key
                let (icon, color) = answerIconAndColor(for: answerRaw)

                HStack(alignment: .top) {
                    Text("\(index + 1).")
                        .foregroundColor(.secondary)
                        .frame(width: 24, alignment: .leading)

                    Text(questionText)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: icon)
                        .foregroundColor(color)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            }
        }
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
