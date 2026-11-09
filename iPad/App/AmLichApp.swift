import CalendarXLib
import SwiftUI
import WidgetKit

@main
struct AmLichApp: App {
    @StateObject private var appStore = AppStore()
    @StateObject private var calendarStore = CalendarStore()
    @StateObject private var viewModel = MainViewModel()

    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: viewModel)
                .environmentObject(appStore)
                .environmentObject(calendarStore)
                .environment(\.locale, appStore.locale)
                .tint(appStore.accentColor)
                .preferredColorScheme(appStore.colorScheme)
        }
    }
}
