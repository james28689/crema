//
//  InsightsRepository.swift
//  Crema
//

import Foundation

// MARK: - Response types

private struct TimelineResponse: Decodable {
    let data: [TimelineEntry]
}

// MARK: - Protocol

protocol TimelineRepositoryProtocol {
    func fetchTimeline(beanId: UUID) async throws -> [TimelineEntry]
}

protocol InsightsRepositoryProtocol: TimelineRepositoryProtocol {
    func fetchCorrelations(beanId: UUID?) async throws -> CorrelationsResponse
}

// MARK: - Implementation

final class InsightsRepository: InsightsRepositoryProtocol {

    private let api: APIClient

    /// Defaults to the shared singleton; pass a different instance for testing.
    init(api: APIClient = .shared) {
        self.api = api
    }

    /// Fetches the ordered shot timeline (with parameter deltas) for a bean.
    func fetchTimeline(beanId: UUID) async throws -> [TimelineEntry] {
        let response: TimelineResponse = try await api.get(
            "insights/timeline",
            queryItems: [URLQueryItem(name: "bean_id", value: beanId.uuidString.lowercased())]
        )
        return response.data
    }

    /// Fetches the pairwise Pearson correlation matrix (and each variable's
    /// correlation vs. rating) across all of the user's shots, or scoped to a
    /// single bean when `beanId` is provided.
    func fetchCorrelations(beanId: UUID?) async throws -> CorrelationsResponse {
        var queryItems: [URLQueryItem] = []
        if let beanId {
            queryItems.append(URLQueryItem(name: "bean_id", value: beanId.uuidString.lowercased()))
        }
        return try await api.get("insights/correlations", queryItems: queryItems)
    }
}
