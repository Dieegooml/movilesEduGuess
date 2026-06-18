import SwiftUI

let avatarOptions = [
    "person.circle.fill",
    "person.fill",
    "person.crop.circle.fill",
    "person.crop.square.fill",
    "person.text.rectangle.fill",
    "person.and.background.dotted",
    "person.badge.shield.checkmark.fill",
    "person.badge.key.fill",
    "person.badge.clock.fill",
    "person.badge.minus.fill",
    "face.smiling.fill",
    "face.dashed.fill",
    "eye.circle.fill",
    "hand.raised.circle.fill",
    "brain.head.profile",
    "star.circle.fill",
    "heart.circle.fill",
    "crown.fill",
    "sun.max.circle.fill",
    "moon.circle.fill",
    "sparkles",
    "graduationcap.fill",
    "book.circle.fill",
    "globe.americas.fill",
]

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("displayName") private var displayName = ""
    @AppStorage("avatarName") private var avatarName = "person.circle.fill"
    @AppStorage("appTheme") private var appTheme: Theme = .system
    @AppStorage("appLanguage") private var appLanguage: String = "es"
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @State private var showAdmin = false
    @State private var showAvatarPicker = false
    @State private var showNameSaved = false

    private let authVM = AuthViewModel.shared

    var body: some View {
        Form {
            Section("Perfil") {
                HStack {
                    Image(systemName: avatarName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.accentColor)
                    Button("Cambiar avatar") {
                        showAvatarPicker = true
                    }
                }

                HStack {
                    TextField("Nombre visible", text: $displayName)
                    Button {
                        saveProfile()
                    } label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.title3)
                    }
                }
                if showNameSaved {
                    Text("¡Guardado!")
                        .font(.caption)
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
            }

            Section("Avatar") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(avatarOptions, id: \.self) { icon in
                            Button {
                                avatarName = icon
                                saveProfile()
                            } label: {
                                Image(systemName: icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                                    .padding(8)
                                    .background(avatarName == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(avatarName == icon ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                            }
                            .foregroundColor(avatarName == icon ? .accentColor : .primary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Apariencia") {
                Picker("Tema", selection: $appTheme) {
                    ForEach(Theme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Idioma") {
                Picker("Idioma", selection: $appLanguage) {
                    Text("Español").tag("es")
                    Text("English").tag("en")
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

    private func saveProfile() {
        guard let uid = authVM.userUID else { return }
        Task {
            try? await FirestoreService.shared.updateUserProfile(uid: uid, name: displayName, avatar: avatarName)
            await MainActor.run {
                withAnimation {
                    showNameSaved = true
                }
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        withAnimation {
                            showNameSaved = false
                        }
                    }
                }
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
