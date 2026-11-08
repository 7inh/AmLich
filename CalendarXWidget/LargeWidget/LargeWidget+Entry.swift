import CalendarXLib
import SwiftUI
import WidgetKit

extension LargeWidget {

    @dynamicMemberLookup
    struct Entry: TimelineEntry {
        let date: Date
        let displayedDate: Date
        let configuration: Provider.Intent

        init(date: Date = Date(), displayedDate: Date? = nil, configuration: Provider.Intent = .init()) {
            self.date = date
            self.displayedDate = displayedDate ?? date
            self.configuration = configuration
        }

        subscript<T>(dynamicMember keyPath: KeyPath<Provider.Intent, T>) -> T {
            get { configuration[keyPath: keyPath] }
        }
    }

}

extension LargeWidget.Entry {
    var showLunar: Bool {
        configuration.showLunar?.boolValue ?? true
    }

    var showEvents: Bool {
        configuration.showEvents?.boolValue ?? false
    }

    var showHolidays: Bool {
        configuration.showHolidays?.boolValue ?? true
    }
    
    var showWeekNumbers: Bool {
        configuration.showWeekNumbers?.boolValue ?? false
    }
}
