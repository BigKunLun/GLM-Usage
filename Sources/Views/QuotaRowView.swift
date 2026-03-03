//
//  QuotaRowView.swift
//  GLM Usage
//
//  Created on 2026-03-03.
//

import SwiftUI

struct QuotaRowView: View {
    let quota: Quota
    let showResetTime: Bool

    init(quota: Quota, showResetTime: Bool = true) {
        self.quota = quota
        self.showResetTime = showResetTime
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 标题行
            HStack {
                Text(quota.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.0f%%", quota.usagePercentage))
                    .font(.caption)
                    .foregroundColor(statusColor)
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景条
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // 进度条 (显示使用量)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: geometry.size.width * min(1, quota.usagePercentage / 100), height: 8)
                }
            }
            .frame(height: 8)

            // 使用量详情
            HStack {
                if quota.hasDetails {
                    Text("\(formatNumber(quota.used)) / \(formatNumber(quota.total))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("已使用 \(String(format: "%.0f%%", quota.usagePercentage))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if showResetTime, let resetTime = quota.resetTime {
                    Spacer()
                    Text("重置: \(formatResetTime(resetTime))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch quota.statusColor {
        case .good:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 1_000_000 {
            return String(format: "%.1fM", Double(n) / 1_000_000)
        } else if n >= 1_000 {
            return String(format: "%.1fK", Double(n) / 1_000)
        }
        return String(n)
    }

    private func formatResetTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
