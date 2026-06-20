import SwiftUI
import PhotosUI

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
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showDeleteAlert = false

    private let authVM = AuthViewModel.shared

    var body: some View {
        Form {
            Section("Perfil") {
                HStack {
                    AvatarView(avatar: avatarName, size: 44)
                    if avatarName.hasPrefix("data:image/") {
                        Button("Quitar foto") {
                            avatarName = "person.circle.fill"
                            saveProfile()
                        }
                        .font(.caption)
                    }
                }

                HStack {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Elegir foto")
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, item in
                        Task {
                            await loadPhoto(from: item)
                        }
                    }

                    Button("Avatar SF") {
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
                    showDeleteAlert = true
                } label: {
                    Text("Borrar datos locales")
                }
            } footer: {
                Text("Esto eliminará todo el progreso local, incluyendo el historial de partidas. Esta acción no se puede deshacer.")
            }
            .alert("Borrar datos locales", isPresented: $showDeleteAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Borrar", role: .destructive) { clearAllData() }
            } message: {
                Text("Se eliminará todo el progreso local. Esta acción no se puede deshacer.")
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

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            let maxSize: CGFloat = 300
            guard let image = UIImage(data: data) else { return }
            let scaled = image.aspectFitted(to: maxSize)
            if let jpeg = scaled.jpegData(compressionQuality: 0.6) {
                let b64 = "data:image/jpeg;base64," + jpeg.base64EncodedString()
                await MainActor.run {
                    avatarName = b64
                    saveProfile()
                }
            }
        }
    }

    private func clearAllData() {
        guard let context = modelContext else {
            dismiss()
            return
        }
        do {
            let characters = try context.fetch(FetchDescriptor<SDCharacter>())
            let sessions = try context.fetch(FetchDescriptor<SDGameSession>())
            let questions = try context.fetch(FetchDescriptor<SDQuestion>())
            let generated = try context.fetch(FetchDescriptor<SDGeneratedQuestion>())

            for obj in characters + sessions + questions + generated {
                context.delete(obj)
            }
            try context.save()
        } catch {
            print("Error clearing local data: \(error)")
        }
        dismiss()
    }
}

extension UIImage {
    func aspectFitted(to maxDimension: CGFloat) -> UIImage {
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
