import AppKit
import Foundation

final class ClipboardMonitor {
    private let pasteboard: NSPasteboard
    private let historyStore: ClipboardHistoryStore
    private let settingsStore: AppSettingsStore
    private var timer: DispatchSourceTimer?
    private var lastChangeCount: Int

    init(pasteboard: NSPasteboard = .general, historyStore: ClipboardHistoryStore, settingsStore: AppSettingsStore) {
        self.pasteboard = pasteboard
        self.historyStore = historyStore
        self.settingsStore = settingsStore
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else {
            return
        }

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 0.9, repeating: 0.9)
        timer.setEventHandler { [weak self] in
            self?.checkPasteboard()
        }
        timer.resume()
        self.timer = timer
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func copyToPasteboard(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        lastChangeCount = pasteboard.changeCount
    }

    func copyToPasteboard(_ image: NSImage) {
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        lastChangeCount = pasteboard.changeCount
    }

    private func checkPasteboard() {
        let currentChangeCount = pasteboard.changeCount

        guard currentChangeCount != lastChangeCount else {
            return
        }

        lastChangeCount = currentChangeCount

        guard !settingsStore.isRecordingPaused else {
            return
        }

        if let text = pasteboard.string(forType: .string) {
            historyStore.addText(text, retentionDays: settingsStore.retentionDays)
            return
        }

        if
            let objects = pasteboard.readObjects(forClasses: [NSImage.self], options: nil),
            let image = objects.first as? NSImage
        {
            historyStore.addImage(image, retentionDays: settingsStore.retentionDays)
        }
    }
}
