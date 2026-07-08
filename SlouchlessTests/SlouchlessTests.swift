//
//  SlouchlessTests.swift
//  SlouchlessTests
//
//  Created by Denislav Dimitrov on 8.07.26.
//

import Testing
import Foundation
@testable import Slouchless

struct SlouchlessTests {

    @Test func analyzerNeedsCalibrationWithoutProfile() {
        var analyzer = PostureAnalyzer()

        let analysis = analyzer.analyze(
            pitch: 0,
            roll: 0,
            yaw: 0,
            profile: nil,
            at: Date()
        )

        #expect(analysis.postureState == PostureState.needsCalibration)
        #expect(analysis.pitchDelta == nil)
        #expect(analysis.rollDelta == nil)
        #expect(analysis.postureProgress == nil)
    }

    @Test func analyzerWaitsForStableStateBeforePublishing() {
        var analyzer = PostureAnalyzer()
        let profile = CalibrationProfile(baselinePitch: 0, baselineRoll: 0, baselineYaw: 0, createdAt: Date())
        let start = Date()

        let first = analyzer.analyze(pitch: 20, roll: 0, yaw: 0, profile: profile, at: start)
        let early = analyzer.analyze(pitch: 20, roll: 0, yaw: 0, profile: profile, at: start.addingTimeInterval(1.9))
        let stable = analyzer.analyze(pitch: 20, roll: 0, yaw: 0, profile: profile, at: start.addingTimeInterval(2.0))

        #expect(first.postureState == PostureState.unknown)
        #expect(early.postureState == PostureState.unknown)
        #expect(stable.postureState == PostureState.bad)
    }

    @Test func analyzerSmoothsDeltasBeforeClassifying() {
        var analyzer = PostureAnalyzer(stabilizationDuration: 0)
        let profile = CalibrationProfile(baselinePitch: 10, baselineRoll: -4, baselineYaw: 0, createdAt: Date())
        let start = Date()

        _ = analyzer.analyze(pitch: 10, roll: -4, yaw: 0, profile: profile, at: start)
        let analysis = analyzer.analyze(pitch: 30, roll: 6, yaw: 0, profile: profile, at: start)

        #expect(analysis.pitchDelta == 3)
        #expect(analysis.rollDelta == 1.5)
        #expect(analysis.postureProgress == 0.2)
        #expect(analysis.postureState == PostureState.good)
    }

}
