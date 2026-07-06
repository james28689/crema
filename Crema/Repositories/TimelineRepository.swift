//
//  TimelineRepository.swift
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

// MARK: - Implementation

final class TimelineRepository: TimelineRepositoryProtocol {

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
}
