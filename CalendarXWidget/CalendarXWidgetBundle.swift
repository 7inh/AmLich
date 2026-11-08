//
//  CalendarXWidgetBundle.swift
//  CalendarXWidget
//
//  Created by zm on 2023/12/15.
//
import SwiftUI
import WidgetKit
import CalendarXLib

@main
struct CalendarXWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        LargeWidget()
        LunarDayWidget()
    }
}

struct LunarDayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AmLich.Day", provider: LunarDayProvider()) { entry in
            LunarDayEntryView(entry: entry)
        }
        .configurationDisplayName("Ngày âm lịch")
        .description("Ngày âm hôm nay, năm Can Chi và ngày lễ Việt Nam.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct LunarDayEntry: TimelineEntry {
    let date: Date
}

struct LunarDayProvider: TimelineProvider {
    func placeholder(in context: Context) -> LunarDayEntry { .init(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (LunarDayEntry) -> Void) {
        completion(.init(date: .now))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<LunarDayEntry>) -> Void) {
        let now = Date()
        let entries = (0..<7).map { offset in
            LunarDayEntry(date: offset == 0 ? now : Calendar.gregorian.date(byAdding: .day, value: offset - 1, to: now.startOfTomorrow)!)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct LunarDayEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LunarDayEntry

    var body: some View {
        HStack(spacing: 14) {
            LunarSummaryView(date: entry.date, compact: true)
            if family == .systemMedium {
                Rectangle().fill(.secondary.opacity(0.15)).frame(width: 1)
                VStack(alignment: .leading, spacing: 10) {
                    Text(entry.date, format: .dateTime.weekday(.wide).locale(.vi))
                        .font(.caption.weight(.semibold))
                    Text("Ngày " + entry.date.canChiDay)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(FestivalStore().all(date: entry.date).prefix(2), id: \.self) { festival in
                        Text(festival)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accentColor(Color(lightHex: "B13D36", darkHex: "F19B88"))
        .environment(\.locale, .vi)
        .containerBackground(for: .widget) { Color(lightHex: "FBF8F1", darkHex: "242521") }
        .widgetURL(URL(string: "amlich://today"))
    }
}
