//
//  MainViewModel.swift
//  CalendarX
//
//  Created by zm on 2022/1/27.
//

import CalendarXLib
import SwiftUI

@MainActor
class MainViewModel: ObservableObject {
 
    @Published
    var interval: TimeInterval

    @Published
    var date: Date

    @Published
    var selected = Date()
    
    var calendar: Calendar = .gregorian

    init() {
        date = Date()
        interval = Date().timeIntervalSince1970
        NotificationCenter.default
            .publisher(for: .EKEventStoreChanged)
            .map { _ in Date().timeIntervalSince1970 }
            .assign(to: &$interval)

        NotificationCenter.default
            .publisher(for: .calendarDayChanged)
            .map { _ in Date() }
            .assign(to: &$date)

    }

    func lastMonth() {
        guard date.year > Solar.minYear || date.month > 1 else { return }
        date.lastMonth()
    }

    func nextMonth() {
        guard date.year < Solar.maxYear || date.month < 12 else { return }
        date.nextMonth()
    }

    func lastYear() {
        guard date.year > Solar.minYear else { return }
        date.lastYear()
    }

    func nextYear() {
        guard date.year < Solar.maxYear else { return }
        date.nextYear()
    }

    func reset() {
        date = Date()
        selected = Date()
    }

}

