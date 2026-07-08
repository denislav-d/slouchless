//
//  PostureState.swift
//  Slouchless
//
//  Created by Denislav Dimitrov on 8.07.26.
//

import Foundation

enum PostureState: String, Equatable {
    case unknown
    case needsCalibration
    case good
    case warning
    case bad

    var title: String {
        switch self {
        case .unknown:
            "Unknown"
        case .needsCalibration:
            "Needs Calibration"
        case .good:
            "Good"
        case .warning:
            "Warning"
        case .bad:
            "Bad"
        }
    }

    var displayTitle: String {
        switch self {
        case .warning:
            "Okay"
        default:
            title
        }
    }

    var menuBarSystemImageName: String {
        switch self {
        case .unknown:
            "airpodspro"
        case .needsCalibration:
            "target"
        case .good:
            "checkmark.circle"
        case .warning:
            "exclamationmark.triangle"
        case .bad:
            "exclamationmark.circle.fill"
        }
    }
}
