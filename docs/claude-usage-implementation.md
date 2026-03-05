# Claude Pro Plan 用量监控实现方案

## 背景

尝试在 GLM Usage 应用中添加 Claude Pro Plan 用量监控功能，但由于 API 限制问题，暂时无法稳定使用。

## API 信息

### 端点
```
GET https://api.anthropic.com/api/oauth/usage
```

### 认证
从 macOS Keychain 获取 OAuth token：
- Service: `Claude Code-credentials`
- Token 路径: `claudeAiOauth.accessToken`

### 请求头
```
Authorization: Bearer {accessToken}
anthropic-beta: oauth-2025-04-20
Content-Type: application/json
```

### 响应格式
```json
{
  "five_hour": {
    "utilization": 45.5,
    "resets_at": "2026-03-04T12:00:00.000Z"
  },
  "seven_day": {
    "utilization": 78.2,
    "resets_at": "2026-03-07T00:00:00.000Z"
  }
}
```

- `utilization`: 百分比 (0-100)
- `resets_at`: ISO8601 格式的重置时间

## 代码实现

### 1. 数据模型 (ClaudeUsage.swift)

```swift
struct ClaudeUsage: Codable {
    let fiveHour: ClaudeLimit
    let sevenDay: ClaudeLimit
    let lastUpdated: Date

    static var empty: ClaudeUsage {
        ClaudeUsage(
            fiveHour: ClaudeLimit(used: 0, remaining: nil, percentageUsed: 0, resets: nil),
            sevenDay: ClaudeLimit(used: 0, remaining: nil, percentageUsed: 0, resets: nil),
            lastUpdated: Date()
        )
    }
}

struct ClaudeLimit: Codable {
    let used: Int
    let remaining: Int?
    let percentageUsed: Double
    let resets: Date?
}
```

### 2. API 服务 (ClaudeAPIService.swift)

```swift
class ClaudeAPIService {
    private let apiURL = "https://api.anthropic.com/api/oauth/usage"

    func fetchUsage() async throws -> ClaudeUsage {
        guard let token = getOAuthTokenFromKeychain() else {
            throw APIError.noAPIKey
        }

        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 429 {
            throw APIError.rateLimited
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        return try parseUsageResponse(data)
    }

    private func getOAuthTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }

        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }

        if let claudeAiOauth = json["claudeAiOauth"] as? [String: Any],
           let accessToken = claudeAiOauth["accessToken"] as? String {
            return accessToken
        }

        return nil
    }

    private func parseUsageResponse(_ data: Data) throws -> ClaudeUsage {
        struct UsageResponse: Codable {
            let five_hour: LimitInfo?
            let seven_day: LimitInfo?
        }

        struct LimitInfo: Codable {
            let utilization: Double?
            let resets_at: String?
        }

        let response = try JSONDecoder().decode(UsageResponse.self, from: data)

        let fiveHourUtilization = response.five_hour?.utilization ?? 0
        let sevenDayUtilization = response.seven_day?.utilization ?? 0

        return ClaudeUsage(
            fiveHour: ClaudeLimit(
                used: Int(fiveHourUtilization),
                remaining: Int(100 - fiveHourUtilization),
                percentageUsed: fiveHourUtilization,
                resets: response.five_hour?.resets_at.flatMap { parseISODate($0) }
            ),
            sevenDay: ClaudeLimit(
                used: Int(sevenDayUtilization),
                remaining: Int(100 - sevenDayUtilization),
                percentageUsed: sevenDayUtilization,
                resets: response.seven_day?.resets_at.flatMap { parseISODate($0) }
            ),
            lastUpdated: Date()
        )
    }
}
```

### 3. 错误类型

```swift
enum APIError: LocalizedError {
    // ... 其他错误
    case rateLimited

    var errorDescription: String? {
        // ...
        case .rateLimited:
            return "请求过于频繁，请稍后重试"
    }
}
```

## 遇到的问题

### Rate Limit (429)
这是主要问题。该 API 是给 Claude Code 客户端内部使用的，有严格的频次限制。

```
HTTP 429
{"error":{"message":"Rate limited. Please try again later.","type":"rate_limit_error"}}
```

**尝试的解决方案**：
- 自动刷新间隔从 5 分钟改为 10 分钟
- 添加手动刷新冷却时间 (5 秒)
- 打开页面不自动刷新

但问题仍然存在，API 限速策略不透明，无法保证稳定使用。

## 结论

Claude OAuth Usage API 存在以下限制：
1. 非公开 API，可能有变更风险
2. 严格的 Rate Limit，无法稳定调用
3. 限速策略不透明

建议等待 Anthropic 提供官方的用量查询 API，或使用其他方案（如解析 Claude 网页端）。

## 相关文件

如需恢复此功能，参考以下文件：
- `Sources/Models/ClaudeUsage.swift`
- `Sources/Services/ClaudeAPIService.swift`
- `Sources/ViewModels/UsageViewModel.swift` 中的 Claude 相关代码
- `Sources/ContentView.swift` 中的 ClaudeContentView
