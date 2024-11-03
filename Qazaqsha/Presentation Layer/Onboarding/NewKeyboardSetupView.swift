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
        VStack(alignment: .center, content: {
            titleView
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 24)
            quickSetupIcon
            actions
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
            Text("Set up \(GlobalConstants.appName) in the Settings")
                .foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
        })
    }

    var actions: some View {
        VStack(alignment: .center, spacing: 4) {
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
                .padding(.vertical, 8)
        })
    }

    var quickSetupIcon: some View {
        GeometryReader(content: { geometry in
            let availableWidth = geometry.size.width
            let ratio = 1.51099831
            let height = availableWidth * ratio
            
            quickSetupIcon(for: availableWidth, height: height)
        })
    }

    func quickSetupIcon(for width: CGFloat, height: CGFloat) -> some View {
        return Asset.Images.onboardingKeyboardSetup.swiftUIImage
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width, height: height)
    }
//    var quickSetupIcon: some View {
//        let ratio = 1.51099831
//        let width = UIScreen.main.bounds.width - 64
//        let height = width * ratio
//        
//        return Asset.Images.onboardingKeyboardSetup.swiftUIImage
//            .resizable()
//            .aspectRatio(contentMode: .fit)
////            .frame(width: width, height: height)
//            .padding(.horizontal, 16)
//    }
}

struct NewKeyboardSetupView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            NewKeyboardSetupView()
        }
    }
}
