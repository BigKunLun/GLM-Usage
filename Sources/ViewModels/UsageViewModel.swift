//
//  UsageViewModel.swift
//  GLM Usage
//
//  Created on 2026-03-03.
//

import Foundation
import SwiftUI

@MainActor
class UsageViewModel: ObservableObject {
    @Published var usage: GLMUsage = .empty
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var apiKey: String = ""
    @Published var showSettings: Bool = false

    private let apiService = GLMAPIService()
    private let apiKeyKey = "glm_api_key"
    private var timer: Timer?

    init() {
        loadAPIKey()
        startAutoRefresh()
    }

    // MARK: - API Key 管理

    func loadAPIKey() {
        apiKey = UserDefaults.standard.string(forKey: apiKeyKey) ?? ""
    }

    func saveAPIKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: apiKeyKey)
    }

    func hasAPIKey() -> Bool {
        return !apiKey.isEmpty
    }

    // MARK: - 数据刷新

    func refresh() async {
        guard hasAPIKey() else {
            errorMessage = "请先配置API Key"
            showSettings = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let newUsage = try await apiService.fetchUsage(apiKey: apiKey)
            self.usage = newUsage
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func formatLastUpdated() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: usage.lastUpdated)
    }

    // MARK: - 状态栏文本

    var statusText: String {
        if isLoading {
            return "GLM ⏳"
        }
        if !hasAPIKey() {
            return "GLM ⚙️"
        }
        if errorMessage != nil {
            return "GLM ❌"
        }
        let percentage = Int(usage.tokenWeekly.usagePercentage.rounded())
        return "GLM \(percentage)%"
    }

    // MARK: - 定时刷新

    func startAutoRefresh() {
        stopAutoRefresh()
        timer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }

    func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        timer?.invalidate()
    }
}
