//
//  PrivacyOnboardingView.swift
//  Qazaqsha
//
//  Step 2, right before Settings: Batyrma says out loud that it never reads, keeps or sends
//  what the user types, and warns that iPhone's Full Access alert is the same scary standard
//  text for every keyboard. Priming before a system prompt (like Opal's "Securely" screen)
//  so the alert doesn't scare people off. Event: onboarding_privacy.
//
//  The claims are true for this code: the keyboard sends only a daily "keyboard opened"
//  event with settings flags, plus crash/memory reports; never text (checked 2026-11-24).
//

import SwiftUI

struct PrivacyOnboardingView: View {
    static let lines = [
        "Бір маңызды нәрсе 🔒",
        "Мен сенің не жазғаныңды оқымаймын, сақтамаймын, ешкімге жібермеймін. Ешқашан.",
        "iPhone «Full Access» туралы қорқынышты ескерту көрсетеді — бұл барлық пернетақталарға бірдей стандарт мәтін.",
    ]

    var onReady: () -> Void = {}

    @State private var showsPoints = false
    @State private var showsPolicy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                TypedLinesView(lines: Self.lines, dimsEarlierLines: false) {
                    withAnimation(.easeOut) { showsPoints = true }
                    onReady()
                }

                if showsPoints {
                    VStack(alignment: .leading, spacing: 16) {
                        point("iphone", "privacy_point_text")
                        point("internaldrive.fill", "privacy_point_words")
                        point("chart.bar.fill", "privacy_point_analytics")
                        Button("privacy_read_policy") { showsPolicy = true }
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(OnboardingTheme.accent)
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white.opacity(0.07)))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.green.opacity(0.35), lineWidth: 1))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showsPolicy) {
            NavigationView { PrivacyPolicyView() }
        }
    }

    private func point(_ systemImage: String, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(.green)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct PrivacyOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            OnboardingBackground()
            PrivacyOnboardingView()
        }
        .preferredColorScheme(.dark)
    }
}
