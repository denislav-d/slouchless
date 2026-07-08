//
//  PostureViewModel.swift
//  Slouchless
//
//  Created by Denislav Dimitrov on 8.07.26.
//

import Combine
import Foundation

@MainActor
final class PostureViewModel: ObservableObject {
    @Published private(set) var postureState: PostureState = .unknown
    @Published private(set) var pitchDelta: Double?
    @Published private(set) var rollDelta: Double?
    @Published private(set) var postureProgress: Double?
    @Published private(set) var statusText = "Start motion updates and calibrate your good posture."

    let motionManager: AirPodsMotionManager
    let calibrationManager: CalibrationManager

    private var analyzer: PostureAnalyzer
    private var cancellables: Set<AnyCancellable> = []

    convenience init() {
        self.init(
            motionManager: AirPodsMotionManager(),
            calibrationManager: CalibrationManager(),
            analyzer: PostureAnalyzer()
        )
    }

    init(
        motionManager: AirPodsMotionManager,
        calibrationManager: CalibrationManager,
        analyzer: PostureAnalyzer
    ) {
        self.motionManager = motionManager
        self.calibrationManager = calibrationManager
        self.analyzer = analyzer

        bindInputs()
        updateAnalysis()
    }

    func startMotionUpdates() {
        motionManager.startMotionUpdates()
    }

    func stopMotionUpdates() {
        motionManager.stopMotionUpdates()
    }

    func startCalibration() {
        calibrationManager.startCalibration(using: motionManager)
    }

    private func bindInputs() {
        motionManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        calibrationManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        Publishers.CombineLatest4(
            motionManager.$latestPitch,
            motionManager.$latestRoll,
            motionManager.$latestYaw,
            calibrationManager.$currentProfile
        )
        .sink { [weak self] _, _, _, _ in
            self?.updateAnalysis()
        }
        .store(in: &cancellables)

        motionManager.$errorMessage
            .sink { [weak self] _ in
                self?.updateStatusText()
            }
            .store(in: &cancellables)

        calibrationManager.$isCalibrating
            .sink { [weak self] _ in
                self?.updateStatusText()
            }
            .store(in: &cancellables)
    }

    private func updateAnalysis(date: Date = Date()) {
        let analysis = analyzer.analyze(
            pitch: motionManager.latestPitch,
            roll: motionManager.latestRoll,
            yaw: motionManager.latestYaw,
            profile: calibrationManager.currentProfile,
            at: date
        )

        postureState = analysis.postureState
        pitchDelta = analysis.pitchDelta
        rollDelta = analysis.rollDelta
        postureProgress = analysis.postureProgress
        updateStatusText()
    }

    private func updateStatusText() {
        if let errorMessage = motionManager.errorMessage {
            statusText = errorMessage
            return
        }

        if calibrationManager.isCalibrating {
            statusText = "Hold your comfortable upright posture while calibration finishes."
            return
        }

        switch postureState {
        case .unknown:
            statusText = "Start motion updates and keep your AirPods connected."
        case .needsCalibration:
            statusText = "Calibrate a comfortable upright posture to begin live posture tracking."
        case .good:
            statusText = "Good posture. Your head angle is close to the saved baseline."
        case .warning:
            statusText = "Posture drifting. Bring your head gently back toward the calibrated baseline."
        case .bad:
            statusText = "Bad posture detected. Your head angle is far from the calibrated baseline."
        }
    }
}
