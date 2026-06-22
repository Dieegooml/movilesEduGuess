import SwiftUI

struct CharacterDetailView: View {
    let character: Character
    @State private var wikiSummary: String?
    @State private var wikiState: WikiLoadState = .idle

    enum WikiLoadState {
        case idle, loading, loaded, error(String)
    }

    private var allAttributes: [AttributeDefinition] {
        AttributeDefinition.pool
    }

    var body: some View {
        ZStack {
            AppTheme.mainGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    attributesSection
                    wikiSection
                }
                .padding()
            }
        }
        .navigationTitle(character.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await loadWikiSummary()
        }
    }

    private func loadWikiSummary() async {
        guard case .idle = wikiState else { return }
        wikiState = .loading
        do {
            let response = try await WikiService.shared.fetchSummary(for: character.name)
            wikiSummary = response.extract
            wikiState = response.extract != nil ? .loaded : .error("No disponible")
        } catch let error as WikiError {
            wikiState = .error(error.localizedDescription)
        } catch {
            wikiState = .error("Error de conexión")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primaryGold, AppTheme.primaryOrange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Text(String(character.name.prefix(1)))
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                )

            Text(character.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)

            let knownCount = character.attributes.filter { $0.value }.count
            Text("\(knownCount) atributos conocidos de \(AttributeDefinition.pool.count)")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
        }
    }

    @ViewBuilder
    private var wikiSection: some View {
        switch wikiState {
        case .idle, .loading:
            VStack(spacing: 12) {
                ProgressView()
                    .tint(AppTheme.primaryGold)
                Text("Cargando información...")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.cardSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
            .cornerRadius(12)
            .transition(.opacity)

        case .loaded:
            if let summary = wikiSummary {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Información adicional")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryGold)
                        .padding(.bottom, 4)

                    Text(summary
                        .replacingOccurrences(of: "\n", with: " ")
                        .trimmingCharacters(in: .whitespaces)
                    )
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppTheme.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

        case .error(let message):
            HStack {
                Image(systemName: "wifi.slash")
                    .foregroundColor(AppTheme.mutedText)
                Text(message)
                    .font(.caption)
                    .foregroundColor(AppTheme.mutedText)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.cardSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
            .cornerRadius(12)
            .transition(.opacity)
        }
    }

    private var attributesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(allAttributes, id: \.key) { def in
                attributeRow(definition: def)
            }
        }
        .padding(.vertical, 8)
        .background(AppTheme.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
        .cornerRadius(12)
        .padding(.horizontal, 4)
    }

    private func attributeRow(definition: AttributeDefinition) -> some View {
        let value = character.attributes[definition.key]
        let isKnown = value != nil
        let isTrue = value == true

        return HStack {
            Text(definition.questionTemplates.first ?? definition.key)
                .font(.subheadline)
                .foregroundColor(AppTheme.primaryText)

            Spacer()

            if isKnown {
                Image(systemName: isTrue ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isTrue ? AppTheme.successGreen : AppTheme.errorRed)
                    .font(.title3)
            } else {
                Text("—")
                    .foregroundColor(AppTheme.mutedText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
