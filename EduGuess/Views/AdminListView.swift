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
    @State private var importURLString = "https://example.com/characters.json"
    @State private var showImport = false
    @State private var isImporting = false

    var body: some View {
        ZStack {
            AppTheme.mainGradient.ignoresSafeArea()

            List {
                Section {
                    if characters.isEmpty {
                        ContentUnavailableView(
                            "Sin personajes",
                            systemImage: "person.slash",
                            description: Text("Agrega o importa personajes")
                        )
                    } else {
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
                                        .fill(AppTheme.primaryGold.opacity(0.2))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Text(String(character.name.prefix(1)))
                                                .font(.caption)
                                                .foregroundColor(AppTheme.primaryGold)
                                        )
                                    Text(character.name)
                                        .foregroundColor(AppTheme.primaryText)
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

                Section {
                    TextField("URL del JSON", text: $importURLString)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(AppTheme.primaryText)

                    Button {
                        Task { await importFromAPI() }
                    } label: {
                        HStack {
                            if isImporting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "icloud.and.arrow.down")
                            }
                            Text("Importar desde API")
                        }
                        .foregroundColor(AppTheme.infoBlue)
                    }
                    .disabled(isImporting || importURLString.isEmpty)
                } header: {
                    Text("Importación masiva")
                        .foregroundColor(AppTheme.mutedText)
                }

                Section {
                    Button {
                        showNewForm = true
                    } label: {
                        Label("Agregar manualmente", systemImage: "plus.circle")
                            .foregroundColor(AppTheme.successGreen)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Administrar")
        .toolbarColorScheme(.dark, for: .navigationBar)
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

    private func importFromAPI() async {
        guard let url = URL(string: importURLString.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme == "https" || url.scheme == "http" else {
            errorMessage = "URL inválida"
            showError = true
            return
        }

        isImporting = true
        do {
            let imported = try await CharacterImportService.shared.fetchCharacters(from: url)
            let result = CharacterImportService.shared.importCharacters(imported, context: modelContext)
            await MainActor.run {
                loadCharacters()
                isImporting = false
                errorMessage = "Importados: \(result.imported)\nSaltados (duplicados/vacíos): \(result.skipped)"
                showError = true
            }
        } catch {
            await MainActor.run {
                isImporting = false
                errorMessage = "Error al importar: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}
