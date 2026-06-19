import SwiftUI
import SwiftData

struct CharacterFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let initialName: String
    let initialAttributes: [String: Bool]
    let onSave: (String, [String: Bool]) -> Void

    @State private var name: String
    @State private var attributes: [String: Bool]

    init(character: Character? = nil,
         onSave: @escaping (String, [String: Bool]) -> Void = { _, _ in }) {
        self.initialName = character?.name ?? ""
        self.initialAttributes = character?.attributes ?? [:]
        self.onSave = onSave
        _name = State(initialValue: character?.name ?? "")
        _attributes = State(initialValue: character?.attributes ?? [:])
    }

    init(initialName: String,
         initialAttributes: [String: Bool],
         onSave: @escaping (String, [String: Bool]) -> Void = { _, _ in }) {
        self.initialName = initialName
        self.initialAttributes = initialAttributes
        self.onSave = onSave
        _name = State(initialValue: initialName)
        _attributes = State(initialValue: initialAttributes)
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

            ForEach(categoriesWithAttributes, id: \.0.rawValue) { category, defs in
                Section(category.rawValue) {
                    ForEach(defs, id: \.key) { def in
                        Toggle(def.questionTemplates.first ?? def.key, isOn: Binding(
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
        onSave(name, attributes)
        dismiss()
    }
}
