import CalendarXLib
import SwiftUI
import WidgetKit

struct HomeView: View {
    @EnvironmentObject private var appStore: AppStore
    @EnvironmentObject private var calendarStore: CalendarStore
    @Environment(\.locale) private var locale

    @ObservedObject var viewModel: MainViewModel

    @AppStorage(DailyQuoteStore.advanceKey, store: .group) private var quoteAdvance = 0
    @AppStorage(CalendarStorageKey.moonPhase, store: .group) private var moonPhase: MoonPhaseMode = .none

    @State private var showSettings = false

    private let eventStore = AppEventStore()
    private let festivalStore = FestivalStore()

    private var calendar: Calendar {
        viewModel.calendar.firstWeekday = calendarStore.weekday.rawValue
        return viewModel.calendar
    }

    var body: some View {
        NavigationStack {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 20) {
                    calendarCard
                    detailColumn.frame(width: 340)
                }
                ScrollView {
                    VStack(spacing: 20) {
                        calendarCard
                        detailColumn
                    }
                }
            }
            .padding(20)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Âm Lịch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Cài đặt")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(appStore)
                    .environmentObject(calendarStore)
                    .environment(\.locale, locale)
                    .tint(appStore.accentColor)
                    .preferredColorScheme(appStore.colorScheme)
            }
        }
        .task { await refreshEventsAccessIfNeeded() }
    }

    // MARK: Calendar card

    private var calendarCard: some View {
        VStack(spacing: 12) {
            header
            weekdayRow
            grid
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var header: some View {
        HStack(spacing: 6) {
            Picker("", selection: $viewModel.date.month) {
                ForEach(Solar.minMonth...Solar.maxMonth, id: \.self) {
                    Text(viewModel.date.monthSymbol(index: $0, locale: locale)).tag($0)
                }
            }
            Picker("", selection: $viewModel.date.year) {
                ForEach(Solar.minYear...Solar.maxYear, id: \.self) { Text(String($0)).tag($0) }
            }
            Spacer()
            Button { moonPhase = moonPhase.next } label: {
                Image(systemName: moonPhase.icon).frame(width: 36, height: 36)
            }
            .accessibilityLabel("Hiển thị pha trăng")
            Button(action: viewModel.lastMonth) { Image(systemName: "chevron.left").frame(width: 36, height: 36) }
            Button(action: viewModel.reset) { Image(systemName: "circle").frame(width: 36, height: 36) }
            Button(action: viewModel.nextMonth) { Image(systemName: "chevron.right").frame(width: 36, height: 36) }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .font(.title3)
    }

    private var weekdayRow: some View {
        let dates = calendar.generateDates(for: viewModel.date)
        return HStack(spacing: 0) {
            if calendarStore.showWeekNumbers { Text("#").frame(width: 28) }
            ForEach(dates.prefix(Solar.daysInWeek), id: \.self) {
                Text($0.shortWeekday(locale: locale))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle($0.inWeekend ? .secondary : .primary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        let dates = calendar.generateDates(for: viewModel.date)
        let eventsMap = eventStore.generateEventsMap(dates)
        let rows = stride(from: 0, to: dates.count, by: Solar.daysInWeek).map {
            Array(dates[$0..<min($0 + Solar.daysInWeek, dates.count)])
        }
        return VStack(spacing: 4) {
            ForEach(rows, id: \.self) { week in
                HStack(spacing: 4) {
                    if calendarStore.showWeekNumbers {
                        Text(week[0].weekOfYearString(calendar: calendar))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 28)
                    }
                    ForEach(week, id: \.self) { date in
                        cell(date, hasEvents: !(eventsMap[date.eventsKey] ?? []).isEmpty)
                    }
                }
            }
        }
    }

    private func cell(_ date: AppDate, hasEvents: Bool) -> some View {
        let selected = Calendar.current.isDate(date, inSameDayAs: viewModel.selected)
        let inMonth = viewModel.date.inSameMonth(as: date)
        let isFestival = calendarStore.showHolidays && !festivalStore.tiaoxiu(date: date).isOrdinary
        let numberColor: Color = isFestival ? .accentColor : (date.inWeekend ? .secondary : .primary)
        let lunarDay = date.vietnameseLunarDate.day

        return Button {
            viewModel.selected = date
            if !inMonth { viewModel.date = date }
        } label: {
            VStack(spacing: 2) {
                Text(date.title)
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(numberColor)
                if calendarStore.showLunar {
                    HStack(spacing: 2) {
                        if let symbol = moonPhase.symbol(lunarDay: lunarDay) {
                            Image(systemName: symbol).font(.system(size: 9))
                        }
                        Text(festivalStore.display(date: date)).font(.caption2)
                    }
                    .foregroundStyle(isFestival ? Color.accentColor : .secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 58)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selected ? Color.accentColor.opacity(0.18) : .clear)
            }
            .overlay {
                if date.inToday {
                    RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.accentColor, lineWidth: 1.5)
                }
            }
            .overlay(alignment: .topTrailing) {
                if hasEvents && calendarStore.showEvents {
                    Circle().fill(Color.accentColor).frame(width: 6, height: 6).padding(7)
                }
            }
            .opacity(inMonth ? 1 : 0.35)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(date.day)/\(date.month), âm lịch \(date.lunarDay)/\(date.lunarMonth)")
    }

    // MARK: Detail column

    private var detailColumn: some View {
        let selected = viewModel.selected
        let festivals = festivalStore.all(date: selected)
        let events = eventStore.generateEventsMap([selected])[selected.eventsKey] ?? []
        let lunar = selected.vietnameseLunarDate

        return VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                LunarSummaryView(date: selected)
                Text("Ngày \(selected.canChiDay) · Tháng \(lunar.monthName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if festivals.isNotEmpty {
                    Text(festivals.joined(separator: " · "))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            if calendarStore.showEvents && events.isNotEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sự kiện").font(.headline)
                    ForEach(events, id: \.eventIdentifier) { event in
                        HStack(alignment: .top, spacing: 8) {
                            Circle().fill(event.color).frame(width: 8, height: 8).padding(.top, 6)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title ?? "").font(.subheadline)
                                Text(event.isAllDay ? "Cả ngày" : "\(event.startDate.eventTimeline) – \(event.endDate.eventTimeline)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }

            DailyQuoteView(quote: DailyQuoteStore.quote(for: Date(), advance: quoteAdvance)) {
                Button {
                    quoteAdvance = DailyQuoteStore.shuffle()
                    WidgetCenter.shared.reloadAllTimelines()
                } label: {
                    Image(systemName: "shuffle").padding(6).contentShape(Rectangle())
                }
                .accessibilityLabel("Đổi câu danh ngôn")
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private func refreshEventsAccessIfNeeded() async {
        guard calendarStore.showEvents else { return }
        let authorizer = Authorizer()
        if authorizer.eventsStatus == .notRequested {
            calendarStore.showEvents = await authorizer.requestEventsAuthorization()
        }
    }
}
