# 技术架构规范

## 技术选型

- 语言：Swift
- UI：SwiftUI
- macOS 集成：AppKit
- 工程形态：Swift Package，可通过 Xcode 打开 `Package.swift` 开发
- 菜单栏入口：NSStatusItem
- 弹出面板：NSPopover
- 剪贴板访问：NSPasteboard
- 本地数据：Core Data
- Core Data 模型：Swift 代码内创建最小模型，避免 Swift Package 依赖 `.xcdatamodeld` 资源文件
- Core Data 文件：`~/Library/Application Support/HistoryClipboard/HistoryClipboard.sqlite`
- Core Data 迁移：启用自动轻量迁移，用于新增字段等兼容性变更
- 设置存储：使用 `UserDefaults` 保存轻量应用设置
- 图片文件：保存到 `~/Library/Application Support/HistoryClipboard/Images/`
- 开机启动：ServiceManagement，需在正式 macOS App bundle 中最终验证

## 最低环境

- macOS 13 或更高版本。
- Xcode 14.3.1 或兼容版本。
- Swift 5.8 或兼容版本。

## 模块划分

- App 启动层：负责应用生命周期、菜单栏图标、弹出面板。
- Clipboard 监听层：负责检测系统剪贴板变化并识别文字或图片。
- History 数据层：负责新增、查询、删除、置顶、清理过期历史。
- Settings 设置层：负责保存保存期限、暂停记录、开机启动等设置。
- UI 展示层：负责历史列表、搜索、设置、空状态和操作按钮。

## 数据模型

### ClipboardItem

- `id`: 唯一标识。
- `type`: 内容类型，支持 `text` 和 `image`。
- `createdAt`: 首次记录时间。
- `updatedAt`: 最近更新时间。
- `isPinned`: 是否置顶。
- `textContent`: 文字内容，仅文字类型使用。
- `imagePath`: 图片文件路径，仅图片类型使用。
- `previewText`: 搜索和列表摘要使用的预览文本。

### AppSettings

- `retentionDays`: 保存天数，只允许 1、3、5。
- `isRecordingPaused`: 是否暂停记录。
- `launchAtLogin`: 是否开机启动。

## 剪贴板监听规则

- 通过 `NSPasteboard.general.changeCount` 检测变化。
- 定时轮询剪贴板，第一版可使用 0.8 到 1.0 秒间隔。
- 如果暂停记录开启，只更新剪贴板变更计数，不新增历史。
- 如果剪贴板内容与最近一条历史完全相同，不重复新增。
- 文字优先读取纯文本。
- 剪贴板没有纯文本时，尝试读取图片对象并保存为本地 PNG 文件。

## 数据清理规则

- 保存期限只作用于未置顶内容。
- 置顶内容不自动删除。
- 清理可在应用启动、保存期限变更、记录新增后触发。
- 第一版默认保存期限为 3 天。
- 删除图片历史时，同时删除对应本地图片文件。
- 过期清理图片历史时，同时删除对应本地图片文件。
- 清空全部历史时，删除全部 Core Data 历史记录和全部关联图片文件。

## 权限与隐私

- 第一版不申请辅助功能权限。
- 第一版不进行网络请求。
- 所有历史数据只保存在本机。
- 不记录来源 App、窗口标题、网页地址等上下文信息。

## 开发原则

- 每个阶段结束时保持项目可编译。
- 优先使用系统原生能力，减少第三方依赖。
- 先做稳定可用，再做体验增强。
- 任何架构变化都要同步更新本文档。
