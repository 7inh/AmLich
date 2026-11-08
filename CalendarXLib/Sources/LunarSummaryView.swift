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
                Text("Vietnamese lunar calendar · UTC+7", bundle: .module)
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
