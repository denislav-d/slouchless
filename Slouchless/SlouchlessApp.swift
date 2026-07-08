//
//  SlouchlessApp.swift
//  Slouchless
//
//  Created by Denislav Dimitrov on 8.07.26.
//

import SwiftUI

@main
struct SlouchlessApp: App {
    @StateObject private var viewModel = PostureViewModel()
    @State private var badPostureWiggleTrigger = 0

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
            Divider()
            Button("Test Wiggle") {
                badPostureWiggleTrigger &+= 1
            }
        } label: {
            menuBarIcon
        }
        .menuBarExtraStyle(.window)
        .onChange(of: viewModel.postureState) { _, postureState in
            guard postureState == .bad else { return }
            badPostureWiggleTrigger &+= 1
        }
    }

    @ViewBuilder
    private var menuBarIcon: some View {
        if #available(macOS 15.0, *) {
            baseMenuBarIcon
                .symbolEffect(.wiggle.byLayer, value: badPostureWiggleTrigger)
        } else {
            baseMenuBarIcon
        }
    }

    private var baseMenuBarIcon: some View {
        Image(systemName: viewModel.postureState.menuBarSystemImageName)
            .symbolRenderingMode(.palette)
            .foregroundStyle(
                viewModel.postureState.menuBarPrimaryColor,
                viewModel.postureState.menuBarSecondaryColor
            )
    }
}

private extension PostureState {
    var menuBarPrimaryColor: Color {
        switch self {
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

    var menuBarSecondaryColor: Color {
        switch self {
        case .unknown, .needsCalibration:
            .secondary.opacity(0.65)
        case .good:
            .green.opacity(0.55)
        case .warning:
            .yellow.opacity(0.65)
        case .bad:
            .red.opacity(0.55)
        }
    }
}

