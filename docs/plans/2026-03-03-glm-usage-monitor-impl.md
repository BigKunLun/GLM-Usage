# GLM Usage Monitor 实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 创建一个macOS菜单栏应用，显示GLM Coding Plan的三种额度使用情况

**Architecture:** SwiftUI原生应用，使用MenuBarExtra实现菜单栏图标和下拉面板。通过读取Dia浏览器的Cookie来获取认证信息，然后调用GLM API获取用量数据。

**Tech Stack:** Swift, SwiftUI, macOS 13.0+, SQLite3, URLSession

---

## Task 1: 创建Xcode项目

**Files:**
- Create: `GLM_Usage.xcodeproj` (Xcode项目文件)
- Create: `GLM_Usage/GLM_UsageApp.swift` (应用入口)
- Create: `GLM_Usage/Info.plist` (应用配置)

**Step 1: 使用Xcode创建项目**

在终端运行：
```bash
cd /Users/shijianing/CodingTime/GLM_Usage
mkdir -p GLM_Usage
```

**Step 2: 创建应用入口文件**

创建文件 `GLM_Usage/GLM_UsageApp.swift`:

```swift
import SwiftUI

@main
struct GLM_UsageApp: App {
    var body: some Scene {
        MenuBarExtra("GLM", systemImage: "chart.bar") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
```

**Step 3: 创建ContentView占位**

创建文件 `GLM_Usage/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("GLM Usage Monitor")
                .font(.headline)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 280, height: 200)
    }
}

#Preview {
    ContentView()
}
```

**Step 4: 验证项目结构**

```bash
ls -la GLM_Usage/
```
Expected: 看到两个swift文件

---

## Task 2: 实现数据模型

**Files:**
- Create: `GLM_Usage/Models/GLMUsage.swift`

**Step 1: 创建Models目录和模型文件**

```bash
mkdir -p GLM_Usage/Models
```

创建文件 `GLM_Usage/Models/GLMUsage.swift`:

```swift
import Foundation

// 单个额度信息
struct Quota: Codable, Identifiable {
    var id: String { name }
    let name: String          // 额度名称
    let used: Int             // 已使用
    let total: Int            // 总额度
    let resetTime: Date?      // 重置时间（可选）

    var remaining: Int {
        max(0, total - used)
    }

    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total) * 100
    }

    var remainingPercentage: Double {
        return 100 - percentage
    }

    // 颜色状态
    var statusColor: QuotaStatus {
        if remainingPercentage > 70 {
            return .good
        } else if remainingPercentage > 30 {
            return .warning
        } else {
            return .critical
        }
    }
}

enum QuotaStatus {
    case good      // 绿色 >70%
    case warning   // 黄色 30-70%
    case critical  // 红色 <30%
}

// GLM用量数据
struct GLMUsage: Codable {
    let hourly5: Quota      // 每5小时额度
    let weekly: Quota       // 每周额度
    let mcpMonthly: Quota   // MCP每月额度
    let lastUpdated: Date   // 更新时间

    // 创建示例数据用于预览
    static var preview: GLMUsage {
        GLMUsage(
            hourly5: Quota(name: "每5小时额度", used: 40, total: 50, resetTime: Date().addingTimeInterval(5 * 3600)),
            weekly: Quota(name: "每周额度", used: 300, total: 500, resetTime: Date().addingTimeInterval(7 * 24 * 3600)),
            mcpMonthly: Quota(name: "MCP每月额度", used: 900, total: 1000, resetTime: Date().addingTimeInterval(30 * 24 * 3600)),
            lastUpdated: Date()
        )
    }

    // 空数据状态
    static var empty: GLMUsage {
        GLMUsage(
            hourly5: Quota(name: "每5小时额度", used: 0, total: 0, resetTime: nil),
            weekly: Quota(name: "每周额度", used: 0, total: 0, resetTime: nil),
            mcpMonthly: Quota(name: "MCP每月额度", used: 0, total: 0, resetTime: nil),
            lastUpdated: Date()
        )
    }
}
```

**Step 2: 验证编译**

使用Xcode打开项目，确认模型文件编译通过。

---

## Task 3: 实现ViewModel

**Files:**
- Create: `GLM_Usage/ViewModels/UsageViewModel.swift`

**Step 1: 创建ViewModels目录**

```bash
mkdir -p GLM_Usage/ViewModels
```

**Step 2: 创建ViewModel文件**

创建文件 `GLM_Usage/ViewModels/UsageViewModel.swift`:

