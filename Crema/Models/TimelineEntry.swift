//
//  TimelineEntry.swift
//  Crema
//

import Foundation

struct TimelineEntry: Codable, Identifiable {
    let id: UUID
    let shotNumber: Int
    let rating: Int
    let doseG: Double
    let yieldG: Double
    let ratio: Double
    let timeSec: Int
    let pulledAt: Date
    let ratingDelta: Int?
    let doseGDelta: Double?
    let timeSecDelta: Int?
    let ratioDelta: Double?
}
