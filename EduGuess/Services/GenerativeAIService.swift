import Foundation

struct GenerativeQuestionResponse: Codable {
    let question: String
    let attributeKey: String
    let confidence: Double
}

struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Codable {
    let responseMimeType: String
    let responseSchema: GeminiResponseSchema
    let temperature: Double
    let topP: Double
}

struct GeminiResponseSchema: Codable {
    let type: String
    let properties: [String: GeminiProperty]
    let required: [String]
}

struct GeminiProperty: Codable {
    let type: String
}

struct GeminiAPIResponse: Codable {
    let candidates: [GeminiCandidate]?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
}

struct GeminiAPIErrorResponse: Codable {
    let error: GeminiErrorDetail
}

struct GeminiErrorDetail: Codable {
    let code: Int
    let message: String
    let status: String
}

actor GenerativeAIService {
    static let shared = GenerativeAIService()

    private let session = URLSession.shared

    private var apiURL: URL? {
        URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(GenerativeAIConfig.apiKey)")
    }

    func generateQuestion(
        remainingAttributes: [String],
        possibleCharacters: [Character],
        askedHistory: [(attributeKey: String, answer: Bool)],
        questionCount: Int
    ) async -> GenerativeQuestionResponse? {
        guard let url = apiURL, GenerativeAIConfig.apiKey != "YOUR_GEMINI_API_KEY_HERE" else {
            print("[GenerativeAI] API key no configurada")
            return nil
        }

        let historyText = askedHistory
            .map { "- \($0.attributeKey): \($0.answer ? "Sí" : "No")" }
            .joined(separator: "\n")
        let possibleText = possibleCharacters.map(\.name).joined(separator: ", ")

        let prompt = """
Eres un asistente experto en juegos de adivinanza tipo Akinator.
Tu objetivo es hacer la MEJOR pregunta de sí/no para descubrir qué personaje está pensando el usuario.

CONTEXTO:
- Atributos disponibles para preguntar: \(remainingAttributes.joined(separator: ", "))
- Personajes posibles: \(possibleText)
- Preguntas ya realizadas:
\(historyText)
- Número de preguntas hechas: \(questionCount)

REGLAS:
1. Haz una pregunta en español que el usuario pueda responder con sí o no.
2. La pregunta debe ayudar a filtrar la mayor cantidad de personajes posible.
3. Cada pregunta debe corresponder a UNO de los atributos disponibles.
4. No repitas preguntas sobre atributos ya preguntados.
5. Varía el estilo de las preguntas (no siempre "¿Tu personaje...").
6. Responde SOLO con el JSON indicado.

Responde en este formato JSON exacto (sin markdown, sin texto adicional):
{
  "question": "¿Tu personaje es peruano?",
  "attributeKey": "isFromPeru",
  "confidence": 0.95
}
"""

        let body = GeminiRequest(
            contents: [GeminiContent(parts: [GeminiPart(text: prompt)])],
            generationConfig: GeminiGenerationConfig(
                responseMimeType: "application/json",
                responseSchema: GeminiResponseSchema(
                    type: "object",
                    properties: [
                        "question": GeminiProperty(type: "string"),
                        "attributeKey": GeminiProperty(type: "string"),
                        "confidence": GeminiProperty(type: "number"),
                    ],
                    required: ["question", "attributeKey", "confidence"]
                ),
                temperature: 0.8,
                topP: 0.9
            )
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 20

        do {
            urlRequest.httpBody = try JSONEncoder().encode(body)
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[GenerativeAI] Respuesta inválida (no HTTP)")
                return nil
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorResponse = try? JSONDecoder().decode(GeminiAPIErrorResponse.self, from: data) {
                    print("[GenerativeAI] Error \(httpResponse.statusCode): \(errorResponse.error.message)")
                } else {
                    let body = String(data: data, encoding: .utf8) ?? "(vacío)"
                    print("[GenerativeAI] Error \(httpResponse.statusCode): \(body)")
                }
                return nil
            }

            let geminiResponse = try JSONDecoder().decode(GeminiAPIResponse.self, from: data)
            guard let candidate = geminiResponse.candidates?.first else {
                print("[GenerativeAI] Respuesta sin candidatos: \(String(data: data, encoding: .utf8) ?? "")")
                return nil
            }

            let text = candidate.content.parts.first?.text ?? ""
            guard let jsonData = text.data(using: .utf8),
                  let result = try? JSONDecoder().decode(GenerativeQuestionResponse.self, from: jsonData) else {
                print("[GenerativeAI] No se pudo parsear JSON de la respuesta: \(text)")
                return nil
            }

            return result
        } catch {
            print("[GenerativeAI] Error de red/parseo: \(error)")
            return nil
        }
    }
}
