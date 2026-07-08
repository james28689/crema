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
    case unauthenticated
    case httpError(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response."
        case .unauthenticated:
            return "No active session."
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
    ///
    /// Local vs. hosted is controlled by `APIEnvironment.current`. The
    /// `LOCAL_API_BASE` env var (set via Xcode scheme) still overrides both,
    /// for device/LAN testing where `localhost` won't resolve to the Mac.
    private let base: URL = {
        if let override = ProcessInfo.processInfo.environment["LOCAL_API_BASE"] {
            return URL(string: override)!
        }
        return APIEnvironment.current.baseURL
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        // camelCase Swift properties → snake_case JSON keys
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        // API returns ISO8601 timestamps that may lack a timezone suffix or include
        // fractional seconds. Try both variants before giving up.
        let withFrac: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }()
        let plain: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime]
            return f
        }()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            var string = try container.decode(String.self)
            if !string.hasSuffix("Z") && !string.contains("+") { string += "Z" }
            if let date = withFrac.date(from: string) { return date }
            if let date = plain.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(in: container,
                debugDescription: "Cannot parse date: \(string)")
        }
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
        let normalizedPath = path.hasSuffix("/") ? String(path.dropLast()) : path
        guard let rawURL = URL(string: normalizedPath, relativeTo: base),
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

        // Attach the Supabase JWT. If there is no active session (e.g. sign-out
        // is in progress) bail with unauthenticated rather than surfacing an
        // AuthError deep inside a view-model catch block.
        guard let token = supabase.auth.currentSession?.accessToken else {
            throw APIError.unauthenticated
        }
        #if DEBUG
        print("[APIClient] \(method) \(req.url?.absoluteString ?? "?") alg=\(jwtAlgorithm(token)) sub=\(jwtSubject(token))")
        #endif
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return req
    }

    // ── Response validation ──────────────────────────────────────────────────

    private struct ErrorEnvelope: Decodable {
        struct Body: Decodable { let message: String }
        let error: Body
    }

    private func validate(response: URLResponse, data: Data) async throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let rawBody = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            #if DEBUG
            print("[APIClient] HTTP \(http.statusCode) \(response.url?.absoluteString ?? "?"): \(rawBody)")
            #endif
            if http.statusCode == 401 {
                try? await supabase.auth.signOut()
            }
            let message = (try? decoder.decode(ErrorEnvelope.self, from: data))?.error.message
            throw APIError.httpError(statusCode: http.statusCode, message: message)
        }
    }

    // ── Decode with diagnostics ──────────────────────────────────────────────

    private func decode<T: Decodable>(_ type: T.Type, from data: Data, url: URL?) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch let error as DecodingError {
            #if DEBUG
            let raw = String(data: data, encoding: .utf8) ?? "<binary>"
            print("[APIClient] Decode error (\(type)) from \(url?.absoluteString ?? "?"): \(decodingErrorDescription(error))")
            print("[APIClient] Raw body: \(raw)")
            #endif
            throw error
        }
    }

    private func decodingErrorDescription(_ error: DecodingError) -> String {
        func path(_ ctx: DecodingError.Context) -> String {
            ctx.codingPath.map(\.stringValue).joined(separator: ".")
        }
        switch error {
        case .keyNotFound(let key, let ctx):
            return "missing key '\(key.stringValue)' at '\(path(ctx))'"
        case .typeMismatch(let type, let ctx):
            return "type mismatch — expected \(type) at '\(path(ctx))': \(ctx.debugDescription)"
        case .valueNotFound(let type, let ctx):
            return "null value for \(type) at '\(path(ctx))'"
        case .dataCorrupted(let ctx):
            return "data corrupted at '\(path(ctx))': \(ctx.debugDescription)"
        @unknown default:
            return error.localizedDescription
        }
    }

    // ── HTTP verbs ───────────────────────────────────────────────────────────

    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        let req = try await buildRequest(method: "GET", path: path, queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(for: req)
        try await validate(response: response, data: data)
        return try decode(T.self, from: data, url: req.url)
    }

    func post<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        let encoded = try encoder.encode(body)
        let req = try await buildRequest(method: "POST", path: path, body: encoded)
        let (data, response) = try await URLSession.shared.data(for: req)
        try await validate(response: response, data: data)
        return try decode(T.self, from: data, url: req.url)
    }

    func put<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        let encoded = try encoder.encode(body)
        let req = try await buildRequest(method: "PUT", path: path, body: encoded)
        let (data, response) = try await URLSession.shared.data(for: req)
        try await validate(response: response, data: data)
        return try decode(T.self, from: data, url: req.url)
    }

    func patch<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        let encoded = try encoder.encode(body)
        let req = try await buildRequest(method: "PATCH", path: path, body: encoded)
        let (data, response) = try await URLSession.shared.data(for: req)
        try await validate(response: response, data: data)
        return try decode(T.self, from: data, url: req.url)
    }

    func delete(_ path: String) async throws {
        let req = try await buildRequest(method: "DELETE", path: path)
        let (data, response) = try await URLSession.shared.data(for: req)
        try await validate(response: response, data: data)
    }
}

// MARK: - Debug helpers (dev only)

#if DEBUG
private func jwtAlgorithm(_ token: String) -> String {
    guard let header = jwtDecodeSegment(token.split(separator: ".").first.map(String.init)) else { return "?" }
    return (header["alg"] as? String) ?? "?"
}

private func jwtSubject(_ token: String) -> String {
    let parts = token.split(separator: ".")
    guard parts.count > 1,
          let payload = jwtDecodeSegment(String(parts[1])) else { return "?" }
    return (payload["sub"] as? String) ?? "?"
}

private func jwtDecodeSegment(_ segment: String?) -> [String: Any]? {
    guard let segment else { return nil }
    var base64 = segment.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    while base64.count % 4 != 0 { base64 += "=" }
    guard let data = Data(base64Encoded: base64),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
    return json
}
#endif
