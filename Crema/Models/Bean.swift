//
//  Bean.swift
//  Crema
//
//  Created by James Watling on 25/05/2026.
//

import Foundation

enum BeanProcess: String, Codable, CaseIterable {
    case washed
    case natural
    case honey

    var displayName: String {
        switch self {
        case .washed:  return "Washed"
        case .natural: return "Natural"
        case .honey:   return "Honey"
        }
    }
}

enum RoastLevel: String, Codable, CaseIterable {
    case light
    case medium
    case dark

    var displayName: String {
        switch self {
        case .light:  return "Light"
        case .medium: return "Medium"
        case .dark:   return "Dark"
        }
    }
}

struct Bean: Codable, Identifiable, Hashable {
    static func == (lhs: Bean, rhs: Bean) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: UUID
    let name: String
    let roaster: String?
    let origin: String?
    let process: BeanProcess?
    let roastLevel: RoastLevel?
    let roastDate: String?
    let isActive: Bool
    let createdAt: Date
}
