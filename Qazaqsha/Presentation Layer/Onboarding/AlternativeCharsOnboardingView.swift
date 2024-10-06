//
//  AlternativeCharsOnboardingView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 05.10.2024.
//

import SwiftUI
import QazaqFoundation

struct AlternativeCharsOnboardingView: View {
    @Environment(\.colorScheme)
    private var colorScheme: ColorScheme

    var body: some View {
        Form {
            Section(content: {
                gifLongPressExample
            }, header: {
                headerView
                    .padding(.vertical, 32)
                    .padding(.horizontal, 16)
            })
            .listRowInsets(EdgeInsets())
        }
        .modifier(FormHiddenBackground())
    }

    var headerView: some View {
        VStack(alignment: .leading, spacing: 10, content: {
            Text("How to select qazaq specific character?")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(Asset.Colors.text.swiftUIColor)
                .textCase(nil) // Ensuring text case is not altered
                .fixedSize(horizontal: false, vertical: true)
            
//            Text("Follow these steps to set \(GlobalConstants.appName) as your default keyboard:")
//                .foregroundColor(Asset.Colors.text.swiftUIColor)
//                .font(.body)
//                .textCase(nil) // Ensuring text case is not altered
//                .fixedSize(horizontal: false, vertical: true)
//            
            // Steps with custom alignment
            VStack(alignment: .leading, spacing: 5) {
                bulletPoint("Long press that available letter.")
                bulletPoint("Slide to select specific letter.")
                bulletPoint("Release")
            }
            .foregroundColor(Asset.Colors.text.swiftUIColor)
            .font(.body)
            .textCase(nil) // Ensuring text case is not altered
        })
    }
    
    func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 5) {
            Text("•")
                .foregroundColor(Asset.Colors.text.swiftUIColor)
            Text(text)
                .foregroundColor(Asset.Colors.text.swiftUIColor)
                .fixedSize(horizontal: false, vertical: true)  // Ensures text wraps correctly
        }
    }
    
    var gifLongPressExample: some View {
        let ratio = 1.16078431
        let width = UIScreen.main.bounds.width - 32
        let height = width / ratio

        let gifName = colorScheme == .dark ? "longPressDark" : "longPressWhite"

        return GifImage(name: gifName)
            .frame(width: width, height: height)
    }
}

struct AlternativeCharsOnboardingView_Preview: PreviewProvider {
    static var previews: some View {
        AlternativeCharsOnboardingView()
        AlternativeCharsOnboardingView().preferredColorScheme(.dark)
    }
}
