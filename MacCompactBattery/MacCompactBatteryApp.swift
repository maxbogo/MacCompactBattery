import AppKit
import Combine
import ServiceManagement
import SwiftUI

@main
struct MacCompactBatteryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let batteryMonitor = BatteryMonitor()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var statusObserver: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerAtLoginIfNeeded()

        let menu = NSMenu()
        let reorderHintItem = NSMenuItem(
            title: "Hold Command and drag the icon to change its order",
            action: nil,
            keyEquivalent: ""
        )
        reorderHintItem.isEnabled = false
        menu.addItem(reorderHintItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu

        statusObserver = batteryMonitor.$status.sink { [weak self] status in
            self?.apply(status: status)
        }
        apply(status: batteryMonitor.status)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func registerAtLoginIfNeeded() {
        guard SMAppService.mainApp.status != .enabled else {
            return
        }

        do {
            try SMAppService.mainApp.register()
        } catch {
            NSLog("Failed to register MacCompactBattery as a login item: \(error.localizedDescription)")
        }
    }

    private func apply(status: BatteryStatus) {
        guard let button = statusItem.button else {
            return
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium),
            .foregroundColor: status.color ?? NSColor.labelColor,
        ]

        button.attributedTitle = NSAttributedString(string: status.title, attributes: attributes)
    }
}
