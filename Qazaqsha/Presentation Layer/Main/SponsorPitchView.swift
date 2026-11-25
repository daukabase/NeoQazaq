//
//  SponsorPitchView.swift
//  Qazaqsha
//
//  Pitch for companies: who the audience is (numbers), why it's brand-safe (we never collect
//  what people type), what placements exist, and a "Become a supporter" request that goes to
//  the team's Telegram (FeedbackService .advertising, #ads).
//
//  The numbers are typed in by hand from Amplitude. UPDATE `SponsorMetrics.current` before
//  each release.
//

import SwiftUI
import QazaqFoundation

/// Only rates and habits, never audience size: they show how much people rely on Batyrma and
/// stay meaningful while the audience grows. All from Amplitude, event `launch_keyboard`.
struct SponsorMetrics {
    /// Keyboard users who type with it again the next day (Retention, launch_keyboard → launch_keyboard, Day 1).
    let nextDayPercent: Int
    /// …and 7 days later (same chart, Day 7).
    let weekLaterPercent: Int
    /// Days a week a typical user types with Batyrma: sum of daily uniques over 7 days / uniques for the week.
    let daysPerWeek: Double
    /// Times a day a typical user opens the keyboard. Up to 1.x: TOTALS(launch_keyboard) / sum of daily
    /// uniques (the event fired on every load). From 2.0: average of `prevDayOpens`.
    let opensPerDay: Int
    /// Minutes a day the keyboard is on screen: average of `prevDayVisibleSeconds` / 60. Collected
    /// from 2.0 on; nil hides the tile until there is data.
    let minutesPerDay: Int?
    /// Month the figures are from, shown under them.
    let asOf: String

    /// Source: Amplitude, Nov 17–23, 2026 (daily keyboard tracking started Nov 11, so Day 14+ can't be
    /// measured yet; add it once there are a few weeks of data).
    static let current = SponsorMetrics(
        nextDayPercent: 79,
        weekLaterPercent: 60,
        daysPerWeek: 4.2,
        opensPerDay: 39,
        minutesPerDay: nil,
        asOf: "11.2026"
    )
}

struct SponsorPitchView: View {
    var metrics: SponsorMetrics = .current

    @State private var showsRequestForm = false

    var body: some View {
        ZStack {
            OnboardingBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Meaning first, then proof, then the offer; the privacy tile closes right
                    // before the button, as the trust argument.
                    hero
                    section("sponsor_why_title", items: [
                        ("heart.fill", "sponsor_why_mission"),
                        ("lock.shield.fill", "sponsor_why_safe"),
                        ("person.3.fill", "sponsor_why_audience"),
                    ])
                    metricsGrid
                    section("sponsor_placements_title", items: [
                        ("space", "sponsor_placement_space"),
                        ("paintpalette.fill", "sponsor_placement_skin"),
                        ("rectangle.stack.fill", "sponsor_placement_home"),
                    ])
                    metric("0", "sponsor_metric_privacy", color: .green)
                    Text("sponsor_data_note\(metrics.asOf)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.45))
                    Button(action: { showsRequestForm = true }) { Text("sponsor_cta") }
                        .buttonStyle(OnboardingPillButtonStyle())
                }
                .padding(24)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsRequestForm) { FeedbackView(type: .advertising) }
        .onAppear {
            AnalyticsServiceFacade.shared.track(event: CommonAnalyticsEvent(name: "sponsor_pitch_opened"))
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            BatyrmaOrb(size: 56)
                .offset(x: -14)
            Text("sponsor_pitch_title")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text("sponsor_pitch_subtitle")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            metric("\(metrics.nextDayPercent)%", "sponsor_metric_next_day")
            metric("\(metrics.weekLaterPercent)%", "sponsor_metric_week_later")
            metric(metrics.daysPerWeek.formatted(.number.precision(.fractionLength(1))), "sponsor_metric_days_per_week")
            metric("\(metrics.opensPerDay)", "sponsor_metric_opens_per_day")
            if let minutes = metrics.minutesPerDay {
                metric("\(minutes)", "sponsor_metric_minutes_per_day")
            }
        }
    }

    private func metric(_ value: String, _ label: LocalizedStringKey, color: Color = OnboardingTheme.accent) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .card()
    }

    private func section(_ title: LocalizedStringKey, items: [(String, LocalizedStringKey)]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundColor(.white)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: item.0)
                        .foregroundColor(OnboardingTheme.gold)
                        .frame(width: 24)
                    Text(item.1)
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct SponsorPitchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { SponsorPitchView() }
    }
}