```swift
import Foundation
import SwiftUI

@MainActor
class UsageViewModel: ObservableObject {
    @Published var usage: GLMUsage = .empty
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = GLMAPIService()
    private let cookieReader = CookieReader()

    func refresh() async {
        isLoading = true
        errorMessage = nil

        do {
            // 1. 读取Cookie
            let cookies = try cookieReader.readCookies(for: "bigmodel.cn")

            // 2. 调用API
            let newUsage = try await apiService.fetchUsage(cookies: cookies)
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
}
```

---

## Task 4: 实现Cookie读取服务

**Files:**
- Create: `GLM_Usage/Services/CookieReader.swift`

**Step 1: 创建Services目录**

```bash
mkdir -p GLM_Usage/Services
```

**Step 2: 创建CookieReader**

创建文件 `GLM_Usage/Services/CookieReader.swift`:

```swift
import Foundation
import SQLite3

enum CookieError: LocalizedError {
    case databaseNotFound
    case databaseOpenFailed
    case queryFailed
    case decryptionFailed
    case noCookiesFound

    var errorDescription: String? {
        switch self {
        case .databaseNotFound:
            return "未找到Dia浏览器的Cookie数据库，请确保已安装Dia并登录GLM"
        case .databaseOpenFailed:
            return "无法打开Cookie数据库"
        case .queryFailed:
            return "查询Cookie失败"
        case .decryptionFailed:
            return "Cookie解密失败"
        case .noCookiesFound:
            return "未找到bigmodel.cn的登录信息，请先在浏览器中登录"
        }
    }
}

class CookieReader {

    // Dia浏览器的Cookie数据库路径
    private var cookieDatabasePath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Application Support/Dia/Cookies"
    }

    // 检查数据库是否存在
    func databaseExists() -> Bool {
        FileManager.default.fileExists(atPath: cookieDatabasePath)
    }

    // 读取指定域名的Cookie
    func readCookies(for domain: String) throws -> [HTTPCookie] {
        guard databaseExists() else {
            throw CookieError.databaseNotFound
        }

        var db: OpaquePointer?

        // 打开数据库
        guard sqlite3_open(cookieDatabasePath, &db) == SQLITE_OK else {
            throw CookieError.databaseOpenFailed
        }
        defer { sqlite3_close(db) }

        var cookies: [HTTPCookie] = []

        // 查询Cookie
        let query = """
            SELECT name, encrypted_value, path, expires_utc, is_secure, is_httponly
            FROM cookies
            WHERE host_key LIKE ?
            """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else {
            throw CookieError.queryFailed
        }
        defer { sqlite3_finalize(stmt) }

        let searchPattern = "%\(domain)%"
        sqlite3_bind_text(stmt, 1, (searchPattern as NSString).utf8String, -1, nil)

        while sqlite3_step(stmt) == SQLITE_ROW {
            if let name = sqlite3_column_text(stmt, 0),
               let encryptedValue = sqlite3_column_blob(stmt, 1),
               let path = sqlite3_column_text(stmt, 2) {

                let nameString = String(cString: name)
                let pathString = String(cString: path)
                let encryptedLength = sqlite3_column_bytes(stmt, 1)
                let encryptedData = Data(bytes: encryptedValue, count: Int(encryptedLength))

                // 尝试解密Cookie值
                do {
                    let decryptedValue = try decryptCookie(encryptedData)

                    let cookie = HTTPCookie(properties: [
                        .name: nameString,
                        .value: decryptedValue,
                        .domain: domain,
                        .path: pathString
                    ])

                    if let cookie = cookie {
                        cookies.append(cookie)
                    }
                } catch {
                    // 解密失败，跳过这个Cookie
                    continue
                }
            }
        }

        if cookies.isEmpty {
            throw CookieError.noCookiesFound
        }

        return cookies
    }

    // 解密Chrome加密的Cookie
    private func decryptCookie(_ encryptedData: Data) throws -> String {
        // Chrome在macOS上使用v10或v11前缀的加密
        // 前3字节是版本标识 (v10/v11)
        guard encryptedData.count > 3 else {
            if let str = String(data: encryptedData, encoding: .utf8) {
                return str // 未加密的Cookie
            }
            throw CookieError.decryptionFailed
        }

        let prefix = encryptedData.prefix(3)
        if prefix == Data("v10".utf8) || prefix == Data("v11".utf8) {
            // 加密的Cookie，需要通过Keychain解密
            return try decryptWithKeychain(encryptedData)
        } else {
            // 未加密的Cookie
            if let str = String(data: encryptedData, encoding: .utf8) {
                return str
            }
            throw CookieError.decryptionFailed
        }
    }

    // 使用Keychain解密 (需要访问系统Keychain)
    private func decryptWithKeychain(_ encryptedData: Data) throws -> String {
        // Chrome加密数据格式: v10/v11 (3 bytes) + nonce (12 bytes) + ciphertext + tag (16 bytes)
        let prefixLength = 3
        let nonceLength = 12

        guard encryptedData.count > prefixLength + nonceLength else {
            throw CookieError.decryptionFailed
        }

        // 提取nonce和ciphertext
        let nonce = encryptedData.dropFirst(prefixLength).prefix(nonceLength)
        var ciphertext = encryptedData.dropFirst(prefixLength + nonceLength)

        // 获取Chrome的加密密钥 (从Keychain)
        // 注意：这需要在实际运行时获取，这里简化处理
        // 实际实现需要调用Security框架

        // 由于这是一个复杂的过程，这里返回一个占位实现
        // 实际项目中需要完整实现Keychain访问和AES-GCM解密

        throw CookieError.decryptionFailed
    }
}
```

