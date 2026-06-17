import SwiftUI
import SwiftData

struct AdminListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var characters: [Character] = []
    @State private var showNewForm = false
    @State private var deleteTarget: Character?
    @State private var showDeleteAlert = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        Group {
            if characters.isEmpty {
                ContentUnavailableView(
                    "Sin personajes",
                    systemImage: "person.slash",
                    description: Text("Agrega personajes usando el botón +")
                )
            } else {
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
                    .onDelete { indexSet in
                        guard let index = indexSet.first else { return }
                        deleteTarget = characters[index]
                        showDeleteAlert = true
                    }
                }
            }
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
        .alert("Eliminar personaje", isPresented: $showDeleteAlert, presenting: deleteTarget) { target in
            Button("Cancelar", role: .cancel) {
                deleteTarget = nil
            }
            Button("Eliminar", role: .destructive) {
                let service = DataService()
                service.deleteCharacter(target, context: modelContext)
                deleteTarget = nil
                loadCharacters()
            }
        } message: { target in
            Text("¿Estás seguro de eliminar a \(target.name)?")
        }
        .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
            Button("OK") { }
        } message: { msg in
            Text(msg)
        }
        .onAppear(perform: loadCharacters)
    }

    private func loadCharacters() {
        let service = DataService()
        characters = service.fetchCharacters(context: modelContext)
    }
}
