import XCTest
@testable import CalendarXLib

final class VietnameseLunarCalendarTests: XCTestCase {
    func testTetAndVietnameseChineseDifference() {
        let fixtures = [
            (1985, 1, 21), (2007, 2, 17), // Vietnam differs from China in these years.
            (2023, 1, 22), (2024, 2, 10), (2025, 1, 29), (2026, 2, 17), (2027, 2, 6)
        ]
        for (year, month, day) in fixtures {
            let lunar = VietnameseLunarCalendar.convert(day: day, month: month, year: year)
            XCTAssertEqual(lunar.day, 1, "\(year)-\(month)-\(day)")
            XCTAssertEqual(lunar.month, 1, "\(year)-\(month)-\(day)")
            XCTAssertEqual(lunar.year, year)
            XCTAssertFalse(lunar.isLeapMonth)
        }
    }

    func testLeapMonthsAndMidAutumn() {
        for (year, month, day, ld, lm, leap) in [
            (2023, 3, 21, 30, 2, false), (2023, 3, 22, 1, 2, true),
            (2023, 4, 19, 29, 2, true), (2023, 4, 20, 1, 3, false),
            (2025, 7, 25, 1, 6, true), (2024, 9, 17, 15, 8, false),
            (2026, 2, 16, 29, 12, false)
        ] {
            let value = VietnameseLunarCalendar.convert(day: day, month: month, year: year)
            XCTAssertEqual(value.day, ld, "\(year)-\(month)-\(day)")
            XCTAssertEqual(value.month, lm)
            XCTAssertEqual(value.isLeapMonth, leap)
        }
    }

    func testCivilDateTimeZone() {
        var vietnam = Calendar(identifier: .gregorian)
        vietnam.timeZone = TimeZone(secondsFromGMT: 7 * 3600)!
        var utc = vietnam
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let instant = utc.date(from: DateComponents(year: 2024, month: 2, day: 9, hour: 20))!
        XCTAssertEqual(VietnameseLunarCalendar.convert(instant, calendar: vietnam).day, 1)
        XCTAssertEqual(VietnameseLunarCalendar.convert(instant, calendar: utc).month, 12)
    }

    func testConsecutiveDatesAcrossSupportedRange() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 7 * 3600)!
        var date = calendar.date(from: DateComponents(year: 1900, month: 1, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2101, month: 1, day: 1))!
        var previous = VietnameseLunarCalendar.convert(date, calendar: calendar)
        while date < end {
            date = calendar.date(byAdding: .day, value: 1, to: date)!
            let lunar = VietnameseLunarCalendar.convert(date, calendar: calendar)
            XCTAssertTrue((1...30).contains(lunar.day))
            XCTAssertTrue((1...12).contains(lunar.month))
            if lunar.day == 1 {
                XCTAssertTrue([29, 30].contains(previous.day))
                if lunar.isLeapMonth {
                    XCTAssertEqual(lunar.month, previous.month)
                    XCTAssertFalse(previous.isLeapMonth)
                } else {
                    XCTAssertEqual(lunar.month, previous.month % 12 + 1)
                }
                XCTAssertEqual(lunar.year, previous.year + (lunar.month == 1 && !lunar.isLeapMonth ? 1 : 0))
            } else {
                XCTAssertEqual(lunar.day, previous.day + 1)
                XCTAssertEqual(lunar.month, previous.month)
                XCTAssertEqual(lunar.year, previous.year)
                XCTAssertEqual(lunar.isLeapMonth, previous.isLeapMonth)
            }
            previous = lunar
        }
    }

    @MainActor
    func testVietnameseFestivalsAndLeapExclusion() {
        let calendar = Calendar.gregorian
        let store = FestivalStore()
        func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
            calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
        }
        XCTAssertTrue(store.all(date: date(2026, 2, 17)).contains("Tết Nguyên đán"))
        XCTAssertTrue(store.all(date: date(2026, 2, 16)).contains("Giao thừa"))
        XCTAssertTrue(store.all(date: date(2024, 9, 17)).contains("Tết Trung thu"))
        XCTAssertTrue(store.all(date: date(2026, 9, 2)).contains("Quốc khánh"))
        XCTAssertFalse(store.all(date: date(2023, 4, 5)).contains("Tết Nguyên tiêu"))
        XCTAssertEqual(VietnameseLunarCalendar.convert(day: 17, month: 2, year: 2026).yearName, "Bính Ngọ")
    }
}
