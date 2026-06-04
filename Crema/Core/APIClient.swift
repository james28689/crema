//
//  APIClient.swift
//  Crema
//
//  Created by James Watling on 04/06/2026.
//

import Foundation
import Supabase

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response."
        case .httpError(let code, let message):
            return message ?? "Server error (HTTP \(code))."
        }
    }
}

// MARK: - Client

/// Thin networking layer for the Crema REST API.
///
/// Automatically attaches the current Supabase session JWT as a Bearer token
/// so the API can identify the authenticated user. All request bodies are
/// encoded and all response bodies are decoded using snake_case ↔ camelCase
/// key conversion.
final class APIClient {

    static let shared = APIClient()
    private init() {}

    // ── Configuration ────────────────────────────────────────────────────────

    /// Base URL includes the trailing slash so relative path resolution works
    /// correctly when using URL(string:relativeTo:).
    private let base = URL(string: "https://crema-api.watling.dev/v1/")!

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        // camelCase Swift properties → snake_case JSON keys
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        // snake_case JSON keys → camelCase Swift properties
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // ── Request builder ──────────────────────────────────────────────────────

    private func buildRequest(
        method: String,
        path: String,
        body: Data? = nil,
        queryItems: [URLQueryItem] = []
    ) async throws -> URLRequest {
        // Resolve the path relative to base, then attach any query parameters
        // via URLComponents so values are properly percent-encoded.
        guard let rawURL = URL(string: path, relativeTo: base),
              var components = URLComponents(url: rawURL, resolvingAgainstBaseURL: true)
        else {
            throw APIError.invalidResponse
        }
        if !queryItems.isEmpty {
            components.queryItems = (components.queryItems ?? []) + queryItems
        }
        guard let url = components.url else { throw APIError.invalidResponse }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
        }

        // Attach the Supabase JWT so the API knows which user is calling.
        // Silently skips if there's no active session (unauthenticated calls).
        if let token = try? await supabase.auth.session.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return req
    }

    // ── Response validation ──────────────────────────────────────────────────

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            // Decode the error body once and check both common key conventions.
            let errorBody = try? decoder.decode([String: String].self, from: data)
            let message = errorBody?["message"] ?? errorBody?["detail"]
            throw APIError.httpError(statusCode: http.statusCode, message: message)
        }
    }

    // ── HTTP verbs ───────────────────────────────────────────────────────────

    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        let req = try await buildRequest(method: "GET", path: path, queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(for: req)
        try validate(response: response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    func post<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        let encoded = try encoder.encode(body)
        let req = try await buildRequest(method: "POST", path: path, body: encoded)
        let (data, response) = try await URLSession.shared.data(for: req)
        try validate(response: response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    func put<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        let encoded = try encoder.encode(body)
        let req = try await buildRequest(method: "PUT", path: path, body: encoded)
        let (data, response) = try await URLSession.shared.data(for: req)
        try validate(response: response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    func patch<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        let encoded = try encoder.encode(body)
        let req = try await buildRequest(method: "PATCH", path: path, body: encoded)
        let (data, response) = try await URLSession.shared.data(for: req)
        try validate(response: response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    func delete(_ path: String) async throws {
        let req = try await buildRequest(method: "DELETE", path: path)
        let (data, response) = try await URLSession.shared.data(for: req)
        try validate(response: response, data: data)
    }
}
