//
//  GLMAPIService.swift
//  GLM Usage
//
//  Created on 2026-03-03.
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case parsingError
    case unauthorized
    case noAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的API地址"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .invalidResponse:
            return "服务器响应无效"
        case .parsingError:
            return "数据解析失败"
        case .unauthorized:
            return "API Key无效或已过期"
        case .noAPIKey:
            return "请先配置API Key"
        }
    }
}

class GLMAPIService {

    private let baseURL = "https://api.z.ai"
    private let usageEndpoint = "/api/monitor/usage/quota/limit"

    func fetchUsage(apiKey: String) async throws -> GLMUsage {
        guard !apiKey.isEmpty else {
            throw APIError.noAPIKey
        }

        guard let url = URL(string: baseURL + usageEndpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }

            guard httpResponse.statusCode == 200 else {
                throw APIError.invalidResponse
            }

            return try parseUsageResponse(data)

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func parseUsageResponse(_ data: Data) throws -> GLMUsage {
        struct APIResponse: Codable {
            let code: Int?
            let data: DataClass?
            let success: Bool?

            struct DataClass: Codable {
                let limits: [Limit]?
                let level: String?
            }

            struct Limit: Codable {
                let type: String
                let unit: Int?
                let number: Int?
                let usage: Int?
                let currentValue: Int?
                let remaining: Int?
                let percentage: Double?
                let nextResetTime: Int64?
            }
        }

        guard let response = try? JSONDecoder().decode(APIResponse.self, from: data) else {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("API响应解析失败: \(jsonString)")
            }
            throw APIError.parsingError
        }

        guard let limits = response.data?.limits else {
            throw APIError.parsingError
        }

        var token5Hour: Quota?
        var tokenWeekly: Quota?
        var mcpMonthly: Quota?

        for limit in limits {
            let resetTime = parseTimestamp(limit.nextResetTime)

            if limit.type == "TIME_LIMIT" {
                // TIME_LIMIT: MCP调用 (每月)
                mcpMonthly = Quota(
                    name: "MCP (每月)",
                    used: limit.currentValue ?? 0,
                    total: limit.usage ?? 0,
                    resetTime: resetTime,
                    percentage: limit.percentage ?? 0
                )
            } else if limit.type == "TOKENS_LIMIT" {
                // 根据unit和number判断是5小时还是每周
                // unit=3, number=5 可能是5小时
                // unit=6, number=1 是每月
                if limit.unit == 3 && limit.number == 5 {
                    token5Hour = Quota(
                        name: "Token (5小时)",
                        used: 0,
                        total: 0,
                        resetTime: resetTime,
                        percentage: limit.percentage ?? 0
                    )
                } else if limit.unit == 6 && limit.number == 1 {
                    tokenWeekly = Quota(
                        name: "Token (每周)",
                        used: 0,
                        total: 0,
                        resetTime: resetTime,
                        percentage: limit.percentage ?? 0
                    )
                }
            }
        }

        return GLMUsage(
            token5Hour: token5Hour ?? Quota(name: "Token (5小时)", used: 0, total: 0, resetTime: nil, percentage: 0),
            tokenWeekly: tokenWeekly ?? Quota(name: "Token (每周)", used: 0, total: 0, resetTime: nil, percentage: 0),
            mcpMonthly: mcpMonthly ?? Quota(name: "MCP (每月)", used: 0, total: 0, resetTime: nil, percentage: 0),
            lastUpdated: Date()
        )
    }

    private func parseTimestamp(_ timestamp: Int64?) -> Date? {
        guard let ts = timestamp else { return nil }
        return Date(timeIntervalSince1970: Double(ts) / 1000.0)
    }
}
