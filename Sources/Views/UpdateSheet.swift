//
//  UpdateSheet.swift
//  GLM Usage
//
//  更新弹窗视图
//

import SwiftUI

struct UpdateSheet: View {
    @ObservedObject var viewModel: UpdateViewModel
    let release: GitHubRelease

    @State private var changelogText: AttributedString = ""

    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("发现新版本 \(release.tagName)")
                    .font(.headline)
            }
            .padding(.top, 8)

            Divider()

            // 版本信息
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("当前版本:")
                        .foregroundColor(.secondary)
                    Text(viewModel.currentVersion)
                }
                HStack {
                    Text("最新版本:")
                        .foregroundColor(.secondary)
                    Text(release.tagName)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 更新内容
            if let body = release.body, !body.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("更新内容:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ScrollView {
                        Text(changelogText)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 120)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                }
            }

            // 下载进度
            if case .downloading(let progress) = viewModel.state {
                VStack(spacing: 4) {
                    if progress > 0 {
                        ProgressView(value: progress) {
                            Text("下载中... \(Int(progress * 100))%")
                                .font(.caption)
                        }
                    } else {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("正在下载...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // 错误提示
            if case .error(let message) = viewModel.state {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            Divider()

            // 按钮
            HStack(spacing: 12) {
                // 稍后提醒按钮（强制更新时隐藏）
                if !viewModel.isForceUpdate {
                    Button("稍后提醒") {
                        viewModel.reset()
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                }

                // 下载页面按钮
                if viewModel.downloadPageURL != nil {
                    Button("打开下载页面") {
                        if let url = viewModel.downloadPageURL {
                            NSWorkspace.shared.open(url)
                        }
                        viewModel.reset()
                    }
                }

                // 立即更新按钮
                if case .downloading = viewModel.state {
                    Button("下载中...") {
                        // 取消操作暂不支持
                    }
                    .disabled(true)
                } else if case .readyToInstall = viewModel.state {
                    Text("即将重启应用...")
                        .foregroundColor(.secondary)
                } else {
                    Button("立即更新") {
                        Task {
                            await viewModel.downloadAndInstall()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear {
            parseChangelog()
        }
    }

    private func parseChangelog() {
        guard let body = release.body else { return }

        // 简单的 Markdown 转 AttributedString
        // 移除 [FORCE] 标记
        var cleanBody = body
            .replacingOccurrences(of: "[FORCE]", with: "")
            .replacingOccurrences(of: "<!-- force-update -->", with: "")

        // 限制长度
        if cleanBody.count > 500 {
            cleanBody = String(cleanBody.prefix(500)) + "..."
        }

        if let attributed = try? AttributedString(markdown: cleanBody) {
            changelogText = attributed
        } else {
            changelogText = AttributedString(cleanBody)
        }
    }
}
