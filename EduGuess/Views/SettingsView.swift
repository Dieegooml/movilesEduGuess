import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("displayName") private var displayName = ""
    @AppStorage("appTheme") private var appTheme: Theme = .system
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @State private var showAdmin = false

    var body: some View {
        Form {
            Section("Perfil") {
                TextField("Nombre visible", text: $displayName)
            }

            Section("Apariencia") {
                Picker("Tema", selection: $appTheme) {
                    ForEach(Theme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Preferencias") {
                Toggle("Sonidos", isOn: $soundEnabled)
                Toggle("Vibración (Haptic)", isOn: $hapticEnabled)
            }

            Section("Información") {
                HStack {
                    Text("Versión")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 2) {
                    showAdmin = true
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
        .background(
            NavigationLink(
                destination: AdminListView(),
                isActive: $showAdmin,
                label: { EmptyView() }
            )
            .hidden()
        )
    }

    private func clearAllData() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let storeURL = documentsPath.appendingPathComponent("default.store")
        try? FileManager.default.removeItem(at: storeURL)
        dismiss()
    }
}
