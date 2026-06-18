import SwiftUI
import SwiftData

struct CharacterFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let initialName: String
    let initialImage: String
    let initialAttributes: [String: Bool]
    let onSave: (String, String, [String: Bool]) -> Void

    @State private var name: String
    @State private var imageURL: String
    @State private var attributes: [String: Bool]

    init(character: Character? = nil,
         onSave: @escaping (String, String, [String: Bool]) -> Void = { _, _, _ in }) {
        self.initialName = character?.name ?? ""
        self.initialImage = character?.image ?? ""
        self.initialAttributes = character?.attributes ?? [:]
        self.onSave = onSave
        _name = State(initialValue: character?.name ?? "")
        _imageURL = State(initialValue: character?.image ?? "")
        _attributes = State(initialValue: character?.attributes ?? [:])
    }

    private var categoriesWithAttributes: [(AttributeCategory, [AttributeDefinition])] {
        let pool = AttributeDefinition.pool
        let grouped = Dictionary(grouping: pool, by: { $0.category })
        return AttributeCategory.allCases.compactMap { category in
            guard let attrs = grouped[category], !attrs.isEmpty else { return nil }
            return (category, attrs)
        }
    }

    var body: some View {
        Form {
            Section("Nombre") {
                TextField("Nombre del personaje", text: $name)
            }

            Section("Imagen") {
                TextField("URL de imagen (opcional)", text: $imageURL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                if !imageURL.isEmpty, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        case .failure:
                            Text("No se pudo cargar la imagen")
                                .font(.caption)
                                .foregroundColor(.red)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 80)
                }
            }

            ForEach(categoriesWithAttributes, id: \.0.rawValue) { category, defs in
                Section(category.rawValue) {
                    ForEach(defs, id: \.key) { def in
                        Toggle(def.questionTemplate, isOn: Binding(
                            get: { attributes[def.key] ?? false },
                            set: { attributes[def.key] = $0 }
                        ))
                    }
                }
            }
        }
        .navigationTitle(name.isEmpty ? "Nuevo personaje" : name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    save()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { dismiss() }
            }
        }
    }

    private func save() {
        let name = name.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        onSave(name, imageURL.trimmingCharacters(in: .whitespaces), attributes)
        dismiss()
    }
}
