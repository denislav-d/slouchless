//
//  ContentView.swift
//  Slouchless
//
//  Created by Denislav Dimitrov on 8.07.26.
//

import CoreMotion
import SwiftUI

struct ContentView: View {
    @StateObject private var motionManager = AirPodsMotionManager()
    @StateObject private var calibrationManager = CalibrationManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("AirPods Motion Debug")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("Connect compatible AirPods or headphones, then start motion updates to inspect live attitude values.")
                    .foregroundStyle(.secondary)
            }

            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 14) {
                statusRow("Motion", value: motionManager.isMotionAvailable ? "Available" : "Unavailable")
                statusRow("Streaming", value: motionManager.isStreaming ? "Streaming" : "Stopped")

                if let authorizationStatus = motionManager.authorizationStatus {
                    statusRow("Authorization", value: authorizationStatus.description)
                }

                Divider()
                    .gridCellUnsizedAxes(.horizontal)

                statusRow("Pitch", value: formattedAngle(motionManager.latestPitch))
                statusRow("Roll", value: formattedAngle(motionManager.latestRoll))
                statusRow("Yaw", value: formattedAngle(motionManager.latestYaw))
            }
            .font(.system(.body, design: .monospaced))

            if let errorMessage = motionManager.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            HStack(spacing: 12) {
                Button("Start") {
                    motionManager.startMotionUpdates()
                }
                .buttonStyle(.borderedProminent)
                .disabled(motionManager.isStreaming)

                Button("Stop") {
                    motionManager.stopMotionUpdates()
                }
                .disabled(!motionManager.isStreaming)
            }

            VStack(alignment: .leading, spacing: 12) {
                Button(calibrationManager.isCalibrating ? "Calibrating..." : "Calibrate Good Posture") {
                    calibrationManager.startCalibration(using: motionManager)
                }
                .buttonStyle(.borderedProminent)
                .disabled(calibrationManager.isCalibrating)

                if calibrationManager.isCalibrating {
                    Text("Calibrating...")
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }

                if let profile = calibrationManager.currentProfile {
                    Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                        statusRow("Baseline Pitch", value: formattedAngle(profile.baselinePitch))
                        statusRow("Baseline Roll", value: formattedAngle(profile.baselineRoll))
                        statusRow("Baseline Yaw", value: formattedAngle(profile.baselineYaw))
                        statusRow("Calibrated", value: profile.createdAt.formatted(date: .abbreviated, time: .standard))
                    }
                    .font(.system(.body, design: .monospaced))
                }
            }

            Spacer()
        }
        .padding(32)
        .frame(minWidth: 520, minHeight: 420, alignment: .topLeading)
    }

    private func statusRow(_ label: String, value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .textSelection(.enabled)
        }
    }

    private func formattedAngle(_ angle: Double?) -> String {
        guard let angle else {
            return "--"
        }

        return angle.formatted(.number.precision(.fractionLength(2))) + " deg"
    }
}

private extension CMAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            "Not determined"
        case .restricted:
            "Restricted"
        case .denied:
            "Denied"
        case .authorized:
            "Authorized"
        @unknown default:
            "Unknown"
        }
    }
}
