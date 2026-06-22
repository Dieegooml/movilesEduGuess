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
        ZStack {
            AppTheme.mainGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Picker("Filtro", selection: $filter) {
                    ForEach(SessionFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .colorMultiply(AppTheme.primaryGold)

                if filteredSessions.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "Sin partidas",
                        description: filter == .all
                            ? "Aún no has jugado ninguna partida. ¡Comienza ahora!"
                            : "No hay \(filter == .wins ? "victorias" : "derrotas") registradas.",
                        buttonTitle: filter == .all ? "Jugar ahora" : nil,
                        buttonAction: filter == .all ? { /* Navigation handled by parent */ } : nil
                    )
                } else {
                    List {
                        ForEach(filteredSessions) { session in
                            NavigationLink {
                                GameSessionDetailView(session: session)
                            } label: {
                                sessionRow(session)
                            }
                            .listRowBackground(AppTheme.cardSurface)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            }
        }
        .navigationTitle("Historial")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear(perform: loadSessions)
        .refreshable { loadSessions() }
    }

    private func sessionRow(_ session: SDGameSession) -> some View {
        HStack {
            Image(systemName: session.won ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(session.won ? AppTheme.successGreen : AppTheme.errorRed)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.characterName)
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                Text(session.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(AppTheme.mutedText)
            }

            Spacer()

            if session.won {
                Text("+\(session.score)")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryGold)
            }
        }
        .padding(.vertical, 4)
    }

    private func loadSessions() {
        let uid = AuthViewModel.shared.effectiveUserId
        let predicate = #Predicate<SDGameSession> { session in
            session.userId == uid
        }
        var descriptor = FetchDescriptor<SDGameSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\SDGameSession.timestamp, order: .reverse)]
        )
        sessions = (try? modelContext.fetch(descriptor)) ?? []
    }
}
