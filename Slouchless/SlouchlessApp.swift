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

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            Image(systemName: viewModel.postureState.menuBarSystemImageName)
        }
        .menuBarExtraStyle(.window)
    }
}
