import SwiftUI

struct CharacterDetailView: View {
    let character: Character
    @State private var wikiSummary: String?
    @State private var wikiState: WikiLoadState = .idle

    enum WikiLoadState {
        case idle, loading, loaded, error(String)
    }

    private var attributesByCategory: [(AttributeCategory, [AttributeDefinition])] {
        let pool = AttributeDefinition.pool
        let grouped = Dictionary(grouping: pool, by: { $0.category })
        return AttributeCategory.allCases.compactMap { category in
            guard let attrs = grouped[category], !attrs.isEmpty else { return nil }
            return (category, attrs)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                attributesSection
                wikiSection
            }
            .padding()
        }
        .navigationTitle(character.name)
        .navigationBarTitleDisplayMode(.large)
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
                        colors: [.orange, .red],
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

            let knownCount = character.attributes.filter { $0.value }.count
            Text("\(knownCount) atributos conocidos de \(AttributeDefinition.pool.count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var wikiSection: some View {
        switch wikiState {
        case .idle, .loading:
            VStack(spacing: 12) {
                ProgressView()
                    .tint(.orange)
                Text("Cargando información...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .transition(.opacity)

        case .loaded:
            if let summary = wikiSummary {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Información adicional")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .padding(.bottom, 4)

                    Text(summary
                        .replacingOccurrences(of: "\n", with: " ")
                        .trimmingCharacters(in: .whitespaces)
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

        case .error(let message):
            HStack {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.secondary)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .transition(.opacity)
        }
    }

    private var attributesSection: some View {
        ForEach(attributesByCategory, id: \.0.rawValue) { category, definitions in
            VStack(alignment: .leading, spacing: 8) {
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(.orange)
                    .padding(.bottom, 4)

                ForEach(definitions, id: \.key) { def in
                    attributeRow(definition: def)
                }
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal, 4)
        }
    }

    private func attributeRow(definition: AttributeDefinition) -> some View {
        let value = character.attributes[definition.key]
        let isKnown = value != nil
        let isTrue = value == true

        return HStack {
            Text(definition.questionTemplate)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            if isKnown {
                Image(systemName: isTrue ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isTrue ? .green : .red)
                    .font(.title3)
            } else {
                Text("—")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
