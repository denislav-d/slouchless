//
//  CalibrationProfile.swift
//  Slouchless
//
//  Created by Denislav Dimitrov on 8.07.26.
//

import Foundation

struct CalibrationProfile: Codable, Equatable {
    let baselinePitch: Double
    let baselineRoll: Double
    let baselineYaw: Double
    let createdAt: Date
}
