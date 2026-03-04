//
//  ContentView.swift
//  GLM Usage
//
//  Created on 2026-03-03.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: UsageViewModel
    @State private var isEditingAPIKey = false
    @State private var inputAPIKey = ""

    var body: some View {
        Group {
            if isEditingAPIKey {
                APIKeySettingsView(
                    apiKey: $inputAPIKey,
                    onCancel: {
                        isEditingAPIKey = false
                    },
                    onSave: {
                        viewModel.saveAPIKey(inputAPIKey)
                        isEditingAPIKey = false
                        Task {
                            await viewModel.refresh()
                        }
                    }
                )
            } else {
                mainView
            }
        }
    }

    private var mainView: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text("GLM 用量查询")
                    .font(.headline)
                Spacer()
                ProgressView()
                    .scaleEffect(0.6)
                    .opacity(viewModel.isLoading ? 1 : 0)
                Button(action: {
                    inputAPIKey = viewModel.apiKey
                    isEditingAPIKey = true
                }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }

            Divider()

            // 主内容
            if !viewModel.hasAPIKey() {
                // 未配置API Key
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    Text("请配置API Key")
                        .font(.subheadline)
                    Text("在智谱官网获取API Key")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("设置API Key") {
                        inputAPIKey = ""
                        isEditingAPIKey = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if let error = viewModel.errorMessage {
                // 错误提示
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                // 额度列表 - 3个数据
                VStack(spacing: 12) {
                    QuotaRowView(quota: viewModel.usage.token5Hour)
                    QuotaRowView(quota: viewModel.usage.tokenWeekly)
                    QuotaRowView(quota: viewModel.usage.mcpMonthly, showResetTime: false)
                }
            }

            Divider()

            // 底部操作栏
            HStack {
                Button(action: {
                    Task {
                        await viewModel.refresh()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("刷新")
                    }
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isLoading || !viewModel.hasAPIKey())

                Spacer()

                Text("更新: \(viewModel.formatLastUpdated())")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 300)
        .task {
            if viewModel.hasAPIKey() {
                await viewModel.refresh()
            }
        }
    }
}

struct APIKeySettingsView: View {
    @Binding var apiKey: String
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("API Key 设置")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("请输入您的GLM API Key:")
                    .font(.subheadline)

                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 280)

                Text("在 open.bigmodel.cn 获取API Key")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                Button("取消") {
                    onCancel()
                }
                .buttonStyle(.bordered)

                Button("保存") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKey.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 340)
    }
}
