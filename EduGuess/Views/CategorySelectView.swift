import SwiftUI
import SwiftData

struct CategorySelectView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var allCharacters: [Character] = []

    private let filters: [(name: String, icon: String, predicate: ([String: Bool]) -> Bool)] = [
        ("Todas", "globe", { _ in true }),
        ("Peruanos", "flag.fill", { $0["isFromPeru"] == true }),
        ("Latinoamericanos", "map.fill", { $0["isLatinAmerican"] == true || $0["isFromPeru"] == true }),
        ("Reales", "person.fill", { $0["isReal"] == true }),
        ("Ficticios", "sparkles", { $0["isFictional"] == true }),
        ("Películas y TV", "tv.fill", { $0["isFromMovie"] == true || $0["isFromTV"] == true }),
        ("Videojuegos", "gamecontroller.fill", { $0["isFromVideoGame"] == true }),
        ("Superhéroes", "bolt.shield.fill", { $0["isSuperhero"] == true }),
        ("Históricos", "book.fill", { $0["isHistorical"] == true }),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Elige una categoría")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                Text("Filtra los personajes antes de empezar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(filters.indices, id: \.self) { index in
                        let filter = filters[index]
                        NavigationLink {
                            let filtered = applyFilter(filter.predicate)
                            QuestionView(preloadedCharacters: filtered)
                        } label: {
                            filterCard(name: filter.name, icon: filter.icon, index: index)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Filtrar")
        .onAppear(perform: loadCharacters)
    }

    private func filterCard(name: String, icon: String, index: Int) -> some View {
        let colors: [Color] = [.orange, .red, .blue, .green, .purple, .pink, .teal, .indigo, .mint]
        let color = colors[index % colors.count]

        return VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(name)
                .font(.headline)
                .foregroundColor(.primary)

            let count = allCharacters.filter { filters[index].predicate($0.attributes) }.count
            Text("\(count) personajes")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }

    private func loadCharacters() {
        let service = DataService()
        allCharacters = service.fetchCharacters(context: modelContext)
    }

    private func applyFilter(_ predicate: ([String: Bool]) -> Bool) -> [Character] {
        allCharacters.filter { predicate($0.attributes) }
    }
}
