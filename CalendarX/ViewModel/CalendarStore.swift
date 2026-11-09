//
//  CalendarViewModel.swift
//  CalendarStore
//
//  Created by zm on 2024/12/25.
//

import CalendarXLib
import SwiftUI

/// How many moon-phase glyphs the month grid shows.
enum MoonPhaseMode: Int {
    case full, half, none

    var next: MoonPhaseMode {
        switch self {
        case .full: .half
        case .half: .none
        case .none: .full
        }
    }

    var icon: String {
        switch self {
        case .full: "moon.fill"
        case .half: "moonphase.first.quarter"
        case .none: "moon"
        }
    }

    /// SF Symbol for a lunar day (1...30), or nil when this mode hides it.
    func symbol(lunarDay: Int) -> String? {
        let keyDays = [1, 8, 15, 23]
        switch self {
        case .none: return nil
        case .half where !keyDays.contains(lunarDay): return nil
        default: break
        }
        let names = [
            "new.moon", "waxing.crescent", "first.quarter", "waxing.gibbous",
            "full.moon", "waning.gibbous", "last.quarter", "waning.crescent",
        ]
        let index = Int((Double(lunarDay - 1) / 29.53 * 8).rounded()) % 8
        return "moonphase." + names[index]
    }
}

@MainActor
class CalendarStore: ObservableObject {

    @AppStorage(CalendarStorageKey.weekday, store: .group)
    var weekday: AppWeekday = .monday

    @AppStorage(CalendarStorageKey.showEvents, store: .group)
    var showEvents: Bool = false

    @AppStorage(CalendarStorageKey.showLunar, store: .group)
    var showLunar: Bool = true

    @AppStorage(CalendarStorageKey.moonPhase, store: .group)
    var moonPhase: MoonPhaseMode = .none

    @AppStorage(CalendarStorageKey.showHolidays, store: .group)
    var showHolidays: Bool = true

    @AppStorage(CalendarStorageKey.showWeekNumbers, store: .group)
    var showWeekNumbers: Bool = false

    @AppStorage(CalendarStorageKey.keyboardShortcut, store: .group)
    var keyboardShortcut: Bool = true

}
