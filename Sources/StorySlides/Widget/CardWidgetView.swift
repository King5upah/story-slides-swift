import SwiftUI

/// Renders one `CardWidget` and calls `onFinished` once the user is ready to
/// advance — with `isCorrect` set for graded widgets, `nil` for ungraded ones.
struct CardWidgetView: View {
    let prompt: String?
    let widget: CardWidget
    let accentColor: Color
    let onFinished: (Bool?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let prompt {
                Text(prompt.uppercased())
                    .font(.footnote.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(accentColor)
            }

            switch widget {
            case let .singleChoiceQuiz(question, options, correctIndex, explanation):
                ChoiceQuizView(
                    question: question,
                    options: options,
                    correctIndices: [correctIndex],
                    isMultiSelect: false,
                    explanation: explanation,
                    accentColor: accentColor,
                    onFinished: onFinished
                )

            case let .multiChoiceQuiz(question, options, correctIndices, explanation):
                ChoiceQuizView(
                    question: question,
                    options: options,
                    correctIndices: correctIndices,
                    isMultiSelect: true,
                    explanation: explanation,
                    accentColor: accentColor,
                    onFinished: onFinished
                )

            case let .trueFalse(statement, isTrue, explanation):
                TrueFalseView(
                    statement: statement,
                    isTrue: isTrue,
                    explanation: explanation,
                    accentColor: accentColor,
                    onFinished: onFinished
                )

            case let .fillInBlank(prompt, answer, hint):
                FillInBlankView(
                    prompt: prompt,
                    answer: answer,
                    hint: hint,
                    accentColor: accentColor,
                    onFinished: onFinished
                )

            case let .flipCard(front, back):
                FlipCardView(front: front, back: back, accentColor: accentColor, onFinished: onFinished)

            case let .counter(label, value, total):
                StatView(
                    label: label,
                    value: total.map { "\(value)/\($0)" } ?? "\(value)",
                    accentColor: accentColor,
                    onFinished: onFinished
                )

            case let .rating(label, value, maxValue):
                StatView(
                    label: label,
                    value: String(repeating: "★", count: value) + String(repeating: "☆", count: max(0, maxValue - value)),
                    accentColor: accentColor,
                    onFinished: onFinished
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ContinueButton: View {
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button("Continuar", action: action)
            .font(.headline)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(accentColor, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct ChoiceQuizView: View {
    let question: String
    let options: [String]
    let correctIndices: Set<Int>
    let isMultiSelect: Bool
    let explanation: String?
    let accentColor: Color
    let onFinished: (Bool?) -> Void

    @State private var selected: Set<Int> = []
    @State private var isLocked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(question)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                ForEach(options.indices, id: \.self) { i in
                    Button {
                        guard !isLocked else { return }
                        if isMultiSelect {
                            if selected.contains(i) { selected.remove(i) } else { selected.insert(i) }
                        } else {
                            selected = [i]
                        }
                    } label: {
                        HStack {
                            Text(options[i])
                                .foregroundStyle(.white)
                            Spacer()
                            if isLocked {
                                if correctIndices.contains(i) {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                } else if selected.contains(i) {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                                }
                            }
                        }
                        .padding(14)
                        .background(background(for: i), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isLocked)
                }
            }

            if isLocked {
                if let explanation {
                    Text(explanation)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                }
                ContinueButton(accentColor: accentColor) {
                    onFinished(selected == correctIndices)
                }
            } else if isMultiSelect {
                Button("Comprobar") { isLocked = true }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accentColor, in: RoundedRectangle(cornerRadius: 14))
                    .disabled(selected.isEmpty)
            }
        }
        .onChange(of: selected) { _, newValue in
            guard !isMultiSelect, !newValue.isEmpty else { return }
            isLocked = true
        }
    }

    private func background(for index: Int) -> Color {
        guard isLocked else {
            return selected.contains(index) ? .white.opacity(0.18) : .white.opacity(0.08)
        }
        if correctIndices.contains(index) { return .green.opacity(0.25) }
        if selected.contains(index) { return .red.opacity(0.25) }
        return .white.opacity(0.05)
    }
}

private struct TrueFalseView: View {
    let statement: String
    let isTrue: Bool
    let explanation: String?
    let accentColor: Color
    let onFinished: (Bool?) -> Void

    @State private var answer: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(statement)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                optionButton(label: "Verdadero", value: true)
                optionButton(label: "Falso", value: false)
            }

            if answer != nil {
                if let explanation {
                    Text(explanation)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                }
                ContinueButton(accentColor: accentColor) {
                    onFinished(answer == isTrue)
                }
            }
        }
    }

    private func optionButton(label: String, value: Bool) -> some View {
        Button {
            guard answer == nil else { return }
            answer = value
        } label: {
            Text(label)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(background(for: value), in: RoundedRectangle(cornerRadius: 14))
        }
        .disabled(answer != nil)
    }

    private func background(for value: Bool) -> Color {
        guard let answer else { return .white.opacity(0.08) }
        if value == isTrue { return .green.opacity(0.25) }
        if value == answer { return .red.opacity(0.25) }
        return .white.opacity(0.05)
    }
}

private struct FillInBlankView: View {
    let prompt: String
    let answer: String
    let hint: String?
    let accentColor: Color
    let onFinished: (Bool?) -> Void

    @State private var input = ""
    @State private var isChecked = false
    @FocusState private var isFocused: Bool

    private var isCorrect: Bool {
        input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            == answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(prompt)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            TextField("Tu respuesta", text: $input)
                .focused($isFocused)
                .textFieldStyle(.plain)
                .padding(14)
                .foregroundStyle(.white)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                .disabled(isChecked)
                .autocorrectionDisabled()

            if let hint, !isChecked {
                Text("Pista: \(hint)")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }

            if isChecked {
                Text(isCorrect ? "¡Correcto!" : "La respuesta era: \(answer)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(isCorrect ? .green : .red)
                ContinueButton(accentColor: accentColor) {
                    onFinished(isCorrect)
                }
            } else {
                Button("Comprobar") {
                    isFocused = false
                    isChecked = true
                }
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(accentColor, in: RoundedRectangle(cornerRadius: 14))
                .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

private struct FlipCardView: View {
    let front: String
    let back: String
    let accentColor: Color
    let onFinished: (Bool?) -> Void

    @State private var isFlipped = false

    var body: some View {
        VStack(spacing: 20) {
            Button {
                withAnimation(.spring(duration: 0.4)) { isFlipped.toggle() }
            } label: {
                Text(isFlipped ? back : front)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .padding(24)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(accentColor.opacity(0.6), lineWidth: 1)
                    )
            }
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            Text(isFlipped ? "Toca para ver el frente" : "Toca para voltear")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))

            if isFlipped {
                ContinueButton(accentColor: accentColor) {
                    onFinished(nil)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StatView: View {
    let label: String
    let value: String
    let accentColor: Color
    let onFinished: (Bool?) -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text(label.uppercased())
                    .font(.footnote.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(accentColor)
                Text(value)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))

            ContinueButton(accentColor: accentColor) {
                onFinished(nil)
            }
        }
    }
}
