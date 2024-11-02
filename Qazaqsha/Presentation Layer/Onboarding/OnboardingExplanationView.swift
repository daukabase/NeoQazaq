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
                contentView
                example
            }, header: {
                headerView
            }, footer: {
                Text("Our autocorrection algorithm is not finished yet, feel free to submit feedback (bugs and improvements)")
                    .foregroundStyle(.secondary).font(.caption)
                    .padding(.vertical, 8)
                Spacer()
            })
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
        }
        .modifier(FormHiddenBackground())
    }

    var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome to NeoQazaq")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Asset.Colors.text.swiftUIColor)
                .lineLimit(2)
                .scaledToFit()
        }
        .fixedSize(horizontal: false, vertical: true)
        .textCase(nil)
        .padding(.bottom, 32)
    }

    static let iconSize = CGFloat(100)
    var contentView: some View {
        VStack(alignment: .center, spacing: 0) {
            Asset.Images.appIconNoBackground.swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Self.iconSize, height: Self.iconSize)
                .background(
                    RoundedRectangle(cornerRadius: 25.0)
                        .frame(width: Self.iconSize / 2, height: Self.iconSize / 2)
                        .foregroundStyle(.white)
                        .shadow(color: .blue, radius: 15, x: -8, y: 8)
                )

            Text("Smart Kazakh Keyboard")
                .foregroundColor(Asset.Colors.text.swiftUIColor)
                .font(.title3)
                .fontWeight(.semibold)

            VStack(alignment: .leading) {
                Text("Type as you used to - we'll add proper Kazakh letters automatically")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .multilineTextAlignment(.center)
        }
        .fixedSize(horizontal: false, vertical: true)
        .textCase(nil)
    }

    var gifAutocorrectionExample: some View {
        let ratio = 1.16078431
        let width = UIScreen.main.bounds.width - 32 - 16
        let height = width / ratio
        
        let gifName = colorScheme == .dark ? "autocorrectionExampleDark" : "autocorrectionExampleWhite"
        
        return GifImage(name: gifName)
            .frame(width: width, height: height)
            
    }
    
    var example: some View {
        VStack(alignment: .center) {
            Text("Example")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            gifAutocorrectionExample
        }
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .padding(16)
    }
}

struct OnboardingExplanationView_Preview: PreviewProvider {
    static var previews: some View {
        OnboardingExplanationView()
        OnboardingExplanationView().preferredColorScheme(.dark)
    }
}
