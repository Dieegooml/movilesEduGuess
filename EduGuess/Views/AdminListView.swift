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
    @State private var isFetchingImages = false
    @State private var fetchProgress = ""

    var body: some View {
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
                            CharacterFormView(character: character) { name, image, attributes in
                                let service = DataService()
                                service.updateCharacter(
                                    character,
                                    newName: name,
                                    newImage: image.isEmpty ? nil : image,
                                    newAttributes: attributes,
                                    context: modelContext
                                )
                                loadCharacters()
                            }
                        } label: {
                            HStack {
                                characterThumbnail(character)
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

            Section("Importación masiva") {
                TextField("URL del JSON", text: $importURLString)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

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
                }
                .disabled(isImporting || importURLString.isEmpty)

                Button {
                    Task { await fetchAllImages() }
                } label: {
                    HStack {
                        if isFetchingImages {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "photo.fill")
                        }
                        Text("Buscar imágenes en Wikipedia")
                    }
                }
                .disabled(isFetchingImages || characters.isEmpty)
                if !fetchProgress.isEmpty {
                    Text(fetchProgress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button {
                    showNewForm = true
                } label: {
                    Label("Agregar manualmente", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Administrar")
        .sheet(isPresented: $showNewForm) {
            NavigationStack {
                CharacterFormView { name, image, attributes in
                    let service = DataService()
                    service.addCharacter(name: name, image: image, attributes: attributes, context: modelContext)
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

    @ViewBuilder
    private func characterThumbnail(_ character: Character) -> some View {
        if !character.image.isEmpty, let url = URL(string: character.image) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                case .failure:
                    fallbackCircle(character)
                case .empty:
                    ProgressView().tint(.orange)
                @unknown default:
                    fallbackCircle(character)
                }
            }
            .frame(width: 36, height: 36)
        } else {
            fallbackCircle(character)
        }
    }

    private func fallbackCircle(_ character: Character) -> some View {
        Circle()
            .fill(Color.orange.opacity(0.3))
            .frame(width: 36, height: 36)
            .overlay(
                Text(String(character.name.prefix(1)))
                    .font(.caption)
                    .foregroundColor(.orange)
            )
    }

    @MainActor
    private func fetchAllImages() async {
        isFetchingImages = true
        var fetched = 0

        for character in characters {
            if !character.image.isEmpty { continue }
            let name = character.name
            fetchProgress = "Buscando: \(name)..."
            if let url = await WikiService.shared.fetchThumbnailURL(for: name) {
                DataService().updateCharacter(character, newImage: url, context: modelContext)
                fetched += 1
            }
        }

        loadCharacters()
        isFetchingImages = false
        fetchProgress = fetched > 0 ? "\(fetched) imágenes actualizadas" : "Sin imágenes nuevas"
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
