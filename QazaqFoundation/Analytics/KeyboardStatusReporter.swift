//
//  KeyboardStatusReporter.swift
//  QazaqFoundation
//
//  Measures keyboard users who did NOT grant Full Access.
//
//  Without Full Access the keyboard has no network, so it can never report anything itself.
//  The app (which always has network) does it instead, once a day when opened:
//   - the keyboard writes "Full Access seen at <date>" to the app group whenever it runs with
//     Full Access (iOS only allows that write with Full Access, so the mark can't lie);
//   - the app sends `keyboard_status` with whether the keyboard is enabled and whether that mark exists.
//
//  In Amplitude: Full Access share = users with fullAccessConfirmed / users with isKeyboardEnabled.
//  Real keyboard users ≈ users seen via `launch_keyboard` / that share.
//

import Foundation
import UIKit

public enum KeyboardStatusReporter {
    private static let lastReportDayKey = "lastKeyboardStatusReportDay"

    /// Keyboard side: call on every launch. Writes only succeed with Full Access, which is the point.
    public static func markFullAccessIfGranted(hasFullAccess: Bool) {
        guard hasFullAccess else { return }
        UserDefaults.localAppGroup.set(Date(), forKey: UserDefaults.keyboardFullAccessLastSeenKey)
    }

    /// App side: call when the app becomes active. Sends at most one event per day.
    public static func reportIfNeeded(
        isKeyboardEnabled: Bool,
        isOnboardingFinished: Bool,
        now: Date = Date(),
        defaults: UserDefaults = .standard,
        analytics: AnalyticsService = AnalyticsServiceFacade.shared
    ) {
        let today = Calendar.current.startOfDay(for: now)
        if let last = defaults.object(forKey: lastReportDayKey) as? Date, last >= today { return }
        defaults.set(today, forKey: lastReportDayKey)
        analytics.track(event: CommonAnalyticsEvent(
            name: "keyboard_status",
            params: params(isKeyboardEnabled: isKeyboardEnabled, isOnboardingFinished: isOnboardingFinished, now: now)
        ))
    }

    static func params(isKeyboardEnabled: Bool, isOnboardingFinished: Bool, now: Date) -> [String: Any] {
        let lastSeen = UserDefaults.localAppGroup.object(forKey: UserDefaults.keyboardFullAccessLastSeenKey) as? Date
        var params: [String: Any] = [
            "isKeyboardEnabled": isKeyboardEnabled,
            "isOnboardingFinished": isOnboardingFinished,
            // Proof written by the keyboard itself (only possible with Full Access).
            "fullAccessConfirmed": lastSeen != nil,
            // KeyboardKit-style check from inside the app; kept to compare with the proof above.
            "fullAccessSystemFlag": UIInputViewController().hasFullAccess,
        ]
        if let lastSeen {
            params["fullAccessLastSeenDaysAgo"] = Calendar.current.dateComponents([.day], from: lastSeen, to: now).day ?? 0
        }
        return params
    }
}

/// How much a person uses the keyboard on a day: how many times it opened and how long it was on
/// screen. Numbers only, nothing about what was typed. The keyboard sends one `launch_keyboard`
/// event a day (memory), so each day's totals ride along on the next day's event.
///
/// In Amplitude: average of `prevDayOpens` / `prevDayVisibleSeconds` on `launch_keyboard`
/// = opens / seconds on screen per active day.
public struct KeyboardUsageCounter {
    /// A keyboard left open while the phone sits on a table shouldn't count as hours of use.
    static let maxSecondsPerAppearance: TimeInterval = 30 * 60

    private enum Key {
        static let day = "keyboardUsageDay"
        static let opens = "keyboardUsageOpens"
        static let seconds = "keyboardUsageSeconds"
        static let finishedOpens = "keyboardUsageFinishedOpens"
        static let finishedSeconds = "keyboardUsageFinishedSeconds"
    }

    private let defaults: UserDefaults
    private let calendar: Calendar

    public init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
    }

    public func recordOpen(now: Date = Date()) {
        rollOverIfNeeded(now: now)
        defaults.set(defaults.integer(forKey: Key.opens) + 1, forKey: Key.opens)
    }

    public func recordVisible(seconds: TimeInterval, now: Date = Date()) {
        guard seconds > 0 else { return }
        rollOverIfNeeded(now: now)
        let added = min(seconds, Self.maxSecondsPerAppearance)
        defaults.set(defaults.double(forKey: Key.seconds) + added, forKey: Key.seconds)
    }

    /// Totals of the last day before today that had any use, for the daily event; nil if already
    /// sent or there is none. Reading removes them, so each day is reported once.
    public func takeFinishedDay(now: Date = Date()) -> (opens: Int, visibleSeconds: Int)? {
        rollOverIfNeeded(now: now)
        guard defaults.object(forKey: Key.finishedOpens) != nil else { return nil }
        let result = (defaults.integer(forKey: Key.finishedOpens), Int(defaults.double(forKey: Key.finishedSeconds).rounded()))
        defaults.removeObject(forKey: Key.finishedOpens)
        defaults.removeObject(forKey: Key.finishedSeconds)
        return result
    }

    /// On the first use of a new day, yesterday's (or the last active day's) totals become "finished".
    private func rollOverIfNeeded(now: Date) {
        let today = calendar.startOfDay(for: now)
        let day = defaults.object(forKey: Key.day) as? Date
        guard day != today else { return }
        if let day, day < today, defaults.integer(forKey: Key.opens) > 0 || defaults.double(forKey: Key.seconds) > 0 {
            defaults.set(defaults.integer(forKey: Key.opens), forKey: Key.finishedOpens)
            defaults.set(defaults.double(forKey: Key.seconds), forKey: Key.finishedSeconds)
        }
        defaults.set(today, forKey: Key.day)
        defaults.set(0, forKey: Key.opens)
        defaults.set(0.0, forKey: Key.seconds)
    }
}
