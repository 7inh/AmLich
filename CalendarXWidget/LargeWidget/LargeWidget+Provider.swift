import CalendarXLib
import WidgetKit

extension LargeWidget {
    typealias Intent = WidgetConfigurationIntent

    @MainActor
    struct Provider: @preconcurrency IntentTimelineProvider {
        func placeholder(in context: Context) -> Entry { .init() }

        func getSnapshot(for configuration: Intent, in context: Context, completion: @escaping (Entry) -> Void) {
            completion(.init(configuration: configuration))
        }

        func getTimeline(for configuration: Intent, in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
            let now = Date()
            // Future entries retain real timeline timestamps, even while browsing another month.
            let entries = (0..<7).map { offset -> Entry in
                let timestamp = offset == 0 ? now : Calendar.gregorian.date(byAdding: .day, value: offset - 1, to: now.startOfTomorrow)!
                return Entry(date: timestamp, displayedDate: offset == 0 ? Store.date : timestamp, configuration: configuration)
            }
            completion(Timeline(entries: entries, policy: .atEnd))
        }
    }
}
