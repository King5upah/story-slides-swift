import Foundation

/// Manual `Codable` conformance for `CardWidget` (a discriminated union
/// isn't synthesizable), keyed by a `kind` field — this is what makes
/// `ShareableDeck` possible.
extension CardWidget: Codable {
    private enum Kind: String, Codable {
        case singleChoiceQuiz, multiChoiceQuiz, trueFalse, fillInBlank, flipCard, counter, rating
    }

    private enum CodingKeys: String, CodingKey {
        case kind
        case question, options, correctIndex, correctIndices, explanation
        case statement, isTrue
        case prompt, answer, hint
        case front, back
        case label, value, total, maxValue
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(Kind.self, forKey: .kind) {
        case .singleChoiceQuiz:
            self = .singleChoiceQuiz(
                question: try c.decode(String.self, forKey: .question),
                options: try c.decode([String].self, forKey: .options),
                correctIndex: try c.decode(Int.self, forKey: .correctIndex),
                explanation: try c.decodeIfPresent(String.self, forKey: .explanation)
            )
        case .multiChoiceQuiz:
            self = .multiChoiceQuiz(
                question: try c.decode(String.self, forKey: .question),
                options: try c.decode([String].self, forKey: .options),
                correctIndices: try c.decode(Set<Int>.self, forKey: .correctIndices),
                explanation: try c.decodeIfPresent(String.self, forKey: .explanation)
            )
        case .trueFalse:
            self = .trueFalse(
                statement: try c.decode(String.self, forKey: .statement),
                isTrue: try c.decode(Bool.self, forKey: .isTrue),
                explanation: try c.decodeIfPresent(String.self, forKey: .explanation)
            )
        case .fillInBlank:
            self = .fillInBlank(
                prompt: try c.decode(String.self, forKey: .prompt),
                answer: try c.decode(String.self, forKey: .answer),
                hint: try c.decodeIfPresent(String.self, forKey: .hint)
            )
        case .flipCard:
            self = .flipCard(
                front: try c.decode(String.self, forKey: .front),
                back: try c.decode(String.self, forKey: .back)
            )
        case .counter:
            self = .counter(
                label: try c.decode(String.self, forKey: .label),
                value: try c.decode(Int.self, forKey: .value),
                total: try c.decodeIfPresent(Int.self, forKey: .total)
            )
        case .rating:
            self = .rating(
                label: try c.decode(String.self, forKey: .label),
                value: try c.decode(Int.self, forKey: .value),
                maxValue: try c.decode(Int.self, forKey: .maxValue)
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .singleChoiceQuiz(question, options, correctIndex, explanation):
            try c.encode(Kind.singleChoiceQuiz, forKey: .kind)
            try c.encode(question, forKey: .question)
            try c.encode(options, forKey: .options)
            try c.encode(correctIndex, forKey: .correctIndex)
            try c.encodeIfPresent(explanation, forKey: .explanation)
        case let .multiChoiceQuiz(question, options, correctIndices, explanation):
            try c.encode(Kind.multiChoiceQuiz, forKey: .kind)
            try c.encode(question, forKey: .question)
            try c.encode(options, forKey: .options)
            try c.encode(correctIndices, forKey: .correctIndices)
            try c.encodeIfPresent(explanation, forKey: .explanation)
        case let .trueFalse(statement, isTrue, explanation):
            try c.encode(Kind.trueFalse, forKey: .kind)
            try c.encode(statement, forKey: .statement)
            try c.encode(isTrue, forKey: .isTrue)
            try c.encodeIfPresent(explanation, forKey: .explanation)
        case let .fillInBlank(prompt, answer, hint):
            try c.encode(Kind.fillInBlank, forKey: .kind)
            try c.encode(prompt, forKey: .prompt)
            try c.encode(answer, forKey: .answer)
            try c.encodeIfPresent(hint, forKey: .hint)
        case let .flipCard(front, back):
            try c.encode(Kind.flipCard, forKey: .kind)
            try c.encode(front, forKey: .front)
            try c.encode(back, forKey: .back)
        case let .counter(label, value, total):
            try c.encode(Kind.counter, forKey: .kind)
            try c.encode(label, forKey: .label)
            try c.encode(value, forKey: .value)
            try c.encodeIfPresent(total, forKey: .total)
        case let .rating(label, value, maxValue):
            try c.encode(Kind.rating, forKey: .kind)
            try c.encode(label, forKey: .label)
            try c.encode(value, forKey: .value)
            try c.encode(maxValue, forKey: .maxValue)
        }
    }
}

extension BarajaCard: Codable {
    enum CodingKeys: String, CodingKey {
        case id, prompt, widget
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID(),
            prompt: try c.decodeIfPresent(String.self, forKey: .prompt),
            widget: try c.decode(CardWidget.self, forKey: .widget)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(prompt, forKey: .prompt)
        try c.encode(widget, forKey: .widget)
    }
}
