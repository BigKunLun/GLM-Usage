//
//  UpdateViewModel.swift
//  GLM Usage
//
//  更新功能状态管理
//

import Foundation
import SwiftUI

enum UpdateState: Equatable {
    case idle
    case checking
    case noUpdate
    case updateAvailable(GitHubRelease)
    case downloading(progress: Double)
    case readyToInstall
    case error(String)

    static func == (lhs: UpdateState, rhs: UpdateState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.checking, .checking):
            return true
        case (.noUpdate, .noUpdate):
            return true
        case (.updateAvailable(let l), .updateAvailable(let r)):
            return l.tagName == r.tagName
        case (.downloading(let lp), .downloading(let rp)):
            return lp == rp
        case (.readyToInstall, .readyToInstall):
            return true
        case (.error(let l), .error(let r)):
            return l == r
        default:
            return false
        }
    }
}

@MainActor
class UpdateViewModel: ObservableObject {
    @Published var state: UpdateState = .idle
    @Published var showUpdateSheet = false

    private let updateService = UpdateService.shared
    private(set) var currentVersion: String

    init() {
        self.currentVersion = updateService.currentAppVersion()
    }

    // MARK: - Public API

    /// 检查更新
    func checkForUpdate() async {
        state = .checking

        do {
            let release = try await updateService.fetchLatestRelease()
            let latestVersion = release.tagName

            if updateService.isNewerVersion(latestVersion, than: currentVersion) {
                state = .updateAvailable(release)
                showUpdateSheet = true
            } else {
                state = .noUpdate
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// 获取当前更新信息（如果有）
    var updateInfo: GitHubRelease? {
        if case .updateAvailable(let release) = state {
            return release
        }
        return nil
    }

    /// 是否为强制更新
    var isForceUpdate: Bool {
        guard let release = updateInfo else { return false }
        return updateService.isForceUpdate(release)
    }

    /// 下载并安装更新
    func downloadAndInstall() async {
        guard let release = updateInfo,
              let asset = release.assets.first(where: { $0.name == "GLM_Usage.zip" }) else {
            state = .error("未找到下载文件")
            return
        }

        guard let downloadUrl = URL(string: asset.browserDownloadUrl) else {
            state = .error("下载地址无效")
            return
        }

        state = .downloading(progress: 0)

        do {
            let zipPath = try await updateService.downloadZip(from: downloadUrl) { [weak self] progress in
                Task { @MainActor in
                    self?.state = .downloading(progress: progress)
                }
            }

            state = .readyToInstall

            // 执行安装
            try updateService.installUpdate(zipPath: zipPath)

        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// 重置状态
    func reset() {
        state = .idle
        showUpdateSheet = false
    }

    /// 获取下载页面 URL
    var downloadPageURL: URL? {
        guard let release = updateInfo else { return nil }
        return URL(string: release.htmlUrl)
    }
}
