//
//  MenuBarView.swift
//  Slouchless
//
//  Created by Denislav Dimitrov on 8.07.26.
//

import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: PostureViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                statusRow("AirPods Motion", value: motionStatus)
                statusRow("Posture", value: viewModel.postureState.displayTitle)
                statusRow("Pitch Delta", value: formattedAngle(viewModel.pitchDelta))
                statusRow("Calibration", value: calibrationStatus)
            }

            PostureProgressBar(
                progress: viewModel.postureProgress ?? 0,
                state: viewModel.postureState,
                pitchDelta: viewModel.pitchDelta
            )
            .padding(.top, 2)

            if !viewModel.statusText.isEmpty {
                Text(viewModel.statusText)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            VStack(spacing: 8) {
                Button("Start Monitoring") {
                    viewModel.startMotionUpdates()
                }
                .disabled(viewModel.motionManager.isStreaming)

                Button("Stop Monitoring") {
                    viewModel.stopMotionUpdates()
                }
                .disabled(!viewModel.motionManager.isStreaming)

                Button(calibrationButtonTitle) {
                    viewModel.startCalibration()
                }
                .disabled(viewModel.calibrationManager.isCalibrating)

                Divider()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
        .padding(16)
        .frame(width: 280, alignment: .topLeading)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: viewModel.postureState.menuBarSystemImageName)
                .font(.title2)
                .foregroundStyle(statusColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("PosturePods")
                    .font(.headline)
                Text(viewModel.motionManager.isStreaming ? "Monitoring" : "Idle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var motionStatus: String {
        if viewModel.motionManager.isStreaming {
            return "Streaming"
        }

        return viewModel.motionManager.isMotionAvailable ? "Available" : "Unavailable"
    }

    private var calibrationStatus: String {
        if viewModel.calibrationManager.isCalibrating {
            return "Calibrating..."
        }

        guard let profile = viewModel.calibrationManager.currentProfile else {
            return "Not calibrated"
        }

        return profile.createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    private var calibrationButtonTitle: String {
        viewModel.calibrationManager.isCalibrating ? "Calibrating..." : "Calibrate Good Posture"
    }

    private var statusColor: Color {
        switch viewModel.postureState {
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

    private func statusRow(_ label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.callout)
    }

    private func formattedAngle(_ angle: Double?) -> String {
        guard let angle else {
            return "--"
        }

        return angle.formatted(.number.precision(.fractionLength(2))) + " deg"
    }
}
