import SwiftUI

/// Runs a deck of `BarajaCard`s one at a time using the exact same
/// interaction language as `StoryDeckView`: tap left/right to go back or
/// advance. Graded widgets (quizzes, true/false, fill-in-the-blank) answer
/// through their own controls; everything else — including revealing a flip
/// card's back — advances through the shared tap zones, just like a story.
/// Ends on a score screen.
public struct CardDeckView: View {
    let title: String
    let icon: String
    let accentColor: Color
    let cards: [BarajaCard]
    let onExit: () -> Void
    let onFinish: (DeckResult) -> Void

    @State private var index = 0
    @State private var isResolved = false
    @State private var correctCount = 0
    @State private var gradedCount = 0
    @State private var isFinished = false

    public init(
        title: String,
        icon: String = "rectangle.stack.fill",
        accentColor: Color = .accentColor,
        cards: [BarajaCard],
        onExit: @escaping () -> Void = {},
        onFinish: @escaping (DeckResult) -> Void = { _ in }
    ) {
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
        self.cards = cards
        self.onExit = onExit
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isFinished {
                DeckResultView(
                    result: DeckResult(total: cards.count, graded: gradedCount, correct: correctCount),
                    accentColor: accentColor,
                    onClose: {
                        onFinish(DeckResult(total: cards.count, graded: gradedCount, correct: correctCount))
                        onExit()
                    }
                )
            } else if cards.indices.contains(index) {
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture { goBack() }
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture { handleRightTap() }
                }

                CardWidgetContent(
                    prompt: cards[index].prompt,
                    widget: cards[index].widget,
                    accentColor: accentColor,
                    isResolved: isResolved,
                    onResolved: resolve
                )
                .id(cards[index].id)

                VStack(spacing: 0) {
                    header
                    Spacer()
                }
            }
        }
        .preferredColorScheme(.dark)
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.height > 80 { onExit() }
                }
        )
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                ForEach(cards.indices, id: \.self) { i in
                    Capsule()
                        .fill(Color.white.opacity(i <= index ? 1 : 0.25))
                        .frame(maxWidth: .infinity)
                        .frame(height: 3)
                }
            }
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    onExit()
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.white.opacity(0.15), in: Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func handleRightTap() {
        guard cards.indices.contains(index) else { return }
        if isResolved {
            advance()
            return
        }
        switch cards[index].widget.tapBehavior {
        case .advanceImmediately:
            resolve(nil)
            advance()
        case .revealThenAdvance:
            withAnimation(.easeInOut(duration: 0.2)) { isResolved = true }
        case .requiresInteraction:
            break
        }
    }

    private func resolve(_ isCorrect: Bool?) {
        guard !isResolved else { return }
        isResolved = true
        if let isCorrect {
            gradedCount += 1
            if isCorrect { correctCount += 1 }
        }
    }

    private func goBack() {
        guard index > 0 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            index -= 1
            isResolved = false
        }
    }

    private func advance() {
        if index < cards.count - 1 {
            withAnimation(.easeInOut(duration: 0.2)) {
                index += 1
                isResolved = false
            }
        } else {
            isFinished = true
        }
    }
}

private struct DeckResultView: View {
    let result: DeckResult
    let accentColor: Color
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("🎉").font(.system(size: 56))
            Text("¡Mazo terminado!")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
            if result.graded > 0 {
                Text("\(result.correct)/\(result.graded) correctas")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.8))
            } else {
                Text("\(result.total) tarjetas revisadas")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
            Button("Cerrar", action: onClose)
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(accentColor, in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
