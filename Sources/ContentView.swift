//
//  ContentView.swift
//  GLM Usage
//
//  Created on 2026-03-03.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: UsageViewModel
    @State private var showAPIKeyInput = false
    @State private var inputAPIKey = ""

    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text("GLM 用量查询")
                    .font(.headline)
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                }
                Button(action: {
                    inputAPIKey = viewModel.apiKey
                    showAPIKeyInput = true
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
                        showAPIKeyInput = true
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
        .sheet(isPresented: $showAPIKeyInput) {
            APIKeySettingsView(
                apiKey: $inputAPIKey,
                onSave: {
                    viewModel.saveAPIKey(inputAPIKey)
                    showAPIKeyInput = false
                    Task {
                        await viewModel.refresh()
                    }
                }
            )
        }
    }
}

struct APIKeySettingsView: View {
    @Binding var apiKey: String
    @Environment(\.dismiss) var dismiss
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
                    dismiss()
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
