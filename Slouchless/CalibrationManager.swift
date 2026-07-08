//
//  CalibrationManager.swift
//  Slouchless
//
//  Created by Denislav Dimitrov on 8.07.26.
//

import Combine
import Foundation

@MainActor
final class CalibrationManager: ObservableObject {
    @Published private(set) var isCalibrating = false
    @Published private(set) var currentProfile: CalibrationProfile?

    private struct MotionSample {
        let pitch: Double
        let roll: Double
        let yaw: Double
    }

    private let userDefaults: UserDefaults
    private let storageKey = "Slouchless.CalibrationProfile"
    private var calibrationTask: Task<Void, Never>?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadSavedProfile()
    }

    deinit {
        calibrationTask?.cancel()
    }

    func startCalibration(using motionManager: AirPodsMotionManager) {
        startCalibration {
            guard let pitch = motionManager.latestPitch,
                  let roll = motionManager.latestRoll,
                  let yaw = motionManager.latestYaw else {
                return nil
            }

            return MotionSample(pitch: pitch, roll: roll, yaw: yaw)
        }
    }

    private func startCalibration(sampleProvider: @MainActor @escaping () -> MotionSample?) {
        guard !isCalibrating else {
            return
        }

        calibrationTask?.cancel()
        isCalibrating = true

        calibrationTask = Task { [weak self] in
            guard let self else { return }

            let startedAt = Date()
            var samples: [MotionSample] = []

            while !Task.isCancelled && Date().timeIntervalSince(startedAt) < 3 {
                if let sample = sampleProvider() {
                    samples.append(sample)
                }

                try? await Task.sleep(for: .milliseconds(100))
            }

            guard !Task.isCancelled else {
                self.isCalibrating = false
                return
            }

            if let profile = Self.profile(from: samples, createdAt: Date()) {
                self.currentProfile = profile
                self.save(profile)
            }

            self.isCalibrating = false
            self.calibrationTask = nil
        }
    }

    private func loadSavedProfile() {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return
        }

        currentProfile = try? JSONDecoder().decode(CalibrationProfile.self, from: data)
    }

    private func save(_ profile: CalibrationProfile) {
        guard let data = try? JSONEncoder().encode(profile) else {
            return
        }

        userDefaults.set(data, forKey: storageKey)
    }

    private static func profile(from samples: [MotionSample], createdAt: Date) -> CalibrationProfile? {
        guard !samples.isEmpty else {
            return nil
        }

        let totals = samples.reduce(into: (pitch: 0.0, roll: 0.0, yaw: 0.0)) { result, sample in
            result.pitch += sample.pitch
            result.roll += sample.roll
            result.yaw += sample.yaw
        }
        let count = Double(samples.count)

        return CalibrationProfile(
            baselinePitch: totals.pitch / count,
            baselineRoll: totals.roll / count,
            baselineYaw: totals.yaw / count,
            createdAt: createdAt
        )
    }
}
