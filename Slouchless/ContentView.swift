//
//  ContentView.swift
//  Slouchless
//
//  Created by Denislav Dimitrov on 8.07.26.
//

import CoreMotion
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PostureViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Slouchless")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("Connect compatible AirPods or headphones, calibrate your good posture, then watch live posture classification.")
                    .foregroundStyle(.secondary)
            }

            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 14) {
                statusRow("Posture", value: viewModel.postureState.title)
                statusRow("Pitch Delta", value: formattedAngle(viewModel.pitchDelta))
                statusRow("Roll Delta", value: formattedAngle(viewModel.rollDelta))
            }
            .font(.system(.body, design: .monospaced))

            Text(viewModel.statusText)
                .foregroundStyle(statusColor(for: viewModel.postureState))
                .textSelection(.enabled)

            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 14) {
                statusRow("Motion", value: viewModel.motionManager.isMotionAvailable ? "Available" : "Unavailable")
                statusRow("Streaming", value: viewModel.motionManager.isStreaming ? "Streaming" : "Stopped")

                if let authorizationStatus = viewModel.motionManager.authorizationStatus {
                    statusRow("Authorization", value: authorizationStatus.description)
                }

                Divider()
                    .gridCellUnsizedAxes(.horizontal)

                statusRow("Pitch", value: formattedAngle(viewModel.motionManager.latestPitch))
                statusRow("Roll", value: formattedAngle(viewModel.motionManager.latestRoll))
                statusRow("Yaw", value: formattedAngle(viewModel.motionManager.latestYaw))
            }
            .font(.system(.body, design: .monospaced))

            if let errorMessage = viewModel.motionManager.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            HStack(spacing: 12) {
                Button("Start") {
                    viewModel.startMotionUpdates()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.motionManager.isStreaming)

                Button("Stop") {
                    viewModel.stopMotionUpdates()
                }
                .disabled(!viewModel.motionManager.isStreaming)
            }

            VStack(alignment: .leading, spacing: 12) {
                Button(viewModel.calibrationManager.isCalibrating ? "Calibrating..." : "Calibrate Good Posture") {
                    viewModel.startCalibration()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.calibrationManager.isCalibrating)

                if viewModel.calibrationManager.isCalibrating {
                    Text("Calibrating...")
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }

                if let profile = viewModel.calibrationManager.currentProfile {
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

    private func statusColor(for state: PostureState) -> Color {
        switch state {
        case .unknown, .needsCalibration:
            .secondary
        case .good:
            .green
        case .warning:
            .orange
        case .bad:
            .red
        }
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
