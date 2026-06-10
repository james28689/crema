//
//  Shot.swift
//  Crema
//
//  Created by James Watling on 25/05/2026.
//

import Foundation

struct ShotBean: Codable {
    let id: UUID
    let name: String
}

struct Shot: Codable, Identifiable {
    let id: UUID
    let beanId: UUID?
    let bean: ShotBean?
    let doseG: Double
    let yieldG: Double
    let ratio: Double
    let timeSec: Int
    let grinderSetting: String?
    let rating: Int
    let tasteTags: [String]?
    let notes: String?
    let pulledAt: Date
    let daysOffRoastAtPull: Int?
}
