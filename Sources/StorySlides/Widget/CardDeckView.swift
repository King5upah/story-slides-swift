import SwiftUI

/// Runs a deck of `BarajaCard`s one at a time — graded widgets (quizzes,
/// true/false, fill-in-the-blank) must be answered before advancing;
/// ungraded ones (flip cards, stats) advance on tap. Ends on a score screen.
public struct CardDeckView: View {
    let title: String
    let icon: String
    let accentColor: Color
    let cards: [BarajaCard]
    let onExit: () -> Void
    let onFinish: (DeckResult) -> Void

    @State private var index = 0
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
                VStack(spacing: 0) {
                    header
                    ScrollView {
                        CardWidgetView(
                            prompt: cards[index].prompt,
                            widget: cards[index].widget,
                            accentColor: accentColor,
                            onFinished: { isCorrect in
                                if let isCorrect {
                                    gradedCount += 1
                                    if isCorrect { correctCount += 1 }
                                }
                                advance()
                            }
                        )
                        .id(cards[index].id)
                        .padding(24)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
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

    private func advance() {
        if index < cards.count - 1 {
            index += 1
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
