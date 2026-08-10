import SwiftUI
import UIKit

/// Full-screen, tap-to-advance story deck (Instagram-Stories-like UX):
/// segmented progress bar, full-bleed cards, tap zones — no autoplay timer.
public struct StoryDeckView: View {
    let title: String
    let icon: String
    let accentColor: Color
    let slides: [StorySlide]
    let onExit: () -> Void
    let onComplete: () -> Void

    @State private var index = 0

    public init(
        title: String,
        icon: String,
        accentColor: Color = .accentColor,
        slides: [StorySlide],
        onExit: @escaping () -> Void = {},
        onComplete: @escaping () -> Void = {}
    ) {
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
        self.slides = slides
        self.onExit = onExit
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if slides.indices.contains(index) {
                StorySlideContent(slide: slides[index], accentColor: accentColor)
                    .id(index)
                    .transition(.opacity)
            }

            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture { goBack() }
                Color.clear
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture { goForward() }
            }

            VStack(spacing: 0) {
                header
                Spacer()
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
                ForEach(slides.indices, id: \.self) { i in
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

    private func goBack() {
        withAnimation(.easeInOut(duration: 0.2)) {
            index = max(0, index - 1)
        }
    }

    private func goForward() {
        guard index < slides.count - 1 else {
            onComplete()
            onExit()
            return
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            index += 1
        }
    }
}

private struct StorySlideContent: View {
    let slide: StorySlide
    let accentColor: Color

    var body: some View {
        VStack {
            Spacer()
            content
            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var content: some View {
        switch slide {
        case let .title(icon, heading, subheading):
            VStack(spacing: 16) {
                Text(icon).font(.system(size: 56))
                Text(heading)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                if let subheading {
                    Text(subheading)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }

        case let .text(heading, body):
            VStack(alignment: .leading, spacing: 12) {
                if let heading {
                    Text(heading)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }
                Text(body)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case let .highlight(heading, value, caption):
            VStack(spacing: 10) {
                Text(heading.uppercased())
                    .font(.footnote.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(accentColor)
                Text(value)
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                if let caption {
                    Text(caption)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))

        case let .example(text):
            Text(text)
                .font(.title3.italic())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
                .padding(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentColor.opacity(0.6), lineWidth: 1)
                )

        case let .table(heading, rows):
            VStack(alignment: .leading, spacing: 14) {
                if let heading {
                    Text(heading)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }
                VStack(spacing: 0) {
                    ForEach(rows.indices, id: \.self) { i in
                        HStack {
                            Text(rows[i].label)
                                .foregroundStyle(.white.opacity(0.7))
                            Spacer()
                            Text(rows[i].value)
                                .foregroundStyle(.white)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .padding(.vertical, 10)
                        if i < rows.count - 1 {
                            Divider().overlay(.white.opacity(0.15))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case let .tip(text):
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(accentColor)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(18)
            .background(accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))

        case let .photo(imageData, caption):
            VStack(spacing: 12) {
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                if let caption {
                    Text(caption)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

        case let .cta(heading, body, label):
            VStack(spacing: 18) {
                Text(heading)
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                Text(body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.75))
                Text(label)
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(accentColor, in: Capsule())
            }
        }
    }
}
