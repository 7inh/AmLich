import XCTest
@testable import CalendarXLib

@MainActor
final class DailyQuoteTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        return calendar
    }

    func testCatalogIsAvailableOfflineAndHasSources() {
        let quotes = DailyQuoteStore.quotes
        XCTAssertEqual(quotes.count, 1000)
        XCTAssertEqual(Set(quotes.map(\.id)).count, quotes.count)
        XCTAssertEqual(Set(quotes.map { $0.text.lowercased() }).count, quotes.count)
        for quote in quotes {
            XCTAssertTrue((40...130).contains(quote.text.count), quote.id)
            XCTAssertFalse(quote.author.isEmpty)
            XCTAssertEqual(quote.sourceURL.scheme, "https")
            XCTAssertEqual(quote.sourceURL.host, "github.com")
        }
    }

    func testEntireShuffledDeckIsUsedBeforeRepeating() {
        let quotes = DailyQuoteStore.quotes
        let deck = QuoteDeck(quotes: quotes)
        let cycle = (0..<quotes.count).map { deck.quote(dayOffset: $0).id }
        XCTAssertEqual(Set(cycle), Set(quotes.map(\.id)))
        XCTAssertNotEqual(cycle, quotes.map(\.id))
        XCTAssertEqual(deck.quote(dayOffset: 0), deck.quote(dayOffset: quotes.count))
        XCTAssertNotEqual(deck.quote(dayOffset: -1), deck.quote(dayOffset: 0))
    }

    func testIndependentProcessesCanReproduceSameOrder() {
        let app = QuoteDeck(quotes: DailyQuoteStore.quotes)
        let widget = QuoteDeck(quotes: DailyQuoteStore.quotes)
        for offset in [-8000, -1, 0, 17, 365, 999, 1000, 8000, Int.min, Int.max] {
            XCTAssertEqual(app.quote(dayOffset: offset), widget.quote(dayOffset: offset))
        }
        let anotherOrder = QuoteDeck(quotes: DailyQuoteStore.quotes, seed: 42)
        XCTAssertNotEqual(
            (0..<20).map { app.quote(dayOffset: $0).id },
            (0..<20).map { anotherOrder.quote(dayOffset: $0).id }
        )
    }

    func testSameQuoteThroughoutDayAndNextQuoteAtMidnight() {
        let morning = calendar.date(from: DateComponents(year: 2026, month: 11, day: 8))!
        let evening = calendar.date(from: DateComponents(year: 2026, month: 11, day: 8, hour: 23, minute: 59))!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: morning)!
        let first = DailyQuoteStore.quote(for: morning, calendar: calendar, advance: 0)
        XCTAssertEqual(first, DailyQuoteStore.quote(for: evening, calendar: calendar, advance: 0))
        XCTAssertNotEqual(first, DailyQuoteStore.quote(for: tomorrow, calendar: calendar, advance: 0))
        XCTAssertEqual(
            DailyQuoteStore.quote(for: morning, calendar: calendar, advance: 1),
            DailyQuoteStore.quote(for: tomorrow, calendar: calendar, advance: 0)
        )
    }

    func testMidnightAcrossDaylightSavingTime() {
        var newYork = calendar
        newYork.timeZone = TimeZone(identifier: "America/New_York")!
        let before = newYork.date(from: DateComponents(year: 2026, month: 3, day: 8))!
        let after = newYork.date(from: DateComponents(year: 2026, month: 3, day: 9))!
        XCTAssertEqual(after.timeIntervalSince(before), 23 * 3600)
        XCTAssertEqual(QuoteDeck.dayOffset(for: after, calendar: newYork) - QuoteDeck.dayOffset(for: before, calendar: newYork), 1)
    }

    func testShufflePersistsAndFutureDaysContinueFromIt() {
        let name = "vn.7inh.amlich.tests.quotes." + UUID().uuidString
        let appSettings = UserDefaults(suiteName: name)!
        defer { appSettings.removePersistentDomain(forName: name) }
        let date = calendar.date(from: DateComponents(year: 2026, month: 11, day: 8))!
        var seen: Set<String> = []
        for _ in 0..<1000 {
            let advance = appSettings.integer(forKey: DailyQuoteStore.advanceKey)
            seen.insert(DailyQuoteStore.quote(for: date, calendar: calendar, advance: advance).id)
            DailyQuoteStore.shuffle(defaults: appSettings)
        }
        XCTAssertEqual(seen.count, 1000)
        XCTAssertEqual(appSettings.integer(forKey: DailyQuoteStore.advanceKey), 0)
        XCTAssertEqual(DailyQuoteStore.shuffle(defaults: appSettings), 1)
        let widgetSettings = UserDefaults(suiteName: name)!
        XCTAssertEqual(widgetSettings.integer(forKey: DailyQuoteStore.advanceKey), 1)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: date)!
        XCTAssertNotEqual(
            DailyQuoteStore.quote(for: date, calendar: calendar, advance: 1),
            DailyQuoteStore.quote(for: tomorrow, calendar: calendar, advance: 1)
        )
    }
}
