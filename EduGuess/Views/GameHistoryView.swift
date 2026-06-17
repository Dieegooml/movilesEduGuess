import SwiftUI
import SwiftData

struct GameHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var sessions: [SDGameSession] = []
    @State private var filter: SessionFilter = .all

    enum SessionFilter: String, CaseIterable {
        case all = "Todas"
        case wins = "Victorias"
        case losses = "Derrotas"
    }

    var filteredSessions: [SDGameSession] {
        switch filter {
        case .all: return sessions
        case .wins: return sessions.filter { $0.won }
        case .losses: return sessions.filter { !$0.won }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Filtro", selection: $filter) {
                ForEach(SessionFilter.allCases, id: \.self) { f in
                    Text(f.rawValue).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            if filteredSessions.isEmpty {
                ContentUnavailableView(
                    "Sin partidas",
                    systemImage: "clock.arrow.circlepath",
                    description: Text(filter == .all ? "Aún no has jugado ninguna partida" : "No hay \(filter == .wins ? "victorias" : "derrotas") registradas")
                )
            } else {
                List {
                    ForEach(filteredSessions) { session in
                        NavigationLink {
                            GameSessionDetailView(session: session)
                        } label: {
                            sessionRow(session)
                        }
                    }
                }
            }
        }
        .navigationTitle("Historial")
        .onAppear(perform: loadSessions)
    }

    private func sessionRow(_ session: SDGameSession) -> some View {
        HStack {
            Image(systemName: session.won ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(session.won ? .green : .red)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.characterName)
                    .font(.headline)
                Text(session.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if session.won {
                Text("+\(session.score)")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }

    private func loadSessions() {
        let descriptor = FetchDescriptor<SDGameSession>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        sessions = (try? modelContext.fetch(descriptor)) ?? []
    }
}
