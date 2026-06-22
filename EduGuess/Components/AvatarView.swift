import SwiftUI

struct AvatarView: View {
    let avatar: String
    var size: CGFloat = 40

    private static let imageCache = NSCache<NSString, UIImage>()

    var body: some View {
        if avatar.hasPrefix("data:image/"),
           let image = cachedUIImage() {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Image(systemName: avatar.isEmpty ? "person.circle.fill" : avatar)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundColor(AppTheme.primaryText)
        }
    }

    private func cachedUIImage() -> UIImage? {
        let cacheKey = avatar as NSString
        if let cached = Self.imageCache.object(forKey: cacheKey) {
            return cached
        }
        let cleaned = avatar
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
        guard let data = Data(base64Encoded: cleaned),
              let image = UIImage(data: data) else { return nil }
        Self.imageCache.setObject(image, forKey: cacheKey)
        return image
    }
}
