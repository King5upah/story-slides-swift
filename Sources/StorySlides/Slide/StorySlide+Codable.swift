import Foundation

/// Manual `Codable` conformance for `StorySlide`, keyed by a `type`
/// discriminator that matches the wire format produced by the JS SDK
/// (`packages/protocol/src/types.ts` in story-slides) field-for-field —
/// **except** for three slides where the two SDKs' native shapes have
/// genuinely diverged, bridged explicitly below:
///
/// - `.highlight` carries an extra `heading` (eyebrow label) the JS side
///   doesn't have. It's still encoded (as an extra JSON key JS's validator
///   ignores, since it only checks *required* fields) so Swift↔Swift
///   round-trips keep it; decoding a JS-originated highlight defaults it
///   to `""`. JS's `content` field maps to Swift's `value`.
/// - `.table` is a fixed 2-column (label, value) list in Swift vs. JS's
///   arbitrary N-column `headers`/`rows`. Encoding always emits
///   `headers: ["", ""]` (Swift has no per-column headers) and 2-cell
///   rows; decoding a JS table takes each row's first two cells (padding
///   with `""` if a row has fewer) and drops `headers` — this is a lossy
///   but graceful degradation, not a crash.
/// - `.photo` has no JS equivalent at all (embedding binary image data in
///   a URL-shareable `DeckManifest` isn't practical). It round-trips fine
///   Swift↔Swift, but a manifest containing one will fail to decode on the
///   JS side — there's no way around that without JS growing a photo slide
///   type, so this is documented rather than silently patched over.
extension StorySlide: Codable {
    private enum Kind: String, Codable {
        case title, text, highlight, example, table, tip, quiz, cta, photo
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case icon, heading, subheading
        case body
        case content, caption
        case text, note
        case headers, rows
        case question, options, correct, explanation
        case label
        case imageData
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let rawType = try c.decode(String.self, forKey: .type)
        guard let kind = Kind(rawValue: rawType) else {
            throw StorySlideCodingError.unknownType(rawType)
        }

        switch kind {
        case .title:
            self = .title(
                icon: try c.decodeIfPresent(String.self, forKey: .icon) ?? "",
                heading: try c.decode(String.self, forKey: .heading),
                subheading: try c.decodeIfPresent(String.self, forKey: .subheading)
            )
        case .text:
            self = .text(
                heading: try c.decodeIfPresent(String.self, forKey: .heading),
                body: try c.decode(String.self, forKey: .body)
            )
        case .highlight:
            self = .highlight(
                heading: try c.decodeIfPresent(String.self, forKey: .heading) ?? "",
                value: try c.decode(String.self, forKey: .content),
                caption: try c.decodeIfPresent(String.self, forKey: .caption)
            )
        case .example:
            self = .example(text: try c.decode(String.self, forKey: .text))
        case .table:
            let jsRows = try c.decode([[String]].self, forKey: .rows)
            self = .table(
                heading: try c.decodeIfPresent(String.self, forKey: .caption),
                rows: jsRows.map { row in (label: row.first ?? "", value: row.count > 1 ? row[1] : "") }
            )
        case .tip:
            self = .tip(text: try c.decode(String.self, forKey: .body))
        case .quiz:
            self = .quiz(
                question: try c.decode(String.self, forKey: .question),
                options: try c.decode([String].self, forKey: .options),
                correctIndex: try c.decode(Int.self, forKey: .correct),
                explanation: try c.decode(String.self, forKey: .explanation)
            )
        case .cta:
            self = .cta(
                heading: try c.decode(String.self, forKey: .heading),
                body: try c.decode(String.self, forKey: .body),
                label: try c.decode(String.self, forKey: .label)
            )
        case .photo:
            self = .photo(
                imageData: try c.decode(Data.self, forKey: .imageData),
                caption: try c.decodeIfPresent(String.self, forKey: .caption)
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .title(icon, heading, subheading):
            try c.encode(Kind.title, forKey: .type)
            try c.encode(icon, forKey: .icon)
            try c.encode(heading, forKey: .heading)
            try c.encodeIfPresent(subheading, forKey: .subheading)
        case let .text(heading, body):
            try c.encode(Kind.text, forKey: .type)
            try c.encodeIfPresent(heading, forKey: .heading)
            try c.encode(body, forKey: .body)
        case let .highlight(heading, value, caption):
            try c.encode(Kind.highlight, forKey: .type)
            try c.encode(value, forKey: .content)
            try c.encodeIfPresent(caption, forKey: .caption)
            try c.encode(heading, forKey: .heading) // Swift-only extra; JS ignores unknown keys.
        case let .example(text):
            try c.encode(Kind.example, forKey: .type)
            try c.encode(text, forKey: .text)
        case let .table(heading, rows):
            try c.encode(Kind.table, forKey: .type)
            try c.encode([String](repeating: "", count: 2), forKey: .headers)
            try c.encode(rows.map { [$0.label, $0.value] }, forKey: .rows)
            try c.encodeIfPresent(heading, forKey: .caption)
        case let .tip(text):
            try c.encode(Kind.tip, forKey: .type)
            try c.encode(text, forKey: .body)
        case let .quiz(question, options, correctIndex, explanation):
            try c.encode(Kind.quiz, forKey: .type)
            try c.encode(question, forKey: .question)
            try c.encode(options, forKey: .options)
            try c.encode(correctIndex, forKey: .correct)
            try c.encode(explanation, forKey: .explanation)
        case let .cta(heading, body, label):
            try c.encode(Kind.cta, forKey: .type)
            try c.encode(heading, forKey: .heading)
            try c.encode(body, forKey: .body)
            try c.encode(label, forKey: .label)
        case let .photo(imageData, caption):
            try c.encode(Kind.photo, forKey: .type)
            try c.encode(imageData, forKey: .imageData)
            try c.encodeIfPresent(caption, forKey: .caption)
        }
    }
}

public enum StorySlideCodingError: Error, LocalizedError {
    case unknownType(String)

    public var errorDescription: String? {
        switch self {
        case .unknownType(let type):
            return "Unknown StorySlide type: \"\(type)\""
        }
    }
}
