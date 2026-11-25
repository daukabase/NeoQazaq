//
//  MemoryPressureMonitor.swift
//  Batyrma
//
//  Watches for OS memory-pressure signals inside the keyboard extension and reports them to
//  Crashlytics *before* a jetsam kill can happen. Jetsam terminations are a SIGKILL — there is no
//  signal handler that fires and nothing left for a crash reporter to catch afterwards, which is
//  why production crashes here have been invisible so far. Reporting on the `.warning`/`.critical`
//  pressure signal (which fires while the process is still alive) is the only way to get visibility
//  into this class of crash.
//

import FirebaseCore
import FirebaseCrashlytics
import Foundation

final class MemoryPressureMonitor {
    static let shared = MemoryPressureMonitor()

    private var source: DispatchSourceMemoryPressure?

    private init() {}

    /// Starts watching for memory pressure. Safe to call multiple times; only the first call attaches
    /// the dispatch source. Call as early as possible so we have coverage for the whole extension lifetime.
    func start() {
        guard source == nil else { return }

        let pressureSource = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .main)
        pressureSource.setEventHandler { [weak pressureSource] in
            guard let event = pressureSource?.data else { return }
            MemoryPressureMonitor.report(event: event)
        }
        pressureSource.resume()
        source = pressureSource
    }

    private static func report(event: DispatchSource.MemoryPressureEvent) {
        let level = event.contains(.critical) ? "critical" : "warning"
        let footprintMB = currentMemoryFootprintMB()
        let footprintDescription = footprintMB.map { String(format: "%.1f MB", $0) } ?? "unknown"

        print("[MemoryPressureMonitor] \(level) memory pressure, footprint: \(footprintDescription)")

        // Firebase is configured asynchronously in KeyboardViewController; a pressure event can in
        // theory fire before that finishes. Nothing we can do about that case except the print above.
        guard FirebaseApp.app() != nil else { return }

        let crashlytics = Crashlytics.crashlytics()
        crashlytics.setCustomValue(level, forKey: "memory_pressure_level")
        if let footprintMB {
            crashlytics.setCustomValue(footprintMB, forKey: "memory_footprint_mb")
        }
        // record(error:) persists a non-fatal report to disk immediately (not batched until next
        // launch), which is what makes this useful as an early-warning signal for a kill that leaves
        // no crash report of its own.
        crashlytics.record(error: NSError(
            domain: "com.qazaqsha.batyrma.memoryPressure",
            code: event.contains(.critical) ? 2 : 1,
            userInfo: [NSLocalizedDescriptionKey: "Keyboard extension received \(level) memory pressure (\(footprintDescription))"]
        ))
    }

    /// Resident memory footprint of the current process, in megabytes. Uses `phys_footprint`, the
    /// same figure iOS itself accounts against the extension's jetsam memory limit.
    private static func currentMemoryFootprintMB() -> Double? {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { infoPtr -> kern_return_t in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        return Double(info.phys_footprint) / 1024.0 / 1024.0
    }
}
