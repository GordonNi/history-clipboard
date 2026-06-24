# 打包与运行说明

## 打包命令

在项目根目录运行：

```bash
scripts/package-app.sh
```

脚本会执行 release 构建，并生成：

```text
dist/HistoryClipboard.app
```

## 应用图标

应用图标资产位于：

```text
Assets/AppIcon/app-cover-liquid-glass.png
Assets/AppIcon/HistoryClipboard.icns
```

打包脚本会把 `Assets/AppIcon/HistoryClipboard.icns` 复制到：

```text
dist/HistoryClipboard.app/Contents/Resources/HistoryClipboard.icns
```

并在 `Info.plist` 中写入 `CFBundleIconFile`。

## 运行方式

可以在 Finder 中双击：

```text
dist/HistoryClipboard.app
```

也可以在终端运行：

```bash
open dist/HistoryClipboard.app
```

启动后，应用不会出现在 Dock 中，而是显示在 macOS 顶部菜单栏。

## 本机安装

先生成 App 包：

```bash
scripts/package-app.sh
```

再安装到当前用户的应用目录：

```bash
scripts/install-local.sh
```

默认安装位置：

```text
~/Applications/HistoryClipboard.app
```

安装后可以在 Finder 的用户应用目录中双击打开，也可以运行：

```bash
open ~/Applications/HistoryClipboard.app
```

如果需要测试安装到其他目录，可临时指定 `INSTALL_DIR`：

```bash
INSTALL_DIR=/tmp/HistoryClipboardInstallTest scripts/install-local.sh
```

## 数据位置

历史数据库：

```text
~/Library/Application Support/HistoryClipboard/HistoryClipboard.sqlite
```

图片文件：

```text
~/Library/Application Support/HistoryClipboard/Images/
```

## 注意事项

- 当前 App 包是本地开发打包版本，未做签名、公证或安装器。
- 第一次打开时，macOS 可能出现安全提示。
- 开机启动使用 `ServiceManagement` 接入，需要在正式 `.app` 包中手动确认。
- 如果修改源码，需要重新运行 `scripts/package-app.sh` 生成新的 App 包。
