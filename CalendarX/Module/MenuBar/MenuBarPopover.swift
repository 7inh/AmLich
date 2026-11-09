//
//  MenubarPopover.swift
//  CalendarX
//
//  Created by zm on 2022/1/4.
//

import AppKit
import CalendarXLib
import Combine
import SwiftUI

@MainActor
class MenubarPopover: NSPopover {

    private let privateKey = "shouldHideAnchor"

    private var eventMonitor: Any?

    private var cancellables = Set<AnyCancellable>()

    private let router: Router

    init<Content>(_ router: Router, rootScreen: Content) where Content: View {
        self.router = router
        super.init()
        let host = NSHostingController(rootView: rootScreen)
        host.sizingOptions = [.preferredContentSize]  // popover height follows the content
        contentViewController = host
        behavior = .transient
        syncAppearance()
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncAppearance() }
            .store(in: &cancellables)
    }

    /// The popover window follows the menu bar's appearance, which can differ from the app theme,
    /// so pin it explicitly to keep the material and the SwiftUI content in agreement.
    private func syncAppearance() {
        let theme = Theme(rawValue: UserDefaults.group?.integer(forKey: AppStorageKey.theme) ?? 0) ?? .system
        appearance = switch theme {
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        default: nil
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(_ sender: Any?) {
        guard let button = sender as? NSStatusBarButton else { return }
        guard let event = NSApp.currentEvent else { return }
        router.set(event.isRightClicked ? .settings : .calendar)
        show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        contentViewController?.view.window?.becomeKey()
        startEventMonitor()
    }

    override func close() {
        router.set(.empty)
        super.close()
        contentViewController?.view.window?.resignKey()
        stopEventMonitor()
    }

    func showCalendar(from button: NSStatusBarButton) {
        router.set(.calendar)
        show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        contentViewController?.view.window?.becomeKey()
        startEventMonitor()
    }

}

extension MenubarPopover {

    func startEventMonitor() {
        stopEventMonitor()
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self else { return }
            guard isShown else { return }
            close()
        }
    }

    func stopEventMonitor() {
        guard eventMonitor != nil else { return }
        NSEvent.removeMonitor(eventMonitor!)
        eventMonitor = .none
    }
}

extension MenubarPopover {

    private func shouldHideAnchor() {
        if value(forKey: privateKey) is String {
            return
        }
        setValue(true, forKey: privateKey)
    }

    override func value(forUndefinedKey key: String) -> Any? {
        key == privateKey ? key : .none
    }

}
