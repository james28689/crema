//
//  APIEnvironment.swift
//  Crema
//

import Foundation

/// Which API the app talks to. Flip `current` to switch — no Xcode scheme
/// editing required.
enum APIEnvironment {
    case local
    case hosted

    static let current: APIEnvironment = .hosted

    var baseURL: URL {
        switch self {
        case .local: return URL(string: "http://localhost:8000/v1/")!
        case .hosted: return URL(string: "https://crema-api.watling.dev/v1/")!
        }
    }
}
