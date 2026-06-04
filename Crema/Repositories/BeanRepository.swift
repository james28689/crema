//
//  BeanRepository.swift
//  Crema
//
//  Created by James Watling on 25/05/2026.
//

import Foundation

// MARK: - Payload types

/// Fields sent when creating a new bean. Server assigns id, user_id, and created_at.
struct CreateBeanPayload: Encodable {
    let name: String
    let roaster: String?
    let origin: String?
    let process: BeanProcess?
    let roastLevel: RoastLevel?
    /// ISO-8601 date string (YYYY-MM-DD). Matches the Postgres `date` column type.
    let roastDate: String?
    let isActive: Bool
}

/// Fields that can be changed on an existing bean. All are optional so callers
/// only need to supply what they're actually changing.
struct UpdateBeanPayload: Encodable {
    let name: String?
    let roaster: String?
    let origin: String?
    let process: BeanProcess?
    let roastLevel: RoastLevel?
    let roastDate: String?
    let isActive: Bool?
}

// MARK: - Protocol

protocol BeanRepositoryProtocol {
    func fetchBeans() async throws -> [Bean]
    func createBean(_ payload: CreateBeanPayload) async throws -> Bean
    func updateBean(id: UUID, payload: UpdateBeanPayload) async throws -> Bean
    func deleteBean(id: UUID) async throws
}

// MARK: - Implementation

final class BeanRepository: BeanRepositoryProtocol {

    private let api: APIClient

    /// Defaults to the shared singleton; pass a different instance for testing.
    init(api: APIClient = .shared) {
        self.api = api
    }

    /// Fetches all beans for the authenticated user.
    func fetchBeans() async throws -> [Bean] {
        try await api.get("beans/")
    }

    /// Creates a new bean and returns the server-assigned record.
    func createBean(_ payload: CreateBeanPayload) async throws -> Bean {
        try await api.post("beans/", body: payload)
    }

    /// Replaces all mutable fields on a bean.
    func updateBean(id: UUID, payload: UpdateBeanPayload) async throws -> Bean {
        try await api.patch("beans/\(id.uuidString.lowercased())/", body: payload)
    }

    /// Deletes a bean by ID.
    func deleteBean(id: UUID) async throws {
        try await api.delete("beans/\(id.uuidString.lowercased())/")
    }
}
