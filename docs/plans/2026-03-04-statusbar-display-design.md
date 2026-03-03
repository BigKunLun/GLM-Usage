# 状态栏显示优化设计

## 目标
将状态栏从显示图标改为直接显示周用量百分比，并添加定时刷新机制。

## 状态栏显示格式
- 有数据：`GLM 23%`
- 加载中：`GLM ⏳`
- 无 API Key：`GLM ⚙️`
- 错误：`GLM ❌`

## 刷新逻辑
- 定时刷新：每 5 分钟
- 打开时刷新：点击打开菜单时刷新（保持现有逻辑）

## 实现方案
1. ViewModel 提升到 App 层，通过 EnvironmentObject 共享给 ContentView
2. 添加 `statusText` 计算属性
3. 使用 Timer 实现定时刷新
