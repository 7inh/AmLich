import SwiftUI

public struct DailyQuoteView<Controls: View>: View {
    public let quote: DailyQuote
    public let compact: Bool
    private let controls: Controls

    public init(quote: DailyQuote, compact: Bool = false, @ViewBuilder controls: () -> Controls) {
        self.quote = quote
        self.compact = compact
        self.controls = controls()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 8) {
            HStack(spacing: 6) {
                Image(systemName: "quote.opening")
                Spacer(minLength: 0)
                controls
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Color.accentColor)

            Text(verbatim: quote.text)
                .font(.system(size: compact ? 12 : 13, design: .serif))
                .lineSpacing(compact ? 1 : 2)
                .lineLimit(compact ? 6 : 4)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .bottom) {
                Text(verbatim: "— " + quote.author)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
            }
        }
        .foregroundStyle(.primary)
        .accessibilityElement(children: .contain)
    }
}

extension DailyQuoteView where Controls == EmptyView {
    public init(quote: DailyQuote, compact: Bool = false) {
        self.init(quote: quote, compact: compact) { EmptyView() }
    }
}
