import Foundation

/// A configurable action a tappable slide/widget can carry — `url` and
/// `deeplink` are just data as far as the SDK is concerned, it never opens
/// either on its own. `actionId` is an app-defined identifier the host app
/// interprets itself. All three funnel through the same `onAction` callback.
/// Same shape (keyed by `kind`) as the web SDK's `CTAAction`.
public enum CTAAction: Codable, Equatable {
    case url(String)
    case deeplink(String)
    case actionId(id: String, payload: [String: String]?)

    private enum Kind: String, Codable {
        case url, deeplink, actionId
    }

    private enum CodingKeys: String, CodingKey {
        case kind, url, id, payload
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(Kind.self, forKey: .kind) {
        case .url:
            self = .url(try c.decode(String.self, forKey: .url))
        case .deeplink:
            self = .deeplink(try c.decode(String.self, forKey: .url))
        case .actionId:
            self = .actionId(
                id: try c.decode(String.self, forKey: .id),
                payload: try c.decodeIfPresent([String: String].self, forKey: .payload)
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .url(url):
            try c.encode(Kind.url, forKey: .kind)
            try c.encode(url, forKey: .url)
        case let .deeplink(url):
            try c.encode(Kind.deeplink, forKey: .kind)
            try c.encode(url, forKey: .url)
        case let .actionId(id, payload):
            try c.encode(Kind.actionId, forKey: .kind)
            try c.encode(id, forKey: .id)
            try c.encodeIfPresent(payload, forKey: .payload)
        }
    }
}
