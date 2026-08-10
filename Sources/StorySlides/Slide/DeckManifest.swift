import Foundation

/// A versioned, portable `StoryDeckView` deck — the URL-shareable
/// counterpart to `ShareableDeck` (which is for `CardDeckView` decks).
/// Same shape as the JS SDK's `DeckManifest`
/// (`packages/protocol/src/types.ts` in story-slides), so a link generated
/// on web opens correctly here and vice versa.
public struct DeckManifest: Codable, Identifiable {
    public static let currentVersion = 1

    public var version: Int
    public var id: String
    public var title: String?
    public var icon: String?
    public var accentColor: String?
    public var slides: [StorySlide]

    public init(id: String, title: String? = nil, icon: String? = nil, accentColor: String? = nil, slides: [StorySlide]) {
        self.version = DeckManifest.currentVersion
        self.id = id
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
        self.slides = slides
    }

    func validate() throws {
        guard version == DeckManifest.currentVersion else {
            throw DeckManifestError.unsupportedVersion(version)
        }
        guard !id.isEmpty else {
            throw DeckManifestError.missingID
        }
    }

    /// Writes this manifest to a temporary `.json` file — pass the returned
    /// URL straight to a share sheet (e.g. `UIActivityViewController`).
    /// File-based counterpart to `encodeDeckToParam`, and the
    /// `StoryDeckView` equivalent of `ShareableDeck.writeToTemporaryFile()`.
    public func writeToTemporaryFile() throws -> URL {
        let json = try serializeDeck(self)
        let safeName = (title ?? id)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(safeName.isEmpty ? "deck" : safeName)
            .appendingPathExtension("json")
        try json.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    public static func decoded(from data: Data) throws -> DeckManifest {
        guard let json = String(data: data, encoding: .utf8) else {
            throw DeckManifestError.invalidJSON
        }
        return try deserializeDeck(json)
    }

    public static func decoded(fromFileAt url: URL) throws -> DeckManifest {
        let data = try Data(contentsOf: url)
        return try decoded(from: data)
    }
}

public enum DeckManifestError: Error, LocalizedError, Equatable {
    case invalidJSON
    case unsupportedVersion(Int)
    case missingID
    case invalidSlide(String)

    public var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Deck manifest is not valid JSON."
        case .unsupportedVersion(let version):
            return "Unsupported deck manifest version: \(version) (expected \(DeckManifest.currentVersion))."
        case .missingID:
            return "Deck manifest is missing a non-empty \"id\"."
        case .invalidSlide(let reason):
            return "Deck manifest has an invalid slide: \(reason)"
        }
    }
}