---

## Task 5: 实现API服务

**Files:**
- Create: `GLM_Usage/Services/GLMAPIService.swift`

**Step 1: 创建API服务**

创建文件 `GLM_Usage/Services/GLMAPIService.swift`:

```swift
import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case parsingError
    case unauthorized

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
            return "登录已过期，请在浏览器重新登录"
        }
    }
}

class GLMAPIService {

    // GLM用量API地址 (需要根据实际情况调整)
    private let usageAPIURL = "https://bigmodel.cn/api/paas/open/v3/codingplan/usage"

    func fetchUsage(cookies: [HTTPCookie]) async throws -> GLMUsage {
        guard let url = URL(string: usageAPIURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // 设置Cookie
        let cookieHeader = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
        request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw APIError.unauthorized
            }

            guard httpResponse.statusCode == 200 else {
                throw APIError.invalidResponse
            }

            // 解析响应数据
            return try parseUsageResponse(data)

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func parseUsageResponse(_ data: Data) throws -> GLMUsage {
        // 解析API响应
        // 注意：实际的JSON结构需要根据GLM API的实际响应来调整

        struct APIResponse: Codable {
            let success: Bool
            let data: UsageData?

            struct UsageData: Codable {
                let hourly5: QuotaData?
                let weekly: QuotaData?
                let mcpMonthly: QuotaData?

                struct QuotaData: Codable {
                    let used: Int
                    let total: Int
                    let resetTime: String?
                }
            }
        }

        guard let response = try? JSONDecoder().decode(APIResponse.self, from: data) else {
            throw APIError.parsingError
        }

        guard response.success, let usageData = response.data else {
            throw APIError.parsingError
        }

        // 转换为GLMUsage
        let hourly5 = Quota(
            name: "每5小时额度",
            used: usageData.hourly5?.used ?? 0,
            total: usageData.hourly5?.total ?? 0,
            resetTime: parseDate(usageData.hourly5?.resetTime)
        )

        let weekly = Quota(
            name: "每周额度",
            used: usageData.weekly?.used ?? 0,
            total: usageData.weekly?.total ?? 0,
            resetTime: parseDate(usageData.weekly?.resetTime)
        )

        let mcpMonthly = Quota(
            name: "MCP每月额度",
            used: usageData.mcpMonthly?.used ?? 0,
            total: usageData.mcpMonthly?.total ?? 0,
            resetTime: parseDate(usageData.mcpMonthly?.resetTime)
        )

        return GLMUsage(
            hourly5: hourly5,
            weekly: weekly,
            mcpMonthly: mcpMonthly,
            lastUpdated: Date()
        )
    }

    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}
```

---

## Task 6: 实现UI组件 - 额度行视图

**Files:**
- Create: `GLM_Usage/Views/QuotaRowView.swift`

**Step 1: 创建Views目录**

```bash
mkdir -p GLM_Usage/Views
```

**Step 2: 创建QuotaRowView**

创建文件 `GLM_Usage/Views/QuotaRowView.swift`:

```swift
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
                Text("\(Int(quota.remainingPercentage))%")
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

                    // 进度条
                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: geometry.size.width * min(1, quota.remainingPercentage / 100), height: 8)
                }
            }
            .frame(height: 8)

            // 使用量详情
            HStack {
                Text("\(quota.used) / \(quota.total) 次")
                    .font(.caption)
                    .foregroundColor(.secondary)

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

    private func formatResetTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VStack(spacing: 16) {
        QuotaRowView(quota: Quota(name: "每5小时额度", used: 40, total: 50, resetTime: Date().addingTimeInterval(3600)))
        QuotaRowView(quota: Quota(name: "每周额度", used: 450, total: 500, resetTime: Date().addingTimeInterval(86400)))
        QuotaRowView(quota: Quota(name: "MCP每月额度", used: 980, total: 1000, resetTime: Date().addingTimeInterval(86400 * 7)))
    }
    .padding()
    .frame(width: 280)
}
```

