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

    var body: some View {
        Form {
            Section("Nombre") {
                TextField("Nombre del personaje", text: $name)
            }

            Section("Atributos") {
                ForEach(AttributeDefinition.pool, id: \.key) { def in
                    Toggle(def.questionTemplates.first ?? def.key, isOn: Binding(
                        get: { attributes[def.key] ?? false },
                        set: { attributes[def.key] = $0 }
                    ))
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
