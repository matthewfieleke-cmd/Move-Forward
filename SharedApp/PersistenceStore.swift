import Foundation

struct PersistenceStore: Sendable {
    var fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    static func defaultURL(appGroup: String? = nil) -> URL {
        let directory: URL
        if let appGroup, let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            directory = container
        } else {
            directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("MoveForward", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("state.json")
    }

    func load() -> PersistedSnapshot {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return seededSnapshot()
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            var snapshot = try decoder.decode(PersistedSnapshot.self, from: data)
            if snapshot.templates.isEmpty {
                snapshot.templates = StarterTemplates.all
                snapshot.templatesRevision = max(snapshot.templatesRevision, 1)
            }
            return snapshot
        } catch {
            return seededSnapshot()
        }
    }

    func save(_ snapshot: PersistedSnapshot) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        let temporary = fileURL.appendingPathExtension("tmp")
        try data.write(to: temporary, options: .atomic)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: temporary)
        } else {
            try FileManager.default.moveItem(at: temporary, to: fileURL)
        }
    }

    private func seededSnapshot() -> PersistedSnapshot {
        PersistedSnapshot(
            schemaVersion: 1,
            templates: StarterTemplates.all,
            session: nil,
            completedVisits: [],
            settings: .default,
            templatesRevision: 1
        )
    }
}
