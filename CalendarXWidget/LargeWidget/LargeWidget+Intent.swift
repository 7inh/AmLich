import AppIntents
import CalendarXLib
import WidgetKit

extension LargeWidget {
    @MainActor
    enum Store {
        private static let defaults = UserDefaults.group ?? .standard
        private static var todayKey: String { Date().eventsKey }
        private static var offset: Int {
            get { defaults.string(forKey: "widget.browseDay") == todayKey ? defaults.integer(forKey: "widget.monthOffset") : 0 }
            set {
                defaults.set(todayKey, forKey: "widget.browseDay")
                defaults.set(newValue, forKey: "widget.monthOffset")
            }
        }
        static var date: Date {
            Calendar.gregorian.date(byAdding: .month, value: offset, to: Date().startOfMonth) ?? .now
        }
        static func lastMonth() { offset -= 1 }
        static func nextMonth() { offset += 1 }
        static func today() { offset = 0 }
    }

    @MainActor
    struct NextMonthIntent: AppIntent {
        nonisolated(unsafe) static var title: LocalizedStringResource = "Tháng sau"
        func perform() async throws -> some IntentResult {
            Store.nextMonth()
            WidgetCenter.shared.reloadTimelines(ofKind: "AmLich.Month")
            return .result()
        }
    }
    @MainActor
    struct LastMonthIntent: AppIntent {
        nonisolated(unsafe) static var title: LocalizedStringResource = "Tháng trước"
        func perform() async throws -> some IntentResult {
            Store.lastMonth()
            WidgetCenter.shared.reloadTimelines(ofKind: "AmLich.Month")
            return .result()
        }
    }
    @MainActor
    struct TodayIntent: AppIntent {
        nonisolated(unsafe) static var title: LocalizedStringResource = "Hôm nay"
        func perform() async throws -> some IntentResult {
            Store.today()
            WidgetCenter.shared.reloadTimelines(ofKind: "AmLich.Month")
            return .result()
        }
    }
}
