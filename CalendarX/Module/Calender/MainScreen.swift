//
//  MainScreen.swift
//  CalendarX
//
//  Created by zm on 2022/1/26.
//

import CalendarXLib
import SwiftUI
import WidgetKit

struct MainScreen: View {

    @EnvironmentObject
    private var appStore: AppStore

    @EnvironmentObject
    private var calendarStore: CalendarStore

    @EnvironmentObject
    private var router: Router

    @ObservedObject
    var viewModel: MainViewModel

    @AppStorage(DailyQuoteStore.advanceKey, store: .group)
    private var quoteAdvance = 0

    private var calendar: Calendar {
        viewModel.calendar.firstWeekday = calendarStore.weekday.rawValue
        return viewModel.calendar
    }

    // Read directly so the view refreshes on change (AppStorage inside CalendarStore doesn't publish).
    @AppStorage(CalendarStorageKey.moonPhase, store: .group)
    private var moonPhase: MoonPhaseMode = .none

    private let eventStore = AppEventStore()

    private let festivalStore = FestivalStore()

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            CalendarView(
                date: viewModel.date,
                calendar: calendar,
                eventStore: eventStore,
                interval: viewModel.interval,
                showWeekNumbers: calendarStore.showWeekNumbers,
                title: title,
                subtitle: subtitle,
                leading: leading,
                element: element
            )
            .frame(maxWidth: .infinity, alignment: .top)

            detailPane
                .frame(width: .detailWidth)
        }
        .padding()
    }

    private var detailPane: some View {
        let selected = viewModel.selected
        let events = eventStore.generateEventsMap([selected])[selected.eventsKey] ?? []
        let lunar = selected.vietnameseLunarDate

        return VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    LunarSummaryView(date: selected)
                    Button {
                        router.push(.settings)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.borderless)
                    .help("Cài đặt")
                }
                Text("Ngày \(selected.canChiDay) · Tháng \(lunar.monthName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            if calendarStore.showEvents && events.isNotEmpty {
                EventsView(events: events, showEvents: true)
                    .frame(maxHeight: 90)
            }

            DailyQuoteView(quote: DailyQuoteStore.quote(for: Date(), advance: quoteAdvance)) {
                Button {
                    quoteAdvance = DailyQuoteStore.shuffle()
                    WidgetCenter.shared.reloadAllTimelines()
                } label: {
                    Image(systemName: "shuffle")
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .help("Đổi câu danh ngôn")
                .accessibilityLabel("Đổi câu danh ngôn")
            }
            .padding(12)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func title() -> some View {
        HStack(spacing: 0) {
            MonthYearPicker(date: $viewModel.date, tint: appStore.accentColor)
                .focusDisabled()

            Spacer(minLength: 4)

            HStack(spacing: 2) {
                Button {
                    moonPhase = moonPhase.next
                } label: {
                    Image(systemName: moonPhase.icon)
                        .frame(width: 26, height: 22)
                        .contentShape(Rectangle())
                }
                .help("Hiển thị pha trăng")
                Button(action: viewModel.lastMonth) {
                    Image(systemName: "chevron.left").frame(width: 26, height: 22).contentShape(Rectangle())
                }
                Button(action: viewModel.reset) {
                    Image(systemName: "circle").frame(width: 26, height: 22).contentShape(Rectangle())
                }
                Button(action: viewModel.nextMonth) {
                    Image(systemName: "chevron.right").frame(width: 26, height: 22).contentShape(Rectangle())
                }
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .fixedSize()
        }
        .background {
            // Invisible keyboard-shortcut targets must not take part in the header layout.
            if calendarStore.keyboardShortcut {
                Group {
                    KeyboardShortcutButton(key: .leftArrow, action: viewModel.lastMonth)
                    KeyboardShortcutButton(key: .space, action: viewModel.reset)
                    KeyboardShortcutButton(key: .rightArrow, action: viewModel.nextMonth)
                    KeyboardShortcutButton(key: .upArrow, action: viewModel.lastYear)
                    KeyboardShortcutButton(key: .downArrow, action: viewModel.nextYear)
                }
                .frame(width: 0, height: 0)
                .opacity(0)
            }
        }
    }

    private func subtitle(_ dates: [AppDate]) -> some View {
        ForEach(dates, id: \.self) {
            Text($0.shortWeekday(locale: appStore.locale))
                .appForeground($0.inWeekend ? .appSecondary : .appPrimary)
                .sideLength(30)
        }
    }

    private func leading(_ dates: [AppDate], spacing: CGFloat) -> some View {
        VStack(spacing: spacing) {
            Text("#")
                .frame(width: 15, height: 30)
                .appForeground(.accentColor)
            ForEach(dates, id: \.self) {
                Text($0.weekOfYearString(calendar: calendar))
                    .font(.system(size: 7, weight: .bold))
                    .frame(width: 15, height: 40)
                    .appForeground(.accentColor)
            }
        }
    }

    @ViewBuilder
    private func element(_ appDate: AppDate, events: [AppEvent]) -> some View {

        let tiaoxiu = festivalStore.tiaoxiu(date: appDate)
        let tiaoxiuColor: Color = tiaoxiu.isXiu ? .offBackground : .workBackground
        let subtitle = festivalStore.display(date: appDate)
        let showHolidays = !tiaoxiu.isOrdinary && calendarStore.showHolidays
        let showEvents = events.isNotEmpty && calendarStore.showEvents
        let showLunar = calendarStore.showLunar
        let defaultColor: Color = appDate.inWeekend ? .appSecondary : .appPrimary
        let inSameMonth = viewModel.date.inSameMonth(as: appDate)

        ScacleButton {
            viewModel.selected = appDate
            if !viewModel.date.inSameMonth(as: appDate) { viewModel.date = appDate }
        } label: {
            ZStack {
                if Calendar.current.isDate(appDate, inSameDayAs: viewModel.selected) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.accentColor.opacity(0.18))
                }
                if appDate.inToday {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.accentColor, lineWidth: 1)
                }

                if showHolidays {
                    tiaoxiuColor.clipShape(.rect(cornerRadius: 4))
                    Text(tiaoxiu.description)
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .offset(x: -14, y: -14)
                        .appForeground(tiaoxiu.isXiu ? .accentColor : .appSecondary)
                }

                if showEvents {
                    Circle()
                        .size(width: 5, height: 5)
                        .appForeground(.accentColor)
                        .offset(x: 32, y: 3)
                }

                VStack {
                    Text(appDate.title)
                        .font(.title3.monospacedDigit())
                        .appForeground(showHolidays ? tiaoxiu.isXiu ? .accentColor : defaultColor : defaultColor)
                    if showLunar {
                        HStack(spacing: 2) {
                            if let symbol = moonPhase.symbol(lunarDay: appDate.vietnameseLunarDate.day) {
                                Image(systemName: symbol).font(.system(size: 8))
                            }
                            Text(subtitle)
                                .font(.caption2.weight(.regular))
                        }
                        .appForeground(showHolidays ? tiaoxiu.isXiu ? .accentColor : .appSecondary : .appSecondary)
                    }
                }
            }
            .opacity(inSameMonth ? 1 : 0.3)
            .sideLength(40)
            .accessibilityLabel("\(appDate.day)/\(appDate.month), âm lịch \(appDate.lunarDay)/\(appDate.lunarMonth)")
            .help(festivalStore.all(date: appDate).joined(separator: ", "))
        }
    }
}

