import SwiftUI

/// The same date summary is used by the menu-bar app and the daily widgets.
public struct LunarSummaryView: View {
    public let date: Date
    public let compact: Bool

    public init(date: Date, compact: Bool = false) {
        self.date = date
        self.compact = compact
    }

    public var body: some View {
        let lunar = date.vietnameseLunarDate
        VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            HStack {
                Image(systemName: "moon.stars.fill")
                Text("Vietnamese lunar calendar", bundle: .module)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .foregroundStyle(Color.accentColor)

            HStack(alignment: .center, spacing: compact ? 12 : 16) {
                Text("\(lunar.day)")
                    .font(.system(size: compact ? 46 : 52, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tháng \(lunar.month)" + (lunar.isLeapMonth ? " nhuận" : ""))
                        .font(.system(size: compact ? 13 : 16, weight: .semibold))
                    Text(lunar.yearName)
                        .font(.system(size: compact ? 12 : 14))
                        .foregroundStyle(.secondary)
                    if !compact {
                        Text(date, format: .dateTime.weekday(.wide).day().month().year().locale(.vi))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            if compact {
                Text(date, format: .dateTime.day().month().year().locale(.vi))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.primary)
        .accessibilityElement(children: .combine)
    }
}

/// Shared by WidgetKit and the native preview renderer.
public struct LunarDayContentView<Controls: View>: View {
    public let date: Date
    public let quote: DailyQuote
    public let showQuote: Bool
    private let controls: Controls

    public init(date: Date, quote: DailyQuote, showQuote: Bool, @ViewBuilder controls: () -> Controls) {
        self.date = date
        self.quote = quote
        self.showQuote = showQuote
        self.controls = controls()
    }

    public var body: some View {
        HStack(spacing: 12) {
            if showQuote {
                dateStamp
                    .frame(width: 104, alignment: .leading)
                Rectangle().fill(.secondary.opacity(0.15)).frame(width: 1)
                DailyQuoteView(quote: quote, compact: true) { controls }
            } else {
                LunarSummaryView(date: date, compact: true)
            }
        }
    }

    private var dateStamp: some View {
        let lunar = date.vietnameseLunarDate
        return VStack(alignment: .leading, spacing: 6) {
            Label("ÂM LỊCH", systemImage: "moon.stars.fill")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(lunar.day)")
                    .font(.system(size: 44, weight: .light, design: .rounded))
                    .monospacedDigit()
                Text("/\(lunar.month)" + (lunar.isLeapMonth ? "N" : ""))
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
            }
            Text(lunar.yearName)
                .font(.system(size: 12, weight: .semibold))
            Text(date, format: .dateTime.day().month().year().locale(.vi))
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(.primary)
    }
}
