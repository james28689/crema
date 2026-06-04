//
//  Shot.swift
//  Crema
//
//  Created by James Watling on 25/05/2026.
//

import Foundation

struct Shot: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let beanId: UUID?
    let doseG: Double
    let yieldG: Double
    let timeSec: Int
    let grinderSetting: String?
    let rating: Int
    let tasteTags: [String]?
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case beanId = "bean_id"
        case doseG = "dose_g"
        case yieldG = "yield_g"
        case timeSec = "time_sec"
        case grinderSetting = "grinder_setting"
        case rating
        case tasteTags = "taste_tags"
        case notes
        case createdAt = "created_at"
    }
}
