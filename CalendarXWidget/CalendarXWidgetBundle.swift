//
//  CalendarXWidgetBundle.swift
//  CalendarXWidget
//
//  Created by zm on 2023/12/15.
//
import SwiftUI
import WidgetKit
import CalendarXLib
import AppIntents

@main
struct CalendarXWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        LargeWidget()
        LunarDayWidget()
        DailyQuoteWidget()
    }
}

struct LunarDayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AmLich.Day", provider: LunarDayProvider()) { entry in
            LunarDayEntryView(entry: entry)
        }
        .configurationDisplayName("Ngày âm lịch")
        .description("Ngày âm hôm nay, năm Can Chi và danh ngôn có nút Shuffle.")
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
    @AppStorage(DailyQuoteStore.advanceKey, store: .group) private var quoteAdvance = 0
    let entry: LunarDayEntry

    var body: some View {
        LunarDayContentView(
            date: entry.date,
            quote: DailyQuoteStore.quote(for: entry.date, advance: quoteAdvance),
            showQuote: family == .systemMedium
        ) {
            Button(intent: ShuffleQuoteIntent()) {
                Image(systemName: "shuffle").padding(3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Đổi câu danh ngôn")
        }
        .accentColor(Color(lightHex: "B13D36", darkHex: "F19B88"))
        .environment(\.locale, .vi)
        .containerBackground(for: .widget) { Color(lightHex: "FBF8F1", darkHex: "242521") }
        .widgetURL(URL(string: "amlich://today"))
    }
}

struct DailyQuoteWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AmLich.Quote", provider: LunarDayProvider()) { entry in
            DailyQuoteEntryView(entry: entry)
        }
        .configurationDisplayName("Mỗi ngày một câu")
        .description("Danh ngôn tiếng Việt, xáo trộn mỗi ngày hoặc bấm Shuffle để đổi câu.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DailyQuoteEntryView: View {
    @AppStorage(DailyQuoteStore.advanceKey, store: .group) private var quoteAdvance = 0
    let entry: LunarDayEntry

    var body: some View {
        DailyQuoteView(quote: DailyQuoteStore.quote(for: entry.date, advance: quoteAdvance), compact: true) {
            Button(intent: ShuffleQuoteIntent()) {
                Image(systemName: "shuffle").padding(3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Đổi câu danh ngôn")
        }
        .accentColor(Color(lightHex: "B13D36", darkHex: "F19B88"))
        .containerBackground(for: .widget) { Color(lightHex: "FBF8F1", darkHex: "242521") }
        .widgetURL(URL(string: "amlich://today"))
    }
}

@MainActor
struct ShuffleQuoteIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Đổi câu danh ngôn"

    func perform() async throws -> some IntentResult {
        DailyQuoteStore.shuffle()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
