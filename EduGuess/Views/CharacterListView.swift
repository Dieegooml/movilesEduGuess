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
        ZStack {
            AppTheme.mainGradient.ignoresSafeArea()

            List {
                ForEach(filteredCharacters, id: \.id) { character in
                    NavigationLink {
                        CharacterDetailView(character: character)
                    } label: {
                        HStack {
                            Circle()
                                .fill(AppTheme.primaryGold.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(character.name.prefix(1)))
                                        .font(.headline)
                                        .foregroundColor(AppTheme.primaryGold)
                                )
                            Text(character.name)
                                .font(.body)
                                .foregroundColor(AppTheme.primaryText)
                        }
                    }
                    .listRowBackground(AppTheme.cardSurface)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .searchable(text: $searchText, prompt: "Buscar personaje")
        }
        .navigationTitle("Personajes")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear(perform: loadCharacters)
        .refreshable { loadCharacters() }
    }

    private func loadCharacters() {
        let service = DataService()
        characters = service.fetchCharacters(context: modelContext)
    }
}
