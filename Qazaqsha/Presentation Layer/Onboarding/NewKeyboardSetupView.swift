//
//  NewKeyboardSetupView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 03.11.2024.
//

import SwiftUI
import QazaqFoundation

// TODO: move to global constants

final class NewKeyboardSetupViewModel: ObservableObject {
    var isSetupFinished: Bool {
        GlobalConstants.isKeyboardExtensionEnabled
    }
}

struct NewKeyboardSetupView: View {
    enum Constants {
        static let iconSize = CGSize(width: 32, height: 32)
        static let indexItemSize = CGSize(width: 22, height: 22)
        static let iOSIconRoundedCornersScale: CGFloat = 10 / 57
        static let appName = GlobalConstants.appName
        static let keyboardName = appName
        static let appURL = URL(string: UIApplication.openSettingsURLString)!
    }

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    
    @State var manualSetupSheetShowing = false
    
    var body: some View {
        VStack(alignment: .leading, content: {
            titleView

            quickSetupView
                .padding(.top, 32)

            Spacer()
            policyView
        })
        .sheet(isPresented: $manualSetupSheetShowing, content: {
            ManualKeyboardSetupView().padding(.top, 32)
        })
        .padding(.horizontal, 32)
        .navigationBarTitle("Keyboard Setup")
    }
    
    var titleView: some View {
        VStack(alignment: .leading, content: {
            HStack(content: {
                Text("Keyboard setup")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(Asset.Colors.text.swiftUIColor)
                if GlobalConstants.isKeyboardExtensionEnabled {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)  // Apple's standard green color
                        .font(.system(size: 24, weight: .bold))  // Adjust the size and weight as needed
                }
            })
            Text("Follow steps below to setup keyboard").foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
        })
    }
    
    @ViewBuilder
    var quickSetupView: some View {
        quickSetupIcon

        VStack(spacing: 12) {
            Button(action: {
                openURL(URL(string: UIApplication.openSettingsURLString)!)
            }, label: {
                Text("Add now")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .padding(.horizontal, 24)
            })
            .background(.blue.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 24))

            showManualSteps
        }
    }

    var showManualSteps: some View {
        Button(action: {
            manualSetupSheetShowing = true
        }, label: {
            Text("Show manual setup steps")
                .font(.footnote)
                .font(.subheadline)
                .foregroundStyle(.blue.opacity(0.7))
                .frame(maxWidth: .infinity)
                .frame(height: 16)
                .padding(.horizontal, 24)
        })
    }

    var quickSetupIcon: some View {
        Asset.Images.onboardingKeyboardSetup.swiftUIImage
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
    }
    
    var policyView: some View {
        Text("By continuing, you are agreeing to [privacy policy](https://www.freeprivacypolicy.com/blog/privacy-policy-url/)")
            .font(.caption)
    }
    
}

struct NewKeyboardSetupView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            NewKeyboardSetupView()
        }
    }
}
