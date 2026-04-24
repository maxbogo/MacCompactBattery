import AppKit
import Foundation
import IOKit.ps

struct BatteryStatus {
    let title: String
    let color: NSColor?
}

private struct BatterySnapshot {
    let percentage: Int
    let isCharging: Bool
}

@MainActor
final class BatteryMonitor: ObservableObject {
    @Published private(set) var status = BatteryStatus(title: "--", color: nil)

    private var timer: Timer?
    private var wakeObserver: NSObjectProtocol?

    init() {
        refresh()

        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }

        wakeObserver = NotificationCenter.default.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    deinit {
        timer?.invalidate()

        if let wakeObserver {
            NotificationCenter.default.removeObserver(wakeObserver)
        }
    }

    func refresh() {
        guard let snapshot = Self.readInternalBatterySnapshot() else {
            status = BatteryStatus(title: "--", color: nil)
            return
        }

        status = BatteryStatus(
            title: "\(snapshot.percentage)",
            color: Self.indicatorColor(for: snapshot)
        )
    }

    private static func indicatorColor(for snapshot: BatterySnapshot) -> NSColor? {
        if snapshot.isCharging {
            return .systemGreen
        }

        let isLowBattery = snapshot.percentage < 20
        if isLowBattery {
            return .systemRed
        }

        return nil
    }

    private static func readInternalBatterySnapshot() -> BatterySnapshot? {
        let powerSourcesInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let powerSourcesList = IOPSCopyPowerSourcesList(powerSourcesInfo).takeRetainedValue() as [CFTypeRef]

        for powerSource in powerSourcesList {
            guard
                let description = IOPSGetPowerSourceDescription(powerSourcesInfo, powerSource)?.takeUnretainedValue() as? [String: Any],
                let isPresent = description[kIOPSIsPresentKey as String] as? Bool,
                isPresent,
                let powerSourceType = description[kIOPSTypeKey as String] as? String,
                powerSourceType == kIOPSInternalBatteryType as String,
                let currentCapacity = description[kIOPSCurrentCapacityKey as String] as? Int,
                let maxCapacity = description[kIOPSMaxCapacityKey as String] as? Int,
                maxCapacity > 0
            else {
                continue
            }

            let percentage = Int((Double(currentCapacity) / Double(maxCapacity) * 100).rounded())
            let isCharging = description[kIOPSIsChargingKey as String] as? Bool ?? false

            return BatterySnapshot(
                percentage: min(max(percentage, 1), 100),
                isCharging: isCharging
            )
        }

        return nil
    }
}
