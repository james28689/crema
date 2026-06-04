//
//  ShotRepository.swift
//  Crema
//
//  Created by James Watling on 25/05/2026.
//

import Foundation

// MARK: - Payload types

/// Fields sent when logging a new shot. Server assigns id, user_id, and created_at.
struct CreateShotPayload: Encodable {
    let beanId: UUID?
    let doseG: Double
    let yieldG: Double
    let timeSec: Int
    let grinderSetting: String?
    let rating: Int
    let tasteTags: [String]?
    let notes: String?
}

/// Fields that can be changed on an existing shot. All are optional so callers
/// only need to supply what they're actually changing.
struct UpdateShotPayload: Encodable {
    let beanId: UUID?
    let doseG: Double?
    let yieldG: Double?
    let timeSec: Int?
    let grinderSetting: String?
    let rating: Int?
    let tasteTags: [String]?
    let notes: String?
}

// MARK: - Protocol

protocol ShotRepositoryProtocol {
    func fetchShots() async throws -> [Shot]
    func fetchShots(beanId: UUID) async throws -> [Shot]
    func createShot(_ payload: CreateShotPayload) async throws -> Shot
    func updateShot(id: UUID, payload: UpdateShotPayload) async throws -> Shot
    func deleteShot(id: UUID) async throws
}

// MARK: - Implementation

final class ShotRepository: ShotRepositoryProtocol {

    private let api: APIClient

    /// Defaults to the shared singleton; pass a different instance for testing.
    init(api: APIClient = .shared) {
        self.api = api
    }

    /// Fetches all shots for the authenticated user.
    func fetchShots() async throws -> [Shot] {
        try await api.get("shots/")
    }

    /// Fetches shots filtered to a specific bean.
    /// Query parameters are passed through URLQueryItem so the UUID is correctly
    /// percent-encoded — avoids manual string interpolation into the path.
    func fetchShots(beanId: UUID) async throws -> [Shot] {
        try await api.get(
            "shots/",
            queryItems: [URLQueryItem(name: "bean_id", value: beanId.uuidString.lowercased())]
        )
    }

    /// Logs a new shot and returns the server-assigned record.
    func createShot(_ payload: CreateShotPayload) async throws -> Shot {
        try await api.post("shots/", body: payload)
    }

    /// Updates mutable fields on an existing shot.
    func updateShot(id: UUID, payload: UpdateShotPayload) async throws -> Shot {
        try await api.patch("shots/\(id.uuidString.lowercased())/", body: payload)
    }

    /// Deletes a shot by ID.
    func deleteShot(id: UUID) async throws {
        try await api.delete("shots/\(id.uuidString.lowercased())/")
    }
}
