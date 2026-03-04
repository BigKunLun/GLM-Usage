# GLM Usage - Claude Code 项目说明

## 项目概述

macOS 菜单栏应用，用于监控智谱 GLM Coding Plan 的用量信息。

## 技术栈

- **语言**: Swift 5.9+
- **框架**: SwiftUI
- **最低系统**: macOS 13.0+
- **构建工具**: Swift Package Manager

## 项目结构

```
Sources/
├── GLM_UsageApp.swift      # 应用入口，MenuBarExtra 配置
├── ContentView.swift       # 主视图，包含设置页面
├── Models/
│   └── GLMUsage.swift      # 数据模型（Quota, GLMUsage）
├── ViewModels/
│   └── UsageViewModel.swift # ViewModel，API 调用，状态管理
├── Services/
│   └── GLMAPIService.swift  # API 服务，调用智谱接口
└── Views/
    └── QuotaRowView.swift   # 额度行组件
```

## 开发命令

```bash
# 构建
swift build

# 运行（命令行模式，用于调试）
swift run

# 发布版本构建
swift build -c release

# 打包为 .app
./build.sh
```

## API 说明

调用智谱开放平台的用量查询接口：
- 端点: `https://open.bigmodel.cn/api/ping/v4/users/me`
- 认证: Bearer Token (API Key)
- 返回: 5小时额度、周额度、月额度数据

## 配置

- API Key 存储: `UserDefaults(suiteName: "com.glm.usage")`
- 自动刷新间隔: 5 分钟

## 发布流程

1. 更新版本号（如需要）
2. 运行 `./build.sh` 打包
3. 提交代码到 GitHub
4. 创建 GitHub Release，上传 `GLM_Usage.zip`

## 版本历史

- **v1.1.0** - UI 紧凑实用型优化，修复布局抖动问题
- **v1.0.0** - 首个正式版本
