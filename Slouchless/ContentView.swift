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

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(viewModel.postureState.displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(statusColor(for: viewModel.postureState))

                    Spacer()

                    Text(progressText(viewModel.postureProgress))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                PostureProgressBar(
                    progress: viewModel.postureProgress ?? 0,
                    state: viewModel.postureState,
                    pitchDelta: viewModel.pitchDelta
                )

                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                    statusRow("Pitch Delta", value: formattedAngle(viewModel.pitchDelta))
                    statusRow("Roll Delta", value: formattedAngle(viewModel.rollDelta))
                }
                .font(.system(.body, design: .monospaced))
            }

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

    private func progressText(_ progress: Double?) -> String {
        guard let progress else {
            return "--"
        }

        return progress.formatted(.percent.precision(.fractionLength(0)))
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

struct PostureProgressBar: View {
    let progress: Double
    let state: PostureState
    let pitchDelta: Double?

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text("Posture drift")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(driftText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            GeometryReader { proxy in
                let activeWidth = max(proxy.size.width * clampedProgress, 8)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.secondary.opacity(0.16))
                        .frame(height: 10)

                    Capsule()
                        .fill(progressColor.gradient)
                        .frame(width: activeWidth, height: 10)
                        .animation(.easeOut(duration: 0.18), value: clampedProgress)
                }
            }
            .frame(height: 10)
        }
    }

    private var progressColor: Color {
        switch state {
        case .unknown, .needsCalibration:
            .secondary
        case .good:
            .green
        case .warning:
            .yellow
        case .bad:
            .red
        }
    }

    private var driftText: String {
        guard let pitchDelta else {
            return "--"
        }

        let magnitude = abs(pitchDelta).formatted(.number.precision(.fractionLength(0)))
        return magnitude + " deg toward bad posture"
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
