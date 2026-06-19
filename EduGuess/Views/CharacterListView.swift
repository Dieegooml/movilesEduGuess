import SwiftUI
import SwiftData

struct CharacterListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var characters: [Character] = []

    var filteredCharacters: [Character] {
        guard !searchText.isEmpty else { return characters }
        return characters.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            ForEach(filteredCharacters, id: \.id) { character in
                NavigationLink {
                    CharacterDetailView(character: character)
                } label: {
                    HStack {
                        Circle()
                            .fill(Color.orange.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(character.name.prefix(1)))
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            )
                        Text(character.name)
                            .font(.body)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Buscar personaje")
        .navigationTitle("Personajes")
        .onAppear(perform: loadCharacters)
        .refreshable { loadCharacters() }
    }

    private func loadCharacters() {
        let service = DataService()
        characters = service.fetchCharacters(context: modelContext)
    }
}
