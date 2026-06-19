import SwiftUI
import SwiftData
import Charts

struct GameDataPoint: Identifiable {
    let id = UUID()
    let index: Int
    let score: Int
    let won: Bool
    let questions: Int
    let date: Date
}

struct WinLossData: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    let color: Color
}

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var sessions: [SDGameSession] = []

    private var dataPoints: [GameDataPoint] {
        sessions.enumerated().map { index, session in
            GameDataPoint(index: index, score: session.score, won: session.won, questions: session.questionsAsked.count, date: session.timestamp)
        }
    }

    private var winLoss: [WinLossData] {
        let wins = sessions.filter { $0.won }.count
        let losses = sessions.filter { !$0.won }.count
        return [
            WinLossData(label: "Victorias", count: wins, color: .green),
            WinLossData(label: "Derrotas", count: losses, color: .red),
        ]
    }

    private var cumulativeScores: [(index: Int, total: Int)] {
        var total = 0
        return sessions.enumerated().map { i, s in
            total += s.score
            return (i, total)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                if sessions.isEmpty {
                    ContentUnavailableView("Sin partidas", systemImage: "chart.bar", description: Text("Juega algunas partidas para ver estadísticas"))
                        .padding(.top, 60)
                } else {
                    scoreChart
                    winLossChart
                    questionsChart
                    cumulativeChart
                }
            }
            .padding()
        }
        .navigationTitle("Estadísticas")
        .onAppear(perform: loadSessions)
        .refreshable { loadSessions() }
    }

    // MARK: - Score per Game

    private var scoreChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Puntuación por partida")
                .font(.headline)

            Chart {
                ForEach(dataPoints) { point in
                    BarMark(
                        x: .value("Partida", point.index + 1),
                        y: .value("Puntaje", point.score)
                    )
                    .foregroundStyle(point.won ? Color.green.gradient : Color.red.gradient)
                }
            }
            .frame(height: 200)
            .chartXAxisLabel("Partida")
            .chartYAxisLabel("Puntos")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Win / Loss

    private var winLossChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Victorias vs Derrotas")
                .font(.headline)

            Chart(winLoss) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(item.color)
                .annotation(position: .overlay) {
                    Text("\(item.count)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(height: 200)

            HStack(spacing: 24) {
                ForEach(winLoss) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 10, height: 10)
                        Text("\(item.label): \(item.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Questions per Game

    private var questionsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preguntas por partida")
                .font(.headline)

            Chart {
                ForEach(dataPoints) { point in
                    BarMark(
                        x: .value("Partida", point.index + 1),
                        y: .value("Preguntas", point.questions)
                    )
                    .foregroundStyle(Color.orange.gradient)
                }
            }
            .frame(height: 200)
            .chartXAxisLabel("Partida")
            .chartYAxisLabel("Preguntas")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Cumulative Score

    private var cumulativeChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Puntaje acumulado")
                .font(.headline)

            Chart {
                ForEach(cumulativeScores, id: \.index) { point in
                    LineMark(
                        x: .value("Partida", point.index + 1),
                        y: .value("Total", point.total)
                    )
                    .foregroundStyle(Color.orange.gradient)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Partida", point.index + 1),
                        y: .value("Total", point.total)
                    )
                    .foregroundStyle(Color.orange.opacity(0.1).gradient)
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 200)
            .chartXAxisLabel("Partida")
            .chartYAxisLabel("Puntos")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Data

    private func loadSessions() {
        let uid = AuthViewModel.shared.userUID ?? ""
        let predicate = #Predicate<SDGameSession> { session in
            session.userId == uid
        }
        let descriptor = FetchDescriptor<SDGameSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        sessions = (try? modelContext.fetch(descriptor)) ?? []
    }
}
