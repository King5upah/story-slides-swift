import SwiftUI

/// Renders one `CardWidget` full-bleed, same visual language as a
/// `StorySlide` (big centered type, no chrome). Non-interactive areas are
/// left hit-testable-through so the deck's shared tap zones still work —
/// only real choices (quiz options, a text field) are tappable controls.
struct CardWidgetContent: View {
    let prompt: String?
    let widget: CardWidget
    let accentColor: Color
    let isResolved: Bool
    let onResolved: (Bool?) -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)

            if let prompt {
                Text(prompt.uppercased())
                    .font(.footnote.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(accentColor)
            }

            content(for: widget)

            Spacer(minLength: 0)

            if showsContinueHint {
                Text("Toca para continuar")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 36)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var showsContinueHint: Bool {
        switch widget.tapBehavior {
        case .advanceImmediately: return true
        case .revealThenAdvance: return isResolved
        case .requiresInteraction: return isResolved
        }
    }

    @ViewBuilder
    private func content(for widget: CardWidget) -> some View {
        switch widget {
        case let .flipCard(front, back):
            FlipCardContent(front: front, back: back, isRevealed: isResolved, accentColor: accentColor)

        case let .singleChoiceQuiz(question, options, correctIndex, explanation):
            ChoiceQuizContent(
                question: question,
                options: options,
                correctIndices: [correctIndex],
                isMultiSelect: false,
                explanation: explanation,
                accentColor: accentColor,
                isResolved: isResolved,
                onResolved: onResolved
            )

        case let .multiChoiceQuiz(question, options, correctIndices, explanation):
            ChoiceQuizContent(
                question: question,
                options: options,
                correctIndices: correctIndices,
                isMultiSelect: true,
                explanation: explanation,
                accentColor: accentColor,
                isResolved: isResolved,
                onResolved: onResolved
            )

        case let .trueFalse(statement, isTrue, explanation):
            ChoiceQuizContent(
                question: statement,
                options: ["Verdadero", "Falso"],
                correctIndices: [isTrue ? 0 : 1],
                isMultiSelect: false,
                explanation: explanation,
                accentColor: accentColor,
                isResolved: isResolved,
                onResolved: onResolved
            )

        case let .fillInBlank(prompt, answer, hint):
            FillInBlankContent(
                prompt: prompt,
                answer: answer,
                hint: hint,
                accentColor: accentColor,
                isResolved: isResolved,
                onResolved: onResolved
            )

        case let .counter(label, value, total):
            StatContent(label: label, value: total.map { "\(value)/\($0)" } ?? "\(value)", accentColor: accentColor)

        case let .rating(label, value, maxValue):
            StatContent(
                label: label,
                value: String(repeating: "★", count: value) + String(repeating: "☆", count: max(0, maxValue - value)),
                accentColor: accentColor
            )
        }
    }
}

private struct FlipCardContent: View {
    let front: String
    let back: String
    let isRevealed: Bool
    let accentColor: Color

    private var backHeadline: String {
        back.components(separatedBy: "\n\n").first ?? back
    }

    private var backCaption: String? {
        let parts = back.components(separatedBy: "\n\n")
        return parts.count > 1 ? parts[1] : nil
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(isRevealed ? backHeadline : front)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .transition(.opacity)
                .id(isRevealed)

            if isRevealed, let backCaption {
                Text(backCaption)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.7))
            }

            if !isRevealed {
                Text("Toca para ver la traducción")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isRevealed)
    }
}

private struct ChoiceQuizContent: View {
    let question: String
    let options: [String]
    let correctIndices: Set<Int>
    let isMultiSelect: Bool
    let explanation: String?
    let accentColor: Color
    let isResolved: Bool
    let onResolved: (Bool?) -> Void

    @State private var selected: Set<Int> = []

    var body: some View {
        VStack(spacing: 24) {
            Text(question)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                ForEach(options.indices, id: \.self) { i in
                    Button {
                        select(i)
                    } label: {
                        HStack {
                            Text(options[i])
                            Spacer()
                            if isResolved {
                                if correctIndices.contains(i) {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                } else if selected.contains(i) {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                                }
                            }
                        }
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(background(for: i), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isResolved)
                }
            }

            if isMultiSelect && !isResolved {
                Button("Comprobar") {
                    onResolved(selected == correctIndices)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accentColor)
                .disabled(selected.isEmpty)
            }

            if isResolved, let explanation {
                Text(explanation)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func select(_ i: Int) {
        guard !isResolved else { return }
        if isMultiSelect {
            if selected.contains(i) { selected.remove(i) } else { selected.insert(i) }
        } else {
            selected = [i]
            onResolved(selected == correctIndices)
        }
    }

    private func background(for index: Int) -> Color {
        guard isResolved else {
            return selected.contains(index) ? .white.opacity(0.16) : .white.opacity(0.06)
        }
        if correctIndices.contains(index) { return .green.opacity(0.22) }
        if selected.contains(index) { return .red.opacity(0.22) }
        return .white.opacity(0.04)
    }
}

private struct FillInBlankContent: View {
    let prompt: String
    let answer: String
    let hint: String?
    let accentColor: Color
    let isResolved: Bool
    let onResolved: (Bool?) -> Void

    @State private var input = ""
    @FocusState private var isFocused: Bool

    private var isCorrect: Bool {
        input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            == answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(prompt)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            if isResolved {
                Text(isCorrect ? "¡Correcto!" : "Era: \(answer)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isCorrect ? .green : .red)
            } else {
                TextField("Escribe tu respuesta", text: $input)
                    .focused($isFocused)
                    .multilineTextAlignment(.center)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .textFieldStyle(.plain)
                    .padding(.bottom, 8)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(accentColor.opacity(0.6)).frame(height: 1)
                    }
                    .submitLabel(.done)
                    .onSubmit {
                        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        isFocused = false
                        onResolved(isCorrect)
                    }

                if let hint {
                    Text("Pista: \(hint)")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .onAppear { isFocused = true }
    }
}

private struct StatContent: View {
    let label: String
    let value: String
    let accentColor: Color

    var body: some View {
        VStack(spacing: 10) {
            Text(label.uppercased())
                .font(.footnote.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(accentColor)
            Text(value)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}
