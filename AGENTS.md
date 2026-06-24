# AGENTS.md

## 项目目标

本项目是一个 macOS 菜单栏历史粘贴板应用，目标是记录近期复制的文字和图片，并提供搜索、置顶、删除、保存期限和再次复制能力。

## 必读文件

每次开发前必须先阅读：

- `docs/requirements.md`
- `docs/technical-architecture.md`
- `docs/design-guidelines.md`
- `docs/development-plan.md`
- `docs/quality-standards.md`
- `docs/manual-acceptance.md`
- `docs/packaging.md`

## 开发日志规则

- 每天使用 `dev-logs/YYYY-MM-DD.md` 记录开发进展。
- 每次开发结束必须更新当天日志。
- 日志必须包含：
  - 已完成
  - 待办
  - 问题
  - 下一步
  - 验证记录

## 工作方式

- 每次只推进一个小阶段。
- 阶段目标以 `docs/development-plan.md` 为准。
- 完成阶段后必须进行构建或手动验证。
- 新想法先记录到待办，不直接扩大当前阶段范围。
- 如果需求、技术、设计、质量标准发生变化，必须同步更新对应文档。

## 开发约束

- 不跳过构建检查，除非日志明确记录原因。
- 不擅自增加计划外功能。
- 第一版所有数据只保存在本机。
- 第一版不做网络同步、不做遥测、不做云端上传。
- UI 保持简洁、直观，并以淡蓝色作为主要强调色。
- 优先使用 macOS 原生能力和 Swift/SwiftUI/AppKit。

## 当前阶段

当前已完成阶段 11：UI 打磨与稳定性检查。

当前第一版功能开发阶段、手动验收和阶段 12 本地安装准备已完成。

正在推进阶段 13：GitHub 开源发布准备。发布时必须排除本机构建缓存、未签名安装包、用户数据和任何敏感信息。
