import Foundation

/// An interactive widget shown on a single card of a `CardDeckView`.
/// This is the extensible part of the SDK — more cases can be added over
/// time without touching `StorySlide` (the passive, non-graded deck type).
public enum CardWidget {
    case singleChoiceQuiz(question: String, options: [String], correctIndex: Int, explanation: String?)
    case multiChoiceQuiz(question: String, options: [String], correctIndices: Set<Int>, explanation: String?)
    case trueFalse(statement: String, isTrue: Bool, explanation: String?)
    case fillInBlank(prompt: String, answer: String, hint: String?)
    case flipCard(front: String, back: String)
    case counter(label: String, value: Int, total: Int?)
    case rating(label: String, value: Int, maxValue: Int)

    /// Whether this widget needs a graded answer before advancing (counts
    /// toward `DeckResult`), vs. just an acknowledgement (flip cards, stats).
    public var isGraded: Bool {
        switch self {
        case .singleChoiceQuiz, .multiChoiceQuiz, .trueFalse, .fillInBlank:
            return true
        case .flipCard, .counter, .rating:
            return false
        }
    }

    /// How the deck's shared left/right tap zones (same ones `StoryDeckView`
    /// uses) resolve this card — everything advances the same way a story
    /// does; only widgets with a real choice to make need their own tap
    /// targets (the options themselves).
    public enum TapBehavior {
        /// First tap reveals the rest of the content, second tap advances
        /// (flip cards: front → back → next).
        case revealThenAdvance
        /// Nothing to answer — a tap advances immediately, like any other
        /// story slide.
        case advanceImmediately
        /// The card has its own tappable controls (quiz options, a text
        /// field); the shared tap zone only advances once it's answered.
        case requiresInteraction
    }

    public var tapBehavior: TapBehavior {
        switch self {
        case .flipCard:
            return .revealThenAdvance
        case .counter, .rating:
            return .advanceImmediately
        case .singleChoiceQuiz, .multiChoiceQuiz, .trueFalse, .fillInBlank:
            return .requiresInteraction
        }
    }
}

/// A single card in a `CardDeckView` — an optional context label plus the
/// widget that renders its content.
public struct BarajaCard: Identifiable {
    public let id: UUID
    public var prompt: String?
    public var widget: CardWidget

    public init(id: UUID = UUID(), prompt: String? = nil, widget: CardWidget) {
        self.id = id
        self.prompt = prompt
        self.widget = widget
    }
}

/// Score summary shown at the end of a `CardDeckView` run.
public struct DeckResult {
    public let total: Int
    public let graded: Int
    public let correct: Int

    public init(total: Int, graded: Int, correct: Int) {
        self.total = total
        self.graded = graded
        self.correct = correct
    }
}
