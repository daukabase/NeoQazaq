//
//  OnboardingExplanationView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 17.04.2024.
//

import SwiftUI
import QazaqFoundation

struct OnboardingExplanationView: View {
    @Environment(\.colorScheme)
    private var colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome to the NeoQazaq")
                .font(.title)

            Text("Our mission is to contribute kazakh language in digital world")
                .font(.headline)
                .padding(.vertical, 4)

            VStack(alignment: .leading) {
                Text("You type in kazakh")
                Text("We correct mistakes")
                Text("Even if you type shalaqazaqsha 😁")
            }
            .font(.title3)
            .padding(.vertical, 16)

            gifAutocorrectionExample

            Text("Our autocorrection algorithm is not finished yet, feel free to submit feedback (bugs and improvements)")
                .foregroundStyle(.secondary).font(.caption)
                .padding(.bottom, 16)
            Spacer()
        }
        .padding(.leading, 32)
        .padding(.trailing, 32)
    }

    var gifAutocorrectionExample: some View {
        let ratio = 1.16078431
        let width = UIScreen.main.bounds.width - 64
        let height = width / ratio
        
        let gifName = colorScheme == .dark ? "autocorrectionExampleDark" : "autocorrectionExampleWhite"
        
        return GifImage(name: gifName)
            .frame(width: width, height: height)
    }
}

struct OnboardingExplanationView_Preview: PreviewProvider {
    static var previews: some View {
        OnboardingExplanationView()
    }
}
