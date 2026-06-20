import Foundation

struct WikiResponse: Codable {
    let title: String
    let extract: String?
    let thumbnail: WikiThumbnail?
    let pageid: Int?
}

struct WikiThumbnail: Codable {
    let source: String
    let width: Int
    let height: Int
}

enum WikiError: LocalizedError {
    case noNetwork
    case notFound
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noNetwork: return "Sin conexión a internet"
        case .notFound: return "No hay información disponible"
        case .invalidResponse: return "Error al obtener información"
        }
    }
}

actor WikiService {
    static let shared = WikiService()
    private let session: URLSession
    private let decoder = JSONDecoder()

    private var cache: [String: WikiResponse] = [:]
    private let maxCacheSize = 100

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
    }

    func fetchSummary(for characterName: String) async throws -> WikiResponse {
        if let cached = cache[characterName] {
            return cached
        }

        let encoded = characterName
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "_")

        let components = URLComponents(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)")
        guard let url = components?.url else {
            throw WikiError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue("EduGuess/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw WikiError.noNetwork
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WikiError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let wikiResponse = try decoder.decode(WikiResponse.self, from: data)
            if cache.count >= maxCacheSize, let firstKey = cache.keys.first {
                cache.removeValue(forKey: firstKey)
            }
            cache[characterName] = wikiResponse
            return wikiResponse
        case 404:
            throw WikiError.notFound
        default:
            throw WikiError.invalidResponse
        }
    }
}
