import Foundation

/// A single slide in a tap-to-advance story deck — the same slide
/// vocabulary as github.com/King5upah/story-slides (the React version): no
/// autoplay timer, the reader controls the pace by tapping left/right.
public enum StorySlide {
    case title(icon: String, heading: String, subheading: String?)
    case text(heading: String?, body: String)
    case highlight(heading: String, value: String, caption: String?)
    case example(text: String)
    case table(heading: String?, rows: [(label: String, value: String)])
    case tip(text: String)
    case cta(heading: String, body: String, label: String)
    case photo(imageData: Data, caption: String?)
}
