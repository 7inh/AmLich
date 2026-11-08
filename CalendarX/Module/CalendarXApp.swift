//
//  CalendarXApp.swift
//  CalendarX
//
//  Created by zm on 2021/12/1.
//

import CalendarXLib
import SwiftUI
import WidgetKit

extension EnvironmentValues {
    @Entry
    var authorizer = Authorizer()
}

@main
struct CalendarXApp: App {
    @NSApplicationDelegateAdaptor(CalendarXDelegate.self)
    private var delegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class CalendarXDelegate: NSObject & NSApplicationDelegate {

    private var menubarController: MenubarController?

    func applicationWillFinishLaunching(_ notification: Notification) {
        if ProcessInfo.processInfo.arguments.contains("--render-previews") { return }
        NSRunningApplication
            .runningApplications(withBundleIdentifier: Bundle.identifier)
            .filter(\.isFinishedLaunching)
            .forEach { $0.terminate() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {

        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--render-previews"), arguments.indices.contains(index + 1) {
            renderPreviews(at: URL(fileURLWithPath: arguments[index + 1], isDirectory: true))
            return
        }
        #endif

        let appStore = AppStore()
        let menubarStore = MenubarStore()
        let calendarStore = CalendarStore()
        let router = Router()
        let dialog = Dialog()
        let authorizer = Authorizer()
        let updater = Updater(appStore: appStore)

        bootstrap(calendarStore: calendarStore, authorizer: authorizer, updater: updater)

        let rootScreen = RootScreen(updater: updater)
            .environment(\.authorizer, authorizer)
            .environmentObject(appStore)
            .environmentObject(menubarStore)
            .environmentObject(calendarStore)
            .environmentObject(router)
            .environmentObject(dialog)
        let popover = MenubarPopover(router, rootScreen: rootScreen)

        menubarController = MenubarController(appStore: appStore, menubarStore: menubarStore, popover: popover)

        if !ProcessInfo.processInfo.arguments.contains("--background") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.menubarController?.showCalendar()
            }
        }

    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        menubarController?.showCalendar()
        return false
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard urls.contains(where: { $0.scheme == "amlich" }) else { return }
        menubarController?.showCalendar()
    }
}

#if DEBUG
extension CalendarXDelegate {
    private func renderPreviews(at directory: URL) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let appStore = AppStore()
            let calendarStore = CalendarStore()
            let menubarStore = MenubarStore()
            let router = Router()
            let dialog = Dialog()

            func render<V: View>(_ view: V, name: String, width: CGFloat, height: CGFloat, scheme: ColorScheme) throws {
                let content = view
                    .environmentObject(appStore)
                    .environmentObject(calendarStore)
                    .environmentObject(menubarStore)
                    .environmentObject(router)
                    .environmentObject(dialog)
                    .environment(\.locale, .vi)
                    .tint(appStore.accentColor)
                    .accentColor(appStore.accentColor)
                    .frame(width: width, height: height)
                    .background(appStore.backgroundColor)
                    .environment(\.colorScheme, scheme)
                let renderer = ImageRenderer(content: content)
                renderer.scale = 2
                guard let cgImage = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
                let bitmap = NSBitmapImageRep(cgImage: cgImage)
                guard let data = bitmap.representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
                try data.write(to: directory.appendingPathComponent(name + ".png"))
            }

            let scheme: ColorScheme = ProcessInfo.processInfo.arguments.contains("--dark") ? .dark : .light
            do {
                appStore.theme = scheme == .light ? .light : .dark
                let suffix = scheme == .light ? "light" : "dark"
                try render(MainScreen(viewModel: MainViewModel()), name: "calendar-" + suffix, width: 365, height: 485, scheme: scheme)
                try render(SettingsScreen(), name: "settings-" + suffix, width: 365, height: 452, scheme: scheme)
                try render(LunarSummaryView(date: Date(), compact: true).padding(16), name: "day-widget-" + suffix, width: 170, height: 170, scheme: scheme)
            }
            print("Rendered previews to \(directory.path)")
        } catch {
            fputs("Preview rendering failed: \(error)\n", stderr)
        }
        NSApp.terminate(nil)
    }
}
#endif

extension CalendarXDelegate {

    private func bootstrap(calendarStore: CalendarStore, authorizer: Authorizer, updater: Updater) {
        resolveEventsAuthorization(authorizer: authorizer, calendarStore: calendarStore)
        resolveNotificationsAuthorization(authorizer: authorizer, updater: updater)
        NotificationCenter.default
            .addObserver(forName: .NSCalendarDayChanged, object: .none, queue: .main) { _ in
                NotificationCenter.default.post(name: .calendarDayChanged, object: .none)
            }
    }

    private func resolveEventsAuthorization(authorizer: Authorizer, calendarStore: CalendarStore) {
        WidgetCenter.shared.reloadAllTimelines()
        if authorizer.allowFullAccessToEvents { return }
        if calendarStore.showEvents { calendarStore.showEvents.toggle() }
    }

    private func resolveNotificationsAuthorization(authorizer: Authorizer, updater: Updater) {
        Task {
            if await authorizer.allowNotifications { return }
            if updater.automaticallyChecksForUpdates {
                updater.automaticallyChecksForUpdates.toggle()
            }
        }
    }
}
