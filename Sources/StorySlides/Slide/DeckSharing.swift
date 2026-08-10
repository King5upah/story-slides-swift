import Foundation

/// Serializes `manifest` to JSON. Mirrors the web SDK's `serializeDeck` —
/// no validation here (that's `deserializeDeck`'s job, for untrusted
/// input); a `DeckManifest` value is already well-formed by construction.
public func serializeDeck(_ manifest: DeckManifest) throws -> String {
    let data = try JSONEncoder().encode(manifest)
    guard let json = String(data: data, encoding: .utf8) else {
        throw DeckManifestError.invalidJSON
    }
    return json
}

/// Parses and validates `json` into a `DeckManifest`. Throws
/// `DeckManifestError` — never crashes, never silently accepts malformed
/// input — mirroring the web SDK's `deserializeDeck`/`InvalidDeckError`.
public func deserializeDeck(_ json: String) throws -> DeckManifest {
    guard let data = json.data(using: .utf8) else {
        throw DeckManifestError.invalidJSON
    }
    let manifest: DeckManifest
    do {
        manifest = try JSONDecoder().decode(DeckManifest.self, from: data)
    } catch let error as StorySlideCodingError {
        throw DeckManifestError.invalidSlide(error.localizedDescription)
    } catch {
        throw DeckManifestError.invalidJSON
    }
    try manifest.validate()
    return manifest
}

/// Packs `manifest` into a URL-safe base64 string, ready for a `?deck=`
/// query param. Byte-for-byte the same algorithm as the web SDK's
/// `encodeDeckToParam` (standard base64, `+`/`/` swapped for `-`/`_`,
/// padding stripped) — this is the part where cross-platform bugs tend to
/// hide, so it's tested against the real JS implementation, not just
/// re-derived independently.
public func encodeDeckToParam(_ manifest: DeckManifest) throws -> String {
    toBase64URL(try serializeDeck(manifest))
}

public func decodeDeckFromParam(_ param: String) throws -> DeckManifest {
    try deserializeDeck(try fromBase64URL(param))
}

/// Appends an encoded `manifest` to `baseURL` as a `deck` query param.
public func buildShareURL(_ baseURL: URL, deck manifest: DeckManifest) throws -> URL {
    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
        throw DeckManifestError.invalidJSON
    }
    var items = components.queryItems ?? []
    items.removeAll { $0.name == "deck" }
    items.append(URLQueryItem(name: "deck", value: try encodeDeckToParam(manifest)))
    components.queryItems = items
    guard let url = components.url else {
        throw DeckManifestError.invalidJSON
    }
    return url
}

/// Reads a `deck` query param out of `url` and decodes it, or returns
/// `nil` if `url` doesn't have one (there's nothing to read — this app
/// wasn't opened from a share link).
public func readDeckFromLocation(_ url: URL) throws -> DeckManifest? {
    guard
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
        let param = components.queryItems?.first(where: { $0.name == "deck" })?.value
    else {
        return nil
    }
    return try decodeDeckFromParam(param)
}

private func toBase64URL(_ input: String) -> String {
    guard let data = input.data(using: .utf8) else { return "" }
    return data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

private func fromBase64URL(_ input: String) throws -> String {
    var base64 = input
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    let remainder = base64.count % 4
    if remainder > 0 {
        base64 += String(repeating: "=", count: 4 - remainder)
    }
    guard let data = Data(base64Encoded: base64), let json = String(data: data, encoding: .utf8) else {
        throw DeckManifestError.invalidJSON
    }
    return json
}
