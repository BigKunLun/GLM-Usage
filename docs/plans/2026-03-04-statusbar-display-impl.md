# 状态栏显示优化实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将状态栏从显示图标改为直接显示周用量百分比，并添加定时刷新机制。

**Architecture:** 将 ViewModel 从 ContentView 提升到 App 层，通过 EnvironmentObject 共享。添加 statusText 计算属性和 Timer 定时刷新。

**Tech Stack:** SwiftUI, MenuBarExtra, Timer, EnvironmentObject

---

### Task 1: 修改 UsageViewModel 添加状态栏文本和定时刷新

**Files:**
- Modify: `Sources/ViewModels/UsageViewModel.swift`

**Step 1: 添加 statusText 计算属性**

在 `UsageViewModel.swift` 中添加计算属性：

```swift
// MARK: - 状态栏文本

var statusText: String {
    if isLoading {
        return "GLM ⏳"
    }
    if !hasAPIKey() {
        return "GLM ⚙️"
    }
    if errorMessage != nil {
        return "GLM ❌"
    }
    let percentage = Int(usage.tokenWeekly.usagePercentage.rounded())
    return "GLM \(percentage)%"
}
```

**Step 2: 添加定时刷新功能**

在 `UsageViewModel.swift` 中添加定时器相关代码：

```swift
import Combine

@MainActor
class UsageViewModel: ObservableObject {
    // ... 现有属性 ...
    private var timer: Timer?

    // MARK: - 定时刷新

    func startAutoRefresh() {
        stopAutoRefresh()
        timer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }

    func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        timer?.invalidate()
    }
}
```

**Step 3: 验证编译**

Run: `swift build`
Expected: Build complete!

---

### Task 2: 修改 GLM_UsageApp 提升 ViewModel 并动态显示状态栏

**Files:**
- Modify: `Sources/GLM_UsageApp.swift`

**Step 1: 重写 GLM_UsageApp.swift**

```swift
//
//  GLM_UsageApp.swift
//  GLM Usage
//
//  Created on 2026-03-03.
//

import SwiftUI

@main
struct GLM_UsageApp: App {
    @StateObject private var viewModel = UsageViewModel()

    var body: some Scene {
        MenuBarExtra(viewModel.statusText) {
            ContentView()
                .environmentObject(viewModel)
        }
        .menuBarExtraStyle(.window)
        .onAppear {
            viewModel.startAutoRefresh()
        }
    }
}
```

**Step 2: 验证编译**

Run: `swift build`
Expected: Build complete!

---

### Task 3: 修改 ContentView 使用 EnvironmentObject

**Files:**
- Modify: `Sources/ContentView.swift`

**Step 1: 将 @StateObject 改为 @EnvironmentObject**

将第 11 行：
```swift
@StateObject private var viewModel = UsageViewModel()
```

改为：
```swift
@EnvironmentObject var viewModel: UsageViewModel
```

**Step 2: 验证编译**

Run: `swift build`
Expected: Build complete!

---

### Task 4: 运行验证

**Step 1: 编译并运行**

Run: `swift build && .build/debug/GLM_Usage`

Expected:
- 状态栏显示 "GLM ⚙️"（未配置 API Key）
- 配置 API Key 后显示 "GLM xx%"
- 每 5 分钟自动刷新

**Step 2: 提交代码**

```bash
git add -A
git commit -m "feat: 状态栏直接显示周用量百分比，添加5分钟定时刷新"
```
