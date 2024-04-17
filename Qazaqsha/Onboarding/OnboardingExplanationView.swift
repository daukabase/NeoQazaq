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
        Form {
            Section(content: {
                gifAutocorrectionExample
            }, header: {
                headerView
                    .padding(.vertical, 32)
                    .padding(.horizontal, 16)
            }, footer: {
                Text("Our autocorrection algorithm is not finished yet, feel free to submit feedback (bugs and improvements)")
                    .foregroundStyle(.secondary).font(.caption)
                    .padding(.vertical, 8)
                Spacer()
            })
            .listRowInsets(EdgeInsets())
        }
        .modifier(FormHiddenBackground())
//        .navigationBarTitle("Switch to \(GlobalConstants.appName)")
//        
//        
//        
//        VStack(alignment: .leading, spacing: 8) {
//            Text("Welcome to the NeoQazaq")
//                .font(.title)
//                .foregroundColor(Asset.Colors.text.swiftUIColor)
//
//            Text("Our mission is to contribute kazakh language in digital world")
//                .font(.headline)
//                .padding(.vertical, 4)
//
//            VStack(alignment: .leading) {
//                Text("You type in kazakh")
//                Text("We correct mistakes")
//                Text("Even if you type shalaqazaqsha 😁")
//            }
//            .font(.title3)
//            .padding(.vertical, 16)
//
//            gifAutocorrectionExample
//
//        }
//        .padding(.horizontal, 16)
    }

    var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome to the NeoQazaq")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(Asset.Colors.text.swiftUIColor)
                .lineLimit(2)

            Text("Our mission is to contribute kazakh language in digital world")
                .foregroundColor(Asset.Colors.text.swiftUIColor)
                .font(.headline)
                .padding(.vertical, 4)

            VStack(alignment: .leading) {
                Text("You type in kazakh")
                Text("We correct mistakes")
                Text("Even if you type shalaqazaqsha 😁")
            }
            .font(.title3)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .fixedSize(horizontal: false, vertical: true)
        .textCase(nil)
    }

    var gifAutocorrectionExample: some View {
        let ratio = 1.16078431
        let width = UIScreen.main.bounds.width - 32
        let height = width / ratio
        
        let gifName = colorScheme == .dark ? "autocorrectionExampleDark" : "autocorrectionExampleWhite"
        
        return GifImage(name: gifName)
            .frame(width: width, height: height)
    }
}

struct OnboardingExplanationView_Preview: PreviewProvider {
    static var previews: some View {
        OnboardingExplanationView()
        OnboardingExplanationView().preferredColorScheme(.dark)
    }
}
