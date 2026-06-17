import SwiftUI

struct CharacterDetailView: View {
    let character: Character

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
            }
            .padding()
        }
        .navigationTitle(character.name)
        .navigationBarTitleDisplayMode(.large)
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