struct MonthYearPicker: View {

    @Environment(\.locale)
    private var locale

    @Binding
    var date: Date

    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Picker("", selection: $date.month) {
                ForEach(Solar.minMonth...Solar.maxMonth, id: \.self) {
                    Text(date.monthSymbol(index: $0, locale: locale)).tag($0)
                }
            }
            Picker("", selection: $date.year) {
                ForEach(Solar.minYear...Solar.maxYear, id: \.self) {
                    Text(String($0)).tag($0)
                }
            }
        }
        .pickerStyle(.menu)
        .buttonStyle(.borderless)
        .labelsHidden()
        .fixedSize()
        .tint(tint)
    }
}

struct CalendarView<Title: View, Subtitle: View, Leading: View, Element: View>: View {

    private let date: AppDate, calendar: Calendar, eventStore: AppEventStore, interval: TimeInterval

    private let showWeekNumbers: Bool

    private let title: () -> Title
    private let subtitle: ([AppDate]) -> Subtitle
    private let leading: ([AppDate], CGFloat) -> Leading
    private let element: (AppDate, [AppEvent]) -> Element

    init(
        date: AppDate,
        calendar: Calendar,
        eventStore: AppEventStore,
        interval: TimeInterval,
        showWeekNumbers: Bool,
        @ViewBuilder title: @escaping () -> Title,
        @ViewBuilder subtitle: @escaping ([AppDate]) -> Subtitle,
        @ViewBuilder leading: @escaping ([AppDate], CGFloat) -> Leading,
        @ViewBuilder element: @escaping (AppDate, [AppEvent]) -> Element
    ) {
        self.date = date
        self.calendar = calendar
        self.eventStore = eventStore
        self.interval = interval

        self.showWeekNumbers = showWeekNumbers
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.element = element
    }

    var body: some View {
        let dates = calendar.generateDates(for: date)
        let spacing = dates.count > Solar.minDates ? 0.5 : 8.5
        let eventsMap = eventStore.generateEventsMap(dates)

        let leadingDates = dates.striding(by: Solar.daysInWeek).map(\.self)
        let subtitleDates = dates.prefix(Solar.daysInWeek).map(\.self)
        let columns = Array(
            repeating: GridItem(.fixed(30), spacing: showWeekNumbers ? 8 : 10),
            count: Solar.daysInWeek
        )

        VStack {

            title()

            LazyHStack {

                if showWeekNumbers {
                    leading(leadingDates, spacing)
                }

                LazyVGrid(columns: columns, spacing: spacing) {

                    subtitle(subtitleDates)

                    ForEach(dates, id: \.self) { appDate in
                        element(appDate, eventsMap[appDate.eventsKey] ?? [])
                    }
                }

            }

        }

    }
}
