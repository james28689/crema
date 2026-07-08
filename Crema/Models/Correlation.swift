//
//  Correlation.swift
//  Crema
//

import Foundation

struct CorrelationPair: Codable {
    let variableX: String
    let variableY: String
    let coefficient: Double?
    let sampleSize: Int
}

struct VariableCorrelation: Codable, Identifiable {
    var id: String { variable }
    let variable: String
    let coefficient: Double?
    let sampleSize: Int
}

struct CorrelationsResponse: Codable {
    let sampleSize: Int
    let grindSampleSize: Int
    let matrix: [CorrelationPair]
    let vsRating: [VariableCorrelation]
}
