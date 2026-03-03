//
//  GLMUsage.swift
//  GLM Usage
//
//  Created on 2026-03-03.
//

import Foundation

// MARK: - 额度状态枚举
enum QuotaStatus {
    case good      // 绿色 <30%
    case warning   // 黄色 30-60%
    case critical  // 红色 >60%
}

// MARK: - 单个额度信息
struct Quota: Codable, Identifiable {
    var id: String { name }
    let name: String          // 额度名称
    let used: Int             // 已使用
    let total: Int            // 总额度
    let resetTime: Date?      // 重置时间（可选）
    let percentage: Double    // 使用百分比

    var remaining: Int {
        max(0, total - used)
    }

    var usagePercentage: Double {
        if percentage > 0 {
            return percentage
        }
        guard total > 0 else { return 0 }
        return Double(used) / Double(total) * 100
    }

    var remainingPercentage: Double {
        return 100 - usagePercentage
    }

    var statusColor: QuotaStatus {
        if usagePercentage < 30 {
            return .good
        } else if usagePercentage < 60 {
            return .warning
        } else {
            return .critical
        }
    }

    var hasDetails: Bool {
        return total > 0 || used > 0
    }

    init(name: String, used: Int, total: Int, resetTime: Date?, percentage: Double = 0) {
        self.name = name
        self.used = used
        self.total = total
        self.resetTime = resetTime
        self.percentage = percentage
    }
}

// MARK: - GLM用量数据
struct GLMUsage: Codable {
    let token5Hour: Quota     // Token 5小时额度
    let tokenWeekly: Quota    // Token 每周额度
    let mcpMonthly: Quota     // MCP 每月额度
    let lastUpdated: Date

    static var preview: GLMUsage {
        GLMUsage(
            token5Hour: Quota(name: "Token (5小时)", used: 0, total: 0, resetTime: Date().addingTimeInterval(5 * 3600), percentage: 14),
            tokenWeekly: Quota(name: "Token (每周)", used: 0, total: 0, resetTime: Date().addingTimeInterval(7 * 24 * 3600), percentage: 23),
            mcpMonthly: Quota(name: "MCP (每月)", used: 503, total: 4000, resetTime: Date().addingTimeInterval(30 * 24 * 3600), percentage: 12),
            lastUpdated: Date()
        )
    }

    static var empty: GLMUsage {
        GLMUsage(
            token5Hour: Quota(name: "Token (5小时)", used: 0, total: 0, resetTime: nil, percentage: 0),
            tokenWeekly: Quota(name: "Token (每周)", used: 0, total: 0, resetTime: nil, percentage: 0),
            mcpMonthly: Quota(name: "MCP (每月)", used: 0, total: 0, resetTime: nil, percentage: 0),
            lastUpdated: Date()
        )
    }
}
