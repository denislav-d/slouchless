//
//  PostureAnalyzer.swift
//  Slouchless
//
//  Created by Denislav Dimitrov on 8.07.26.
//

import Foundation

struct PostureAnalysis: Equatable {
    let postureState: PostureState
    let pitchDelta: Double?
    let rollDelta: Double?
    let yawDelta: Double?
}

struct PostureAnalyzer {
    private let alpha: Double
    private let warningPitchThreshold: Double
    private let badPitchThreshold: Double
    private let stabilizationDuration: TimeInterval

    private var publicState: PostureState = .unknown
    private var candidateState: PostureState?
    private var candidateStartedAt: Date?
    private var smoothedPitchDelta: Double?
    private var smoothedRollDelta: Double?
    private var smoothedYawDelta: Double?

    init(
        alpha: Double = 0.15,
        warningPitchThreshold: Double = 8,
        badPitchThreshold: Double = 15,
        stabilizationDuration: TimeInterval = 2
    ) {
        self.alpha = alpha
        self.warningPitchThreshold = warningPitchThreshold
        self.badPitchThreshold = badPitchThreshold
        self.stabilizationDuration = stabilizationDuration
    }

    mutating func analyze(
        pitch: Double?,
        roll: Double?,
        yaw: Double?,
        profile: CalibrationProfile?,
        at date: Date = Date()
    ) -> PostureAnalysis {
        guard let profile else {
            resetMotionState(publicState: .needsCalibration)
            return currentAnalysis()
        }

        guard let pitch, let roll, let yaw else {
            resetMotionState(publicState: .unknown)
            return currentAnalysis()
        }

        smoothedPitchDelta = smooth(current: pitch - profile.baselinePitch, previous: smoothedPitchDelta)
        smoothedRollDelta = smooth(current: roll - profile.baselineRoll, previous: smoothedRollDelta)
        smoothedYawDelta = smooth(current: yaw - profile.baselineYaw, previous: smoothedYawDelta)

        let computedState = computedState(forPitchDelta: smoothedPitchDelta)
        updatePublicState(with: computedState, at: date)

        return currentAnalysis()
    }

    mutating func reset() {
        publicState = .unknown
        candidateState = nil
        candidateStartedAt = nil
        smoothedPitchDelta = nil
        smoothedRollDelta = nil
        smoothedYawDelta = nil
    }

    private mutating func resetMotionState(publicState: PostureState) {
        self.publicState = publicState
        candidateState = nil
        candidateStartedAt = nil
        smoothedPitchDelta = nil
        smoothedRollDelta = nil
        smoothedYawDelta = nil
    }

    private mutating func updatePublicState(with computedState: PostureState, at date: Date) {
        if candidateState != computedState {
            candidateState = computedState
            candidateStartedAt = date
            return
        }

        guard let candidateStartedAt else {
            self.candidateStartedAt = date
            return
        }

        if date.timeIntervalSince(candidateStartedAt) >= stabilizationDuration {
            publicState = computedState
        }
    }

    private func smooth(current: Double, previous: Double?) -> Double {
        guard let previous else {
            return current
        }

        return alpha * current + (1 - alpha) * previous
    }

    private func computedState(forPitchDelta pitchDelta: Double?) -> PostureState {
        guard let pitchDelta else {
            return .unknown
        }

        let magnitude = abs(pitchDelta)

        if magnitude < warningPitchThreshold {
            return .good
        }

        if magnitude <= badPitchThreshold {
            return .warning
        }

        return .bad
    }

    private func currentAnalysis() -> PostureAnalysis {
        PostureAnalysis(
            postureState: publicState,
            pitchDelta: smoothedPitchDelta,
            rollDelta: smoothedRollDelta,
            yawDelta: smoothedYawDelta
        )
    }
}
