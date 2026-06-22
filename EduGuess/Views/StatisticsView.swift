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
    @State private var dataPoints: [GameDataPoint] = []
    @State private var winLoss: [WinLossData] = []
    @State private var cumulativeScores: [(index: Int, total: Int)] = []

    var body: some View {
        ZStack {
            AppTheme.mainGradient.ignoresSafeArea()

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
        }
        .navigationTitle("Estadísticas")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear(perform: loadSessions)
        .refreshable { loadSessions() }
    }

    // MARK: - Score per Game

    private var scoreChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Puntuación por partida")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)

            Chart {
                ForEach(dataPoints) { point in
                    BarMark(
                        x: .value("Partida", point.index + 1),
                        y: .value("Puntaje", point.score)
                    )
                    .foregroundStyle(point.won ? AppTheme.successGreen.gradient : AppTheme.errorRed.gradient)
                }
            }
            .frame(height: 200)
            .chartXAxisLabel("Partida")
            .chartYAxisLabel("Puntos")
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(AppTheme.divider)
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(AppTheme.divider)
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }
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

    // MARK: - Win / Loss

    private var winLossChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Victorias vs Derrotas")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)

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
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
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

    // MARK: - Questions per Game

    private var questionsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preguntas por partida")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)

            Chart {
                ForEach(dataPoints) { point in
                    BarMark(
                        x: .value("Partida", point.index + 1),
                        y: .value("Preguntas", point.questions)
                    )
                    .foregroundStyle(AppTheme.primaryOrange.gradient)
                }
            }
            .frame(height: 200)
            .chartXAxisLabel("Partida")
            .chartYAxisLabel("Preguntas")
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(AppTheme.divider)
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(AppTheme.divider)
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }
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

    // MARK: - Cumulative Score

    private var cumulativeChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Puntaje acumulado")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)

            Chart {
                ForEach(cumulativeScores, id: \.index) { point in
                    LineMark(
                        x: .value("Partida", point.index + 1),
                        y: .value("Total", point.total)
                    )
                    .foregroundStyle(AppTheme.primaryGold.gradient)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Partida", point.index + 1),
                        y: .value("Total", point.total)
                    )
                    .foregroundStyle(AppTheme.primaryGold.opacity(0.1).gradient)
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 200)
            .chartXAxisLabel("Partida")
            .chartYAxisLabel("Puntos")
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(AppTheme.divider)
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(AppTheme.divider)
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }
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

    // MARK: - Data

    private func loadSessions() {
        let uid = AuthViewModel.shared.effectiveUserId
        let predicate = #Predicate<SDGameSession> { session in
            session.userId == uid
        }
        let descriptor = FetchDescriptor<SDGameSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        sessions = (try? modelContext.fetch(descriptor)) ?? []

        dataPoints = sessions.enumerated().map { index, session in
            GameDataPoint(index: index, score: session.score, won: session.won, questions: session.questionsAsked.count, date: session.timestamp)
        }

        let wins = sessions.filter { $0.won }.count
        let losses = sessions.filter { !$0.won }.count
        winLoss = [
            WinLossData(label: "Victorias", count: wins, color: AppTheme.successGreen),
            WinLossData(label: "Derrotas", count: losses, color: AppTheme.errorRed),
        ]

        var total = 0
        cumulativeScores = sessions.enumerated().map { i, s in
            total += s.score
            return (i, total)
        }
    }
}
