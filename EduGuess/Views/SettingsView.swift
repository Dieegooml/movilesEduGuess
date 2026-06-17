import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("displayName") private var displayName = ""

    var body: some View {
        Form {
            Section("Perfil") {
                TextField("Nombre visible", text: $displayName)
            }

            Section("Información") {
                HStack {
                    Text("Versión")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button(role: .destructive) {
                    clearAllData()
                } label: {
                    Text("Borrar datos locales")
                }
            } footer: {
                Text("Esto eliminará todo el progreso local, incluyendo el historial de partidas. Esta acción no se puede deshacer.")
            }
        }
        .navigationTitle("Ajustes")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Listo") { dismiss() }
            }
        }
    }

    private func clearAllData() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let storeURL = documentsPath.appendingPathComponent("default.store")
        try? FileManager.default.removeItem(at: storeURL)
        dismiss()
    }
}
