import Foundation

enum ClipboardItemType: String {
    case text
    case image
}

struct ClipboardHistoryItem: Identifiable, Equatable {
    let id: UUID
    let type: ClipboardItemType
    let createdAt: Date
    let isPinned: Bool
    let textContent: String
    let imagePath: String?

    init(
        id: UUID = UUID(),
        type: ClipboardItemType = .text,
        createdAt: Date = Date(),
        isPinned: Bool = false,
        textContent: String,
        imagePath: String? = nil
    ) {
        self.id = id
        self.type = type
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.textContent = textContent
        self.imagePath = imagePath
    }

    func withPinned(_ isPinned: Bool) -> ClipboardHistoryItem {
        ClipboardHistoryItem(
            id: id,
            type: type,
            createdAt: createdAt,
            isPinned: isPinned,
            textContent: textContent,
            imagePath: imagePath
        )
    }
}
