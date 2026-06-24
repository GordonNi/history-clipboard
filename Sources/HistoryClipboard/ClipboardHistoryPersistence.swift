import CoreData
import Foundation

final class ClipboardHistoryPersistence {
    private enum Entity {
        static let name = "ClipboardHistoryRecord"
        static let id = "id"
        static let type = "type"
        static let createdAt = "createdAt"
        static let isPinned = "isPinned"
        static let textContent = "textContent"
        static let imagePath = "imagePath"
    }

    private let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(
            name: "HistoryClipboardModel",
            managedObjectModel: Self.makeManagedObjectModel()
        )

        let description: NSPersistentStoreDescription

        if inMemory {
            description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
        } else {
            description = NSPersistentStoreDescription(url: Self.storeURL())
            description.type = NSSQLiteStoreType
        }

        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("Failed to load clipboard history store: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func fetchItems() throws -> [ClipboardHistoryItem] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.name)
        request.sortDescriptors = [
            NSSortDescriptor(key: Entity.isPinned, ascending: false),
            NSSortDescriptor(key: Entity.createdAt, ascending: false)
        ]

        return try container.viewContext.fetch(request).compactMap { object in
            guard
                let id = object.value(forKey: Entity.id) as? UUID,
                let createdAt = object.value(forKey: Entity.createdAt) as? Date,
                let textContent = object.value(forKey: Entity.textContent) as? String
            else {
                return nil
            }

            let typeRawValue = object.value(forKey: Entity.type) as? String ?? ClipboardItemType.text.rawValue
            let type = ClipboardItemType(rawValue: typeRawValue) ?? .text
            let isPinned = object.value(forKey: Entity.isPinned) as? Bool ?? false
            let imagePath = object.value(forKey: Entity.imagePath) as? String
            return ClipboardHistoryItem(
                id: id,
                type: type,
                createdAt: createdAt,
                isPinned: isPinned,
                textContent: textContent,
                imagePath: imagePath
            )
        }
    }

    func insert(_ item: ClipboardHistoryItem) throws {
        let context = container.viewContext
        let object = NSEntityDescription.insertNewObject(forEntityName: Entity.name, into: context)
        object.setValue(item.id, forKey: Entity.id)
        object.setValue(item.type.rawValue, forKey: Entity.type)
        object.setValue(item.createdAt, forKey: Entity.createdAt)
        object.setValue(item.isPinned, forKey: Entity.isPinned)
        object.setValue(item.textContent, forKey: Entity.textContent)
        object.setValue(item.imagePath, forKey: Entity.imagePath)
        try saveIfNeeded()
    }

    func updatePin(_ item: ClipboardHistoryItem) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.name)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "%K == %@", Entity.id, item.id as NSUUID)

        if let object = try container.viewContext.fetch(request).first {
            object.setValue(item.isPinned, forKey: Entity.isPinned)
            try saveIfNeeded()
        }
    }

    func deleteExpiredUnpinnedItems(olderThan cutoffDate: Date) throws -> [String] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.name)
        request.predicate = NSPredicate(
            format: "%K == %@ AND %K < %@",
            Entity.isPinned,
            NSNumber(value: false),
            Entity.createdAt,
            cutoffDate as NSDate
        )

        let objects = try container.viewContext.fetch(request)

        guard !objects.isEmpty else {
            return []
        }

        let imagePaths = objects.compactMap { $0.value(forKey: Entity.imagePath) as? String }

        for object in objects {
            container.viewContext.delete(object)
        }

        try saveIfNeeded()
        return imagePaths
    }

    func delete(_ item: ClipboardHistoryItem) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.name)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "%K == %@", Entity.id, item.id as NSUUID)

        if let object = try container.viewContext.fetch(request).first {
            container.viewContext.delete(object)
            try saveIfNeeded()
        }
    }

    func deleteAllItems() throws -> [String] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Entity.name)
        let objects = try container.viewContext.fetch(request)
        let imagePaths = objects.compactMap { $0.value(forKey: Entity.imagePath) as? String }

        guard !objects.isEmpty else {
            return []
        }

        for object in objects {
            container.viewContext.delete(object)
        }

        try saveIfNeeded()
        return imagePaths
    }

    private func saveIfNeeded() throws {
        let context = container.viewContext

        if context.hasChanges {
            try context.save()
        }
    }

    private static func storeURL() -> URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        let directory = appSupport.appendingPathComponent("HistoryClipboard", isDirectory: true)

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            assertionFailure("Failed to create Application Support directory: \(error)")
        }

        return directory.appendingPathComponent("HistoryClipboard.sqlite")
    }

    private static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = Entity.name
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let id = NSAttributeDescription()
        id.name = Entity.id
        id.attributeType = .UUIDAttributeType
        id.isOptional = false

        let type = NSAttributeDescription()
        type.name = Entity.type
        type.attributeType = .stringAttributeType
        type.isOptional = false

        let createdAt = NSAttributeDescription()
        createdAt.name = Entity.createdAt
        createdAt.attributeType = .dateAttributeType
        createdAt.isOptional = false

        let isPinned = NSAttributeDescription()
        isPinned.name = Entity.isPinned
        isPinned.attributeType = .booleanAttributeType
        isPinned.isOptional = false
        isPinned.defaultValue = false

        let textContent = NSAttributeDescription()
        textContent.name = Entity.textContent
        textContent.attributeType = .stringAttributeType
        textContent.isOptional = false

        let imagePath = NSAttributeDescription()
        imagePath.name = Entity.imagePath
        imagePath.attributeType = .stringAttributeType
        imagePath.isOptional = true

        entity.properties = [id, type, createdAt, isPinned, textContent, imagePath]
        model.entities = [entity]
        return model
    }
}
