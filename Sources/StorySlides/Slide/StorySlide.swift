import Foundation

/// A single slide in a tap-to-advance story deck — the same slide
/// vocabulary as github.com/King5upah/story-slides (the React version): no
/// autoplay timer, the reader controls the pace by tapping left/right.
public enum StorySlide {
    case title(icon: String, heading: String, subheading: String?, action: CTAAction? = nil)
    case text(heading: String?, body: String, action: CTAAction? = nil)
    case highlight(heading: String, value: String, caption: String?, action: CTAAction? = nil)
    case example(text: String, action: CTAAction? = nil)
    case table(heading: String?, rows: [(label: String, value: String)], action: CTAAction? = nil)
    case tip(text: String, action: CTAAction? = nil)
    case quiz(question: String, options: [String], correctIndex: Int, explanation: String, action: CTAAction? = nil)
    case cta(heading: String, body: String, label: String, action: CTAAction? = nil)
    case photo(imageData: Data, caption: String?, action: CTAAction? = nil)

    /// The action this slide carries, if any — fired via `StoryDeckView`'s
    /// `onAction` when the slide's interaction resolves (cta tapped, quiz
    /// answered). Passive slides never resolve, so their `action` is inert.
    public var action: CTAAction? {
        switch self {
        case let .title(_, _, _, action),
             let .text(_, _, action),
             let .highlight(_, _, _, action),
             let .example(_, action),
             let .table(_, _, action),
             let .tip(_, action),
             let .quiz(_, _, _, _, action),
             let .cta(_, _, _, action),
             let .photo(_, _, action):
            return action
        }
    }
}
