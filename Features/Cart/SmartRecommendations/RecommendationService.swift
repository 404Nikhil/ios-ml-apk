//
//  RecommendationService.swift
//  WSHackathonApp
//
//  Calls POST /recommend on the FastAPI ML server.
//  Maps WS product titles to intcart-known type IDs automatically.
//

import Foundation

final class RecommendationService {
    static let shared = RecommendationService()
    private init() {}

    // MARK: - Keyword → intcart type mapping
    // intcart knows: pan, pot, knife, spatula, cutting_board, plate, glass, chair, table, sofa, coffee_table
    private let keywordMap: [String: String] = [
        // Cookware
        "pan":          "pan",
        "skillet":      "pan",
        "frying":       "pan",
        "sauté":        "pan",
        "wok":          "pan",
        "pot":          "pot",
        "saucepan":     "pot",
        "stockpot":     "pot",
        "casserole":    "pot",
        "dutch":        "pot",
        "knife":        "knife",
        "chef":         "knife",
        "paring":       "knife",
        "spatula":      "spatula",
        "turner":       "spatula",
        "cutting":      "cutting_board",
        "board":        "cutting_board",
        "chopping":     "cutting_board",
        // Dining
        "plate":        "plate",
        "dish":         "plate",
        "bowl":         "plate",
        "glass":        "glass",
        "mug":          "glass",
        "cup":          "glass",
        // Furniture
        "chair":        "chair",
        "stool":        "chair",
        "table":        "table",
        "desk":         "table",
        "sofa":         "sofa",
        "couch":        "sofa",
        "coffee":       "coffee_table"
    ]

    // MARK: - Map cart items to intcart IDs

    /// Converts WS product titles to intcart-resolvable IDs.
    /// Falls back to a demo set if nothing maps (so the hackathon demo always shows content).
    func resolvedIntcartIds(from cartItems: [(id: String, title: String)]) -> [String] {
        var mapped: [String] = []
        var seen = Set<String>()

        for item in cartItems {
            let words = item.title.lowercased()
                .components(separatedBy: .whitespacesAndNewlines)
            for word in words {
                if let intcartId = keywordMap[word], !seen.contains(intcartId) {
                    mapped.append(intcartId)
                    seen.insert(intcartId)
                    break
                }
            }
        }

        // Fallback: if no mapping found, use a generic demo set
        // so the UI always shows recommendations during the demo.
        if mapped.isEmpty {
            mapped = ["pan"]
        }

        return mapped
    }

    // MARK: - Fetch

    /// Fetches recommendation sections for the given intcart-compatible IDs.
    func fetchRecommendations(for intcartIds: [String]) async throws -> RecommendationResponse {
        guard let url = URL(string: AppConstants.RecommendAPI.recommendEndpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        request.httpBody = try JSONEncoder().encode(intcartIds)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        // Check for server-side error JSON: {"error": "No valid items"}
        if let errorPayload = try? JSONDecoder().decode([String: String].self, from: data),
           let serverError = errorPayload["error"] {
            throw NSError(
                domain: "RecommendationService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: serverError]
            )
        }

        return try JSONDecoder().decode(RecommendationResponse.self, from: data)
    }
}

