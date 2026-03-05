//
//  UpdateService.swift
//  GLM Usage
//
//  自动更新服务
//

import Foundation
import AppKit

enum UpdateError: LocalizedError {
    case noReleaseFound
    case noAssetFound
    case downloadFailed(Error)
    case installationFailed(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .noReleaseFound:
            return "未找到发布版本"
        case .noAssetFound:
            return "未找到下载文件"
        case .downloadFailed(let error):
            return "下载失败: \(error.localizedDescription)"
        case .installationFailed(let reason):
            return "安装失败: \(reason)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        }
    }
}

class UpdateService {
    static let shared = UpdateService()

    private let repoOwner = "BigKunLun"
    private let repoName = "GLM-Usage"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public API

    /// 获取最新 Release 信息
    func fetchLatestRelease() async throws -> GitHubRelease {
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        guard let url = URL(string: urlString) else {
            throw UpdateError.noReleaseFound
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("GLM-Usage-macOS", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw UpdateError.networkError(URLError(.badServerResponse))
            }

            // GitHub API 限流返回 403
            if httpResponse.statusCode == 403 {
                throw UpdateError.networkError(URLError(.cannotConnectToHost))
            }

            guard httpResponse.statusCode == 200 else {
                throw UpdateError.noReleaseFound
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            return release

        } catch let error as UpdateError {
            throw error
        } catch {
            throw UpdateError.networkError(error)
        }
    }

    /// 比较版本号，判断是否有新版本
    func isNewerVersion(_ remote: String, than local: String) -> Bool {
        let remoteClean = remote.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
        let localClean = local.trimmingCharacters(in: CharacterSet(charactersIn: "v"))

        let remoteParts = remoteClean.split(separator: ".").compactMap { Int($0) }
        let localParts = localClean.split(separator: ".").compactMap { Int($0) }

        // 补齐版本号位数
        let maxCount = max(remoteParts.count, localParts.count)
        let remotePadded = remoteParts + [Int](repeating: 0, count: maxCount - remoteParts.count)
        let localPadded = localParts + [Int](repeating: 0, count: maxCount - localParts.count)

        for (r, l) in zip(remotePadded, localPadded) {
            if r > l { return true }
            if r < l { return false }
        }

        return false
    }

    /// 检测是否为强制更新
    func isForceUpdate(_ release: GitHubRelease) -> Bool {
        guard let body = release.body else { return false }
        return body.contains("[FORCE]") || body.contains("<!-- force-update -->")
    }

    /// 获取当前应用版本
    func currentAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return "v\(version)"
    }

    /// 下载 zip 文件
    func downloadZip(from url: URL, progress: @escaping (Double) -> Void) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let destination = tempDir.appendingPathComponent("GLM_Usage_Update.zip")

        // 删除旧文件
        try? FileManager.default.removeItem(at: destination)

        var request = URLRequest(url: url)
        request.setValue("GLM-Usage-macOS", forHTTPHeaderField: "User-Agent")

        let (asyncBytes, response) = try await session.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UpdateError.downloadFailed(URLError(.badServerResponse))
        }

        let expectedLength = response.expectedContentLength
        var receivedLength: Int64 = 0

        // 创建文件句柄
        FileManager.default.createFile(atPath: destination.path, contents: nil)
        let fileHandle = try FileHandle(forWritingTo: destination)

        defer {
            try? fileHandle.close()
        }

        // 流式下载
        for try await byte in asyncBytes {
            try fileHandle.write(contentsOf: [byte])
            receivedLength += 1

            if expectedLength > 0 {
                let progressValue = Double(receivedLength) / Double(expectedLength)
                await MainActor.run {
                    progress(progressValue)
                }
            }
        }

        return destination
    }

    /// 安装更新
    func installUpdate(zipPath: URL) throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("GLM_Usage_Extract", isDirectory: true)

        // 清理旧的解压目录
        try? FileManager.default.removeItem(at: tempDir)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // 解压
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", zipPath.path, "-d", tempDir.path]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw UpdateError.installationFailed("解压失败")
        }

        // 查找解压后的 .app
        let extractedFiles = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        guard let appName = extractedFiles.first(where: { $0.hasSuffix(".app") }) else {
            throw UpdateError.installationFailed("未找到应用文件")
        }

        let extractedApp = tempDir.appendingPathComponent(appName)
        let targetApp = URL(fileURLWithPath: "/Applications/GLM_Usage.app")

        // 创建安装脚本
        let script = """
        #!/bin/bash
        sleep 1
        cp -R "\(extractedApp.path)" "\(targetApp.path)"
        open "\(targetApp.path)"
        """

        let scriptPath = tempDir.appendingPathComponent("install.sh")
        try script.write(to: scriptPath, atomically: true, encoding: .utf8)

        // 执行安装脚本
        let installProcess = Process()
        installProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
        installProcess.arguments = [scriptPath.path]

        try installProcess.run()

        // 退出当前应用
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApplication.shared.terminate(nil)
        }
    }
}
