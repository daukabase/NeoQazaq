//
//  OnboardingExplanationView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 17.04.2024.
//

import SwiftUI
import QazaqFoundation

struct OnboardingExplanationView: View {
    static let iconSize = CGFloat(100)

    @Environment(\.colorScheme)
    private var colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading) {
            Form {
                Section(content: {
                    contentView
                    example
                }, header: {
                    headerView
                }, footer: {
                    
                })
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
            .modifier(FormHiddenBackground())
            Spacer()
            policyView.padding(16)
        }
    }

    var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("onboarding_welcome \(GlobalConstants.appName)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Asset.Colors.text.swiftUIColor)
                .lineLimit(2)
                .scaledToFit()
        }
        .fixedSize(horizontal: false, vertical: false)
        .textCase(nil)
        .padding(.bottom, 32)
    }

    var contentView: some View {
        VStack(alignment: .center, spacing: 0) {
            appIcon

            Text("onboarding_welcome_subtitle")
                .foregroundColor(Asset.Colors.text.swiftUIColor)
                .font(.title3)
                .fontWeight(.semibold)

            VStack(alignment: .leading) {
                Text("onboarding_welcome_description")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .textCase(nil)
    }

    var example: some View {
        VStack(alignment: .center) {
            Text("common_example")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            gifAutocorrectionExample
        }
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .padding([.top, .horizontal], 16)
    }
    
    var appIcon: some View {
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
    }

    var gifAutocorrectionExample: some View {
        let ratio = 1.16078431
        let width = UIScreen.main.bounds.width - 32 - 16
        let height = width / ratio

        let gifName = colorScheme == .dark ? "autocorrectionExampleDark" : "autocorrectionExampleWhite"

        return GifImage(name: gifName).frame(width: width, height: height)
    }

    var policyView: some View {
        Text("data_not_collected")
            .font(.caption).multilineTextAlignment(.leading)
    }
}

struct OnboardingExplanationView_Preview: PreviewProvider {
    static var previews: some View {
        OnboardingExplanationView()
        OnboardingExplanationView().preferredColorScheme(.dark)
    }
}
