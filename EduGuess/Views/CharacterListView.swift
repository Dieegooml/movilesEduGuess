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
                        characterThumbnail(character)
                        Text(character.name)
                            .font(.body)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Buscar personaje")
        .navigationTitle("Personajes")
        .onAppear(perform: loadCharacters)
    }

    @ViewBuilder
    private func characterThumbnail(_ character: Character) -> some View {
        if !character.image.isEmpty, let url = URL(string: character.image) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                case .failure:
                    fallbackCircle(character)
                case .empty:
                    ProgressView().tint(.orange)
                @unknown default:
                    fallbackCircle(character)
                }
            }
            .frame(width: 40, height: 40)
        } else {
            fallbackCircle(character)
        }
    }

    private func fallbackCircle(_ character: Character) -> some View {
        Circle()
            .fill(Color.orange.opacity(0.3))
            .frame(width: 40, height: 40)
            .overlay(
                Text(String(character.name.prefix(1)))
                    .font(.caption)
                    .foregroundColor(.orange)
            )
    }

    private func loadCharacters() {
        let service = DataService()
        characters = service.fetchCharacters(context: modelContext)
    }
}
