//
//  AirPodsMotionManager.swift
//  Slouchless
//
//  Created by Denislav Dimitrov on 8.07.26.
//

import Combine
import CoreMotion
import Foundation

@MainActor
final class AirPodsMotionManager: ObservableObject {
    @Published private(set) var isMotionAvailable = false
    @Published private(set) var isStreaming = false
    @Published private(set) var authorizationStatus: CMAuthorizationStatus?
    @Published private(set) var latestPitch: Double?
    @Published private(set) var latestRoll: Double?
    @Published private(set) var latestYaw: Double?
    @Published private(set) var errorMessage: String?

    private let motionManager = CMHeadphoneMotionManager()
    private let motionQueue = OperationQueue()

    init() {
        motionQueue.name = "Slouchless.HeadphoneMotionQueue"
        motionQueue.qualityOfService = .userInitiated

        refreshAvailability()
        refreshAuthorizationStatus()
    }

    func startMotionUpdates() {
        refreshAvailability()
        refreshAuthorizationStatus()

        guard isMotionAvailable else {
            errorMessage = "Headphone motion is unavailable. Connect AirPods or supported headphones with head tracking."
            return
        }

        errorMessage = nil

        motionManager.startDeviceMotionUpdates(to: motionQueue) { [weak self] motion, error in
            Task { @MainActor in
                guard let self else { return }

                self.refreshAvailability()
                self.refreshAuthorizationStatus()
                self.isStreaming = self.motionManager.isDeviceMotionActive

                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let attitude = motion?.attitude else {
                    return
                }

                self.latestPitch = Self.degrees(fromRadians: attitude.pitch)
                self.latestRoll = Self.degrees(fromRadians: attitude.roll)
                self.latestYaw = Self.degrees(fromRadians: attitude.yaw)
            }
        }

        isStreaming = motionManager.isDeviceMotionActive
    }

    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        isStreaming = false
    }

    private func refreshAvailability() {
        isMotionAvailable = motionManager.isDeviceMotionAvailable
    }

    private func refreshAuthorizationStatus() {
        authorizationStatus = CMHeadphoneMotionManager.authorizationStatus()
    }

    private static func degrees(fromRadians radians: Double) -> Double {
        radians * 180.0 / .pi
    }
}
