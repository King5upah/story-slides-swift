import Foundation

/// A `BarajaCard` deck in its shareable, file-based form — any app using
/// this SDK can export a deck to a `.json` file (share sheet, AirDrop,
/// Files, Messages...) and any other app using this SDK can read it back,
/// regardless of what storage each app uses internally.
public struct ShareableDeck: Codable {
    public var name: String
    public var cards: [BarajaCard]

    public init(name: String, cards: [BarajaCard]) {
        self.name = name
        self.cards = cards
    }

    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    /// Writes this deck to a temporary `.json` file — pass the returned URL
    /// straight to a share sheet (e.g. `UIActivityViewController`).
    public func writeToTemporaryFile() throws -> URL {
        let data = try jsonData()
        let safeName = name
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(safeName.isEmpty ? "baraja" : safeName)
            .appendingPathExtension("json")
        try data.write(to: url, options: .atomic)
        return url
    }

    public static func decoded(from data: Data) throws -> ShareableDeck {
        try JSONDecoder().decode(ShareableDeck.self, from: data)
    }

    public static func decoded(fromFileAt url: URL) throws -> ShareableDeck {
        let data = try Data(contentsOf: url)
        return try decoded(from: data)
    }
}
