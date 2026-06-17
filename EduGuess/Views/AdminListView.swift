import SwiftUI
import SwiftData

struct AdminListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var characters: [Character] = []
    @State private var showNewForm = false

    var body: some View {
        List {
            ForEach(characters, id: \.id) { character in
                NavigationLink {
                    CharacterFormView(character: character) { name, attributes in
                        let service = DataService()
                        service.updateCharacter(
                            character,
                            newName: name,
                            newAttributes: attributes,
                            context: modelContext
                        )
                        loadCharacters()
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(Color.orange.opacity(0.3))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(String(character.name.prefix(1)))
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            )
                        Text(character.name)
                    }
                }
            }
            .onDelete(perform: deleteCharacters)
        }
        .navigationTitle("Administrar")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewForm) {
            NavigationStack {
                CharacterFormView { name, attributes in
                    let service = DataService()
                    service.addCharacter(name: name, image: "", attributes: attributes, context: modelContext)
                    loadCharacters()
                }
            }
        }
        .onAppear(perform: loadCharacters)
    }

    private func loadCharacters() {
        let service = DataService()
        characters = service.fetchCharacters(context: modelContext)
    }

    private func deleteCharacters(at offsets: IndexSet) {
        let service = DataService()
        for index in offsets {
            let character = characters[index]
            service.deleteCharacter(character, context: modelContext)
        }
        loadCharacters()
    }
}