---

## Task 7: 实现主视图

**Files:**
- Modify: `GLM_Usage/ContentView.swift`

**Step 1: 更新ContentView**

修改文件 `GLM_Usage/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = UsageViewModel()

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
            }

            Divider()

            // 错误提示
            if let error = viewModel.errorMessage {
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
                // 额度列表
                VStack(spacing: 12) {
                    QuotaRowView(quota: viewModel.usage.hourly5)
                    QuotaRowView(quota: viewModel.usage.weekly)
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
                .disabled(viewModel.isLoading)

                Spacer()

                Text("上次更新: \(viewModel.formatLastUpdated())")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 300)
        .task {
            // 首次加载
            await viewModel.refresh()
        }
    }
}

#Preview {
    ContentView()
}
```

---

## Task 8: 更新应用入口

**Files:**
- Modify: `GLM_Usage/GLM_UsageApp.swift`

**Step 1: 更新应用入口**

修改文件 `GLM_Usage/GLM_UsageApp.swift`:

```swift
import SwiftUI

@main
struct GLM_UsageApp: App {
    var body: some Scene {
        MenuBarExtra("GLM", systemImage: "chart.bar.fill") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
```

---

## Task 9: 添加权限配置

**Files:**
- Create: `GLM_Usage/Info.plist`

**Step 1: 创建Info.plist**

创建文件 `GLM_Usage/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIconFile</key>
    <string></string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024. All rights reserved.</string>
    <key>NSMainStoryboardFile</key>
    <string></string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSNetworkClientUsageDescription</key>
    <string>GLM Usage需要网络访问来获取用量数据</string>
</dict>
</plist>
```

**注意:** `LSUIElement` 设置为 true 使应用只显示在菜单栏，不在Dock中显示。

---

## Task 10: 创建Xcode项目文件

**Files:**
- Create: `GLM_Usage.xcodeproj/project.pbxproj`

**Step 1: 使用Xcode创建项目**

由于Xcode项目文件较为复杂，建议：

1. 打开Xcode
2. 选择 File > New > Project
3. 选择 macOS > App
4. 产品名称: GLM_Usage
5. 接口: SwiftUI
6. 语言: Swift
7. 保存到: `/Users/shijianing/CodingTime/GLM_Usage`

然后将之前创建的文件添加到项目中。

**Step 2: 替换自动生成的文件**

Xcode会自动生成一些文件，用我们之前创建的文件内容替换它们。

---

## Task 11: 测试和调试

**Step 1: 在Xcode中编译项目**

- 打开 `GLM_Usage.xcodeproj`
- 按 `Cmd+B` 编译
- 修复任何编译错误

**Step 2: 运行应用**

- 按 `Cmd+R` 运行
- 检查菜单栏是否出现图标
- 点击图标查看面板

**Step 3: 调试Cookie读取**

由于Cookie解密是一个复杂的过程，可能需要调试：
- 检查Cookie数据库路径是否正确
- 检查Keychain访问权限
- 验证解密逻辑

**Step 4: 调试API调用**

- 使用代理工具(Charles/Proxyman)查看实际API请求
- 根据实际响应调整JSON解析逻辑

---

## Task 12: 改进Cookie解密实现

**Files:**
- Modify: `GLM_Usage/Services/CookieReader.swift`

**背景:** Chrome系浏览器在macOS上使用Keychain存储加密密钥，需要正确的解密实现。

**Step 1: 添加Security框架支持**

在CookieReader.swift顶部添加:
```swift
import Security
import CommonCrypto
```

**Step 2: 实现完整的解密逻辑**

需要实现:
1. 从Keychain获取Chrome的加密密钥
2. 使用AES-GCM解密Cookie值

这部分需要参考Chrome的加密实现，可能需要额外的研究。

---

## 后续优化任务

1. **图标设计** - 设计更精美的菜单栏图标
2. **通知功能** - 额度即将用尽时发送通知
3. **多浏览器支持** - 支持Safari、Chrome等其他浏览器
4. **数据缓存** - 缓存数据，避免频繁请求
5. **自动刷新** - 添加定时自动刷新选项
