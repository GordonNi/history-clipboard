import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private let settingsStore = AppSettingsStore()
    private let historyStore = ClipboardHistoryStore()
    private var clipboardMonitor: ClipboardMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        historyStore.cleanupExpired(retentionDays: settingsStore.retentionDays)
        configurePopover()
        configureStatusItem()
        configureClipboardMonitor()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor?.stop()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 390, height: 560)
        popover.contentViewController = NSHostingController(
            rootView: ContentView(
                store: historyStore,
                settingsStore: settingsStore,
                onCopyItem: { [weak self] item in
                    guard let self else {
                        return
                    }

                    switch item.type {
                    case .text:
                        clipboardMonitor?.copyToPasteboard(item.textContent)
                    case .image:
                        if let image = historyStore.image(for: item) {
                            clipboardMonitor?.copyToPasteboard(image)
                        }
                    }
                }
            )
        )
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "doc.on.clipboard",
                accessibilityDescription: "历史粘贴板"
            )
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        statusItem = item
    }

    private func configureClipboardMonitor() {
        let monitor = ClipboardMonitor(historyStore: historyStore, settingsStore: settingsStore)
        monitor.start()
        clipboardMonitor = monitor
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }
}
