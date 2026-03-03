//
//  GLM_UsageApp.swift
//  GLM Usage
//
//  Created on 2026-03-03.
//

import SwiftUI

@main
struct GLM_UsageApp: App {
    @StateObject private var viewModel = UsageViewModel()

    var body: some Scene {
        MenuBarExtra(viewModel.statusText) {
            ContentView()
                .environmentObject(viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
