import AppKit
import Foundation

final class ClipboardImageStore {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func save(_ image: NSImage, id: UUID) throws -> String {
        let url = try imageURL(for: id)
        let imageData = try pngData(from: image)
        try imageData.write(to: url, options: .atomic)
        return url.path
    }

    func load(path: String) -> NSImage? {
        NSImage(contentsOfFile: path)
    }

    func delete(path: String?) {
        guard let path, !path.isEmpty else {
            return
        }

        try? fileManager.removeItem(atPath: path)
    }

    private func imageURL(for id: UUID) throws -> URL {
        let directory = try imagesDirectory()
        return directory.appendingPathComponent("\(id.uuidString).png")
    }

    private func imagesDirectory() throws -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        let directory = appSupport
            .appendingPathComponent("HistoryClipboard", isDirectory: true)
            .appendingPathComponent("Images", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func pngData(from image: NSImage) throws -> Data {
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            throw ClipboardImageStoreError.cannotEncodePNG
        }

        return pngData
    }
}

enum ClipboardImageStoreError: Error {
    case cannotEncodePNG
}
