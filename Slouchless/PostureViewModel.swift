//
//  PostureViewModel.swift
//  Slouchless
//
//  Created by Denislav Dimitrov on 8.07.26.
//

import Combine
import Foundation
import UserNotifications

@MainActor
protocol PostureNotificationScheduling: AnyObject {
    func requestAuthorization()
    func scheduleBadPostureNotification(after delay: TimeInterval)
    func cancelBadPostureNotification()
}

@MainActor
final class UserNotificationScheduler: NSObject, PostureNotificationScheduling, UNUserNotificationCenterDelegate {
    private let center: UNUserNotificationCenter
    private let badPostureNotificationIdentifier = "Slouchless.BadPosture"

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
        center.delegate = self
    }

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { isAuthorized, error in
            if let error {
                print("Slouchless notification authorization failed: \(error.localizedDescription)")
            } else if !isAuthorized {
                print("Slouchless notifications are not authorized.")
            }
        }
    }

    func scheduleBadPostureNotification(after delay: TimeInterval) {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            Task { @MainActor in
                self.scheduleBadPostureNotification(after: delay, settings: settings)
            }
        }
    }

    private func scheduleBadPostureNotification(
        after delay: TimeInterval,
        settings: UNNotificationSettings
    ) {
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            addBadPostureNotification(after: delay)
        case .notDetermined:
            center.requestAuthorization(options: [.alert, .sound]) { [weak self] isAuthorized, error in
                guard let self else { return }

                Task { @MainActor in
                    if isAuthorized {
                        self.addBadPostureNotification(after: delay)
                    } else if let error {
                        print("Slouchless notification authorization failed: \(error.localizedDescription)")
                    } else {
                        print("Slouchless notifications are not authorized.")
                    }
                }
            }
        case .denied:
            print("Slouchless notifications are disabled in System Settings.")
        @unknown default:
            print("Slouchless notification authorization status is unknown.")
        }
    }

    private func addBadPostureNotification(after delay: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Straighten up"
        content.body = "You've been in a bad posture state for more than 5 seconds."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: badPostureNotificationIdentifier,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [badPostureNotificationIdentifier])
        center.add(request) { error in
            if let error {
                print("Slouchless failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    func cancelBadPostureNotification() {
        center.removePendingNotificationRequests(withIdentifiers: [badPostureNotificationIdentifier])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

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
    private let notificationScheduler: PostureNotificationScheduling
    private let badPostureNotificationDelay: TimeInterval
    private var cancellables: Set<AnyCancellable> = []
    private var hasScheduledBadPostureNotification = false

    convenience init() {
        self.init(
            motionManager: AirPodsMotionManager(),
            calibrationManager: CalibrationManager(),
            analyzer: PostureAnalyzer(),
            notificationScheduler: UserNotificationScheduler()
        )
    }

    init(
        motionManager: AirPodsMotionManager,
        calibrationManager: CalibrationManager,
        analyzer: PostureAnalyzer,
        notificationScheduler: PostureNotificationScheduling,
        badPostureNotificationDelay: TimeInterval = 5
    ) {
        self.motionManager = motionManager
        self.calibrationManager = calibrationManager
        self.analyzer = analyzer
        self.notificationScheduler = notificationScheduler
        self.badPostureNotificationDelay = badPostureNotificationDelay

        notificationScheduler.requestAuthorization()
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
        updateBadPostureNotification()
        updateStatusText()
    }

    private func updateBadPostureNotification() {
        guard postureState == .bad else {
            hasScheduledBadPostureNotification = false
            notificationScheduler.cancelBadPostureNotification()
            return
        }

        guard !hasScheduledBadPostureNotification else {
            return
        }

        hasScheduledBadPostureNotification = true
        notificationScheduler.scheduleBadPostureNotification(after: badPostureNotificationDelay)
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
