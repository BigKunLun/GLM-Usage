# GLM Usage Monitor

一个macOS菜单栏应用，用于监控GLM Coding Plan的用量信息。

## 系统要求

- macOS 13.0+
- Xcode 15.0+

## 项目结构

```
GLM_Usage/
├── GLM_UsageApp.swift      // 应用入口
├── ContentView.swift        // 主视图
├── Models/                  // 数据模型
├── ViewModels/              // ViewModel层
├── Services/                // 服务层（API调用等）
└── Views/                   // UI视图组件
```

## 如何创建Xcode项目

### 方法一：使用Xcode创建新项目（推荐）

1. **打开Xcode**，选择 `File` → `New` → `Project`

2. **选择模板**：
   - 选择 `macOS` 标签
   - 选择 `App` 模板
   - 点击 `Next`

3. **配置项目**：
   - Product Name: `GLM Usage`
   - Team: 选择你的开发团队
   - Organization Identifier: 你的标识符（如 `com.yourname`）
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Storage: `None`（这个应用不需要Core Data）
   - 点击 `Next`

4. **选择位置**：
   - 选择 `/Users/shijianing/CodingTime/` 目录
   - 取消勾选 `Create Git repository`（如果已有git仓库）
   - 点击 `Create`

5. **替换默认文件**：
   - 删除Xcode自动创建的 `GLM_UsageApp.swift` 和 `ContentView.swift`
   - 将本目录下的源文件拖入Xcode项目中
   - 确保勾选 `Copy items if needed`

6. **添加文件夹**：
   - 在Xcode左侧项目导航器中，右键点击项目根目录
   - 选择 `New Group`，创建 `Models`、`ViewModels`、`Services`、`Views` 文件夹

### 方法二：使用Swift Package（适用于开发测试）

如果只是想快速测试代码，可以直接用Swift Package：

```bash
cd /Users/shijianing/CodingTime/GLM_Usage
swift package init --type executable
```

然后编辑 `Package.swift` 添加依赖。

## 配置MenuBarExtra

本项目使用 `MenuBarExtra`（macOS 13+新特性）创建菜单栏应用。

### 修改GLM_UsageApp.swift

将应用转换为菜单栏应用需要：

1. 在 `Info.plist` 中设置 `LSUIElement` 为 `true`（隐藏Dock图标）
2. 使用 `MenuBarExtra` 替代 `WindowGroup`

示例代码：

```swift
@main
struct GLM_UsageApp: App {
    var body: some Scene {
        MenuBarExtra("GLM Usage", systemImage: "chart.bar") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
```

## 开发计划

- [x] 项目结构创建
- [ ] 数据模型实现
- [ ] API服务实现
- [ ] ViewModel实现
- [ ] UI视图实现
- [ ] 菜单栏集成
- [ ] 后台定时刷新

## 注意事项

1. **Bundle Identifier**: 确保在Xcode中设置正确的Bundle Identifier
2. **Signing**: 需要配置正确的签名证书才能运行
3. **Permissions**: 如果需要网络访问，确保在沙盒设置中允许网络出站连接
