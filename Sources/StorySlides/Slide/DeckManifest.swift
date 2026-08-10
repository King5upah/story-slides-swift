import Foundation

/// A versioned, portable `StoryDeckView` deck — the URL-shareable
/// counterpart to `ShareableDeck` (which is for `CardDeckView` decks).
/// Same shape as the JS SDK's `DeckManifest`
/// (`packages/protocol/src/types.ts` in story-slides), so a link generated
/// on web opens correctly here and vice versa.
public struct DeckManifest: Codable {
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
