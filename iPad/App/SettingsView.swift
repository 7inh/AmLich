import CalendarXLib
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appStore: AppStore
    @EnvironmentObject private var calendarStore: CalendarStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage(CalendarStorageKey.moonPhase, store: .group) private var moonPhase: MoonPhaseMode = .none

    @State private var eventsDenied = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Giao diện") {
                    Picker("Chủ đề", selection: $appStore.theme) {
                        ForEach(Theme.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    accentGrid
                }

                Section("Lịch") {
                    Picker("Bắt đầu tuần vào", selection: calendarStore.$weekday) {
                        ForEach(AppWeekday.allCases, id: \.self) { Text($0.symbol(locale: locale)).tag($0) }
                    }
                    Toggle("Hiển thị âm lịch", isOn: calendarStore.$showLunar)
                    Picker("Pha trăng", selection: $moonPhase) {
                        Text("Tất cả").tag(MoonPhaseMode.full)
                        Text("Ngày chính").tag(MoonPhaseMode.half)
                        Text("Tắt").tag(MoonPhaseMode.none)
                    }
                    .pickerStyle(.segmented)
                    Toggle("Hiển thị ngày lễ", isOn: calendarStore.$showHolidays)
                    Toggle("Hiển thị số tuần", isOn: calendarStore.$showWeekNumbers)
                    Toggle("Hiển thị sự kiện", isOn: eventsBinding)
                }

                Section("Ngôn ngữ") {
                    Picker("Ngôn ngữ", selection: $appStore.language) {
                        ForEach(Language.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                }

                Section("Giới thiệu") {
                    LabeledContent("Phiên bản", value: Bundle.appVersionName)
                    Link("Mã nguồn Âm Lịch", destination: URL(string: AppLink.gitHub)!)
                    Link("Phát triển từ CalendarX · AGPL-3.0", destination: URL(string: "https://github.com/ZzzM/CalendarX")!)
                }
            }
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Xong") { dismiss() } }
            }
            .alert("Chưa được cấp quyền Lịch", isPresented: $eventsDenied) {
                Button("Mở Cài đặt") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
                Button("Để sau", role: .cancel) {}
            } message: {
                Text("Cho phép truy cập Lịch trong Cài đặt hệ thống để hiện sự kiện.")
            }
        }
    }

    private var eventsBinding: Binding<Bool> {
        Binding {
            calendarStore.showEvents
        } set: { value in
            guard value else { calendarStore.showEvents = false; return }
            let authorizer = Authorizer()
            switch authorizer.eventsStatus {
            case .granted: calendarStore.showEvents = true
            case .notRequested:
                Task { calendarStore.showEvents = await authorizer.requestEventsAuthorization() }
            default: eventsDenied = true
            }
        }
    }

    private var accentGrid: some View {
        let isDark = colorScheme == .dark
        let colors = isDark ? Bundle.darkAccent : Bundle.lightAccent
        let selected = isDark ? appStore.appearance.darkAccent : appStore.appearance.lightAccent
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 32), spacing: 8), count: 8), spacing: 8) {
            ForEach(colors, id: \.self) { info in
                Button {
                    if isDark { appStore.appearance.darkAccent = info } else { appStore.appearance.lightAccent = info }
                } label: {
                    Circle()
                        .fill(Color(hex: info.hex) ?? .accentColor)
                        .frame(height: 32)
                        .overlay {
                            if info == selected { Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white) }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(info.name(from: locale))
            }
        }
        .padding(.vertical, 4)
    }
}
