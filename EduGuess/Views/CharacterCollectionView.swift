import SwiftUI
import SwiftData

struct CharacterCollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var characters: [Character] = []
    @State private var unlockedNames: Set<String> = []
    @State private var isLoading = true
    @State private var selectedCharacter: Character?
    @State private var showDetail = false
    @State private var searchText = ""
    @State private var showUnlockConfirmation = false
    @State private var pendingUnlockName: String?
    @State private var toastMessage = ""
    @State private var showToast = false
    @State private var characterImages: [String: String] = [:]

    private let unlockCost = 100
    private let authVM = AuthViewModel.shared

    var filteredCharacters: [Character] {
        guard !searchText.isEmpty else { return characters }
        return characters.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var unlockedCount: Int {
        unlockedNames.count
    }

    var progressText: String {
        "\(unlockedCount) / \(characters.count)"
    }

    var body: some View {
        ZStack {
            AppTheme.mainGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                progressHeader

                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                            ForEach(filteredCharacters) { character in
                                collectionCell(character)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Colección")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Buscar personaje")
        .task {
            await loadData()
        }
        .sheet(isPresented: $showDetail) {
            if let character = selectedCharacter {
                CollectionCharacterDetailView(character: character)
            }
        }
        .alert("Desbloquear personaje", isPresented: $showUnlockConfirmation, presenting: pendingUnlockName) { name in
            Button("Cancelar", role: .cancel) {}
            Button("Desbloquear por \(unlockCost) pts") {
                unlockWithPoints(name: name)
            }
        } message: { name in
            Text("¿Quieres gastar \(unlockCost) puntos para desbloquear a \(name)?")
        }
        .toast(message: toastMessage, icon: "checkmark.circle.fill", isShowing: $showToast)
    }

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Progreso")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                Text(progressText)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.primaryGold)
                    .fontWeight(.semibold)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.cardSurface)
                        .frame(height: 16)

                    let ratio = characters.isEmpty ? 0 : Double(unlockedCount) / Double(characters.count)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.buttonGradient)
                        .frame(width: geo.size.width * ratio, height: 16)
                        .animation(.easeInOut(duration: 0.5), value: unlockedCount)
                }
            }
            .frame(height: 16)
        }
        .padding()
        .background(AppTheme.cardSurface)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppTheme.cardBorder),
            alignment: .bottom
        )
    }

    private func collectionCell(_ character: Character) -> some View {
        let isUnlocked = unlockedNames.contains(character.name)
        let imageURL = characterImages[character.name]

        return Button {
            if isUnlocked {
                selectedCharacter = character
                showDetail = true
            } else {
                pendingUnlockName = character.name
                showUnlockConfirmation = true
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? AppTheme.primaryGold.opacity(0.2) : AppTheme.cardSurface)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(isUnlocked ? AppTheme.primaryGold.opacity(0.6) : AppTheme.cardBorder, lineWidth: 2)
                        )

                    if isUnlocked {
                        if let urlString = imageURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 76, height: 76)
                                        .clipShape(Circle())
                                case .failure:
                                    Text(String(character.name.prefix(1)))
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(AppTheme.primaryGold)
                                case .empty:
                                    ProgressView()
                                        .tint(AppTheme.primaryGold)
                                @unknown default:
                                    Text(String(character.name.prefix(1)))
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(AppTheme.primaryGold)
                                }
                            }
                        } else {
                            Text(String(character.name.prefix(1)))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppTheme.primaryGold)
                        }
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AppTheme.mutedText)
                    }
                }

                Text(character.name)
                    .font(.caption)
                    .fontWeight(isUnlocked ? .semibold : .regular)
                    .foregroundColor(isUnlocked ? AppTheme.primaryText : AppTheme.mutedText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 32)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            if isUnlocked && imageURL == nil {
                loadImage(for: character.name)
            }
        }
    }

    private func loadData() async {
        let service = DataService()
        characters = service.fetchCharacters(context: modelContext)

        if let uid = authVM.userUID {
            do {
                let names = try await FirestoreService.shared.fetchUnlockedCharacters(uid: uid)
                await MainActor.run {
                    unlockedNames = Set(names)
                }
            } catch {
                print("Failed to load unlocked characters: \(error)")
            }
        }

        isLoading = false
    }

    private func unlockWithPoints(name: String) {
        // Local-only unlock using points is not implemented in this version;
        // we just show a toast indicating the user should win the character by playing.
        toastMessage = "¡Juega y adivina a \(name) para desbloquearlo!"
        withAnimation { showToast = true }
    }

    private func loadImage(for name: String) {
        Task {
            do {
                let response = try await WikiService.shared.fetchSummary(for: name)
                if let thumbnailURL = response.thumbnail?.source {
                    await MainActor.run {
                        characterImages[name] = thumbnailURL
                    }
                }
            } catch {
                // Silently fail - will show initial letter instead
            }
        }
    }
}

// MARK: - Detail Sheet

private struct CollectionCharacterDetailView: View {
    let character: Character
    @State private var summary: String?
    @State private var thumbnailURL: String?
    @State private var isLoading = false
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.mainGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if let urlString = thumbnailURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(AppTheme.primaryGold.opacity(0.6), lineWidth: 2)
                                        )
                                case .failure:
                                    fallbackAvatar
                                case .empty:
                                    ProgressView()
                                        .tint(AppTheme.primaryGold)
                                        .frame(width: 120, height: 120)
                                @unknown default:
                                    fallbackAvatar
                                }
                            }
                        } else {
                            fallbackAvatar
                        }

                        Text(character.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.primaryText)

                        if isLoading {
                            ProgressView()
                                .tint(AppTheme.primaryGold)
                        } else if let summary = summary {
                            Text(summary)
                                .font(.body)
                                .foregroundColor(AppTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(AppTheme.cardSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                                )
                                .cornerRadius(12)
                        } else if showError {
                            Text("No hay información adicional disponible.")
                                .foregroundColor(AppTheme.mutedText)
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle(character.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                        .foregroundColor(AppTheme.primaryGold)
                }
            }
        }
        .task {
            await loadSummary()
        }
    }

    @Environment(\.dismiss) private var dismiss

    private var fallbackAvatar: some View {
        Circle()
            .fill(AppTheme.primaryGold.opacity(0.2))
            .frame(width: 120, height: 120)
            .overlay(
                Circle()
                    .stroke(AppTheme.primaryGold.opacity(0.6), lineWidth: 2)
            )
            .overlay(
                Text(String(character.name.prefix(1)))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(AppTheme.primaryGold)
            )
    }

    private func loadSummary() async {
        isLoading = true
        do {
            let response = try await WikiService.shared.fetchSummary(for: character.name)
            summary = response.extract
            thumbnailURL = response.thumbnail?.source
        } catch {
            showError = true
        }
        isLoading = false
    }
}
