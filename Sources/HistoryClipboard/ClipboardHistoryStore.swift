import Combine
import AppKit
import Foundation

final class ClipboardHistoryStore: ObservableObject {
    @Published private(set) var items: [ClipboardHistoryItem] = []
    private let persistence: ClipboardHistoryPersistence?
    private let imageStore: ClipboardImageStore

    init(persistence: ClipboardHistoryPersistence? = ClipboardHistoryPersistence(), imageStore: ClipboardImageStore = ClipboardImageStore()) {
        self.persistence = persistence
        self.imageStore = imageStore
        loadPersistedItems()
    }

    func addText(_ text: String, retentionDays: Int? = nil) {
        guard !text.isEmpty else {
            return
        }

        if items.first?.textContent == text {
            return
        }

        let item = ClipboardHistoryItem(textContent: text)
        items.insert(item, at: 0)
        sortItems()

        do {
            try persistence?.insert(item)
        } catch {
            assertionFailure("Failed to persist clipboard text item: \(error)")
        }

        if let retentionDays {
            cleanupExpired(retentionDays: retentionDays)
        }
    }

    func addImage(_ image: NSImage, retentionDays: Int? = nil) {
        let id = UUID()

        do {
            let imagePath = try imageStore.save(image, id: id)
            let item = ClipboardHistoryItem(
                id: id,
                type: .image,
                textContent: "",
                imagePath: imagePath
            )
            items.insert(item, at: 0)
            sortItems()
            try persistence?.insert(item)

            if let retentionDays {
                cleanupExpired(retentionDays: retentionDays)
            }
        } catch {
            assertionFailure("Failed to save clipboard image item: \(error)")
        }
    }

    func image(for item: ClipboardHistoryItem) -> NSImage? {
        guard item.type == .image, let imagePath = item.imagePath else {
            return nil
        }

        return imageStore.load(path: imagePath)
    }

    func delete(_ item: ClipboardHistoryItem) {
        items.removeAll { $0.id == item.id }
        imageStore.delete(path: item.imagePath)

        do {
            try persistence?.delete(item)
        } catch {
            assertionFailure("Failed to delete clipboard text item: \(error)")
        }
    }

    func clearAll() {
        let imagePaths = items.compactMap(\.imagePath)
        items.removeAll()
        imagePaths.forEach { imageStore.delete(path: $0) }

        do {
            let persistedImagePaths = try persistence?.deleteAllItems() ?? []
            persistedImagePaths.forEach { imageStore.delete(path: $0) }
        } catch {
            assertionFailure("Failed to clear clipboard history: \(error)")
        }
    }

    func togglePin(_ item: ClipboardHistoryItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        let updatedItem = item.withPinned(!item.isPinned)
        items[index] = updatedItem
        sortItems()

        do {
            try persistence?.updatePin(updatedItem)
        } catch {
            assertionFailure("Failed to update clipboard item pin state: \(error)")
        }
    }

    func cleanupExpired(retentionDays: Int, now: Date = Date()) {
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: now) else {
            return
        }

        let expiredImagePaths = items.compactMap { item in
            !item.isPinned && item.createdAt < cutoffDate ? item.imagePath : nil
        }
        items.removeAll { item in
            !item.isPinned && item.createdAt < cutoffDate
        }
        expiredImagePaths.forEach { imageStore.delete(path: $0) }

        do {
            let persistedImagePaths = try persistence?.deleteExpiredUnpinnedItems(olderThan: cutoffDate) ?? []
            persistedImagePaths.forEach { imageStore.delete(path: $0) }
        } catch {
            assertionFailure("Failed to delete expired clipboard items: \(error)")
        }
    }

    private func loadPersistedItems() {
        do {
            items = try persistence?.fetchItems() ?? []
            sortItems()
        } catch {
            assertionFailure("Failed to load clipboard history: \(error)")
            items = []
        }
    }

    private func sortItems() {
        items.sort {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }

            return $0.createdAt > $1.createdAt
        }
    }
}

extension ClipboardHistoryStore {
    static var preview: ClipboardHistoryStore {
        let store = ClipboardHistoryStore(persistence: nil)
        store.addText("这是一条临时文字历史。下一阶段会把它保存到本地数据库。")
        store.addText("复制新的文字后，会显示在列表顶部。")
        return store
    }
}
