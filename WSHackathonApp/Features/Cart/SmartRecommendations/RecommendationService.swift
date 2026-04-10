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

    func resolvedIntcartIds(from cartItems: [(id: String, title: String)]) -> [String] {
        return cartItems.map { $0.id }
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

