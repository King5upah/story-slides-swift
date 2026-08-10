# StorySlides (Swift)

Tap-to-advance story decks and graded card widgets for SwiftUI — the iOS
counterpart to [story-slides](https://github.com/King5upah/story-slides)
(the React version).

Two engines, one visual language (segmented progress bar, full-bleed dark
cards, tap zones, no autoplay timer):

- **`StoryDeckView`** — passive slides for anything you read: a lesson, a
  training plan, a diet, an onboarding flow. Slide types: `title`, `text`,
  `highlight`, `example`, `table`, `tip`, `cta`, `photo`.
- **`CardDeckView`** — graded/interactive cards for flashcards, quizzes,
  spaced-repetition-style decks. Widget types: `singleChoiceQuiz`,
  `multiChoiceQuiz`, `trueFalse`, `fillInBlank`, `flipCard`, `counter`,
  `rating`. Graded widgets block advancing until answered and roll up into
  a `DeckResult` (score) shown at the end.

## Install

Add as a Swift Package dependency:

```
https://github.com/King5upah/story-slides-swift
```

## Usage — StoryDeckView

```swift
import StorySlides

StoryDeckView(
    title: "Mi progreso",
    icon: "sparkles",
    accentColor: .orange,
    slides: [
        .title(icon: "💪", heading: "Hola", subheading: "Tu progreso hasta hoy"),
        .highlight(heading: "Peso", value: "77.9 kg", caption: "↓ 1.5 kg"),
        .cta(heading: "Sigue así", body: "Registra tu próximo estudio.", label: "Cerrar"),
    ],
    onExit: { /* dismiss */ }
)
```

## Usage — CardDeckView

```swift
import StorySlides

CardDeckView(
    title: "Vocabulario A1",
    icon: "text.book.closed.fill",
    accentColor: .green,
    cards: [
        BarajaCard(prompt: "Italiano", widget: .flipCard(front: "ciao", back: "hola")),
        BarajaCard(widget: .singleChoiceQuiz(
            question: "¿Cómo se dice \"gracias\" en italiano?",
            options: ["Ciao", "Grazie", "Acqua", "Prego"],
            correctIndex: 1,
            explanation: nil
        )),
    ],
    onFinish: { result in
        print("\(result.correct)/\(result.graded) correctas")
    }
)
```

## License

MIT
