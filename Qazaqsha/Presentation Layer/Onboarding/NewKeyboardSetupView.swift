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
    @State var showKeyboardGuide = false

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center, spacing: 0) {
                titleView
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 24)
                
                // Flexible container for icon
                quickSetupIcon
                    .frame(height: getIconHeight(in: geometry))
                    .animation(.easeInOut(duration: 1))

                if !GlobalConstants.isKeyboardExtensionEnabled {
                    actions
                        .padding(.top, 24)
                        .animation(.easeInOut(duration: 1))
                } else {
                    postSetupGuide
                        .padding(.top, 24)
                        .animation(.easeInOut(duration: 1))
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 32)
        }
        .navigationBarTitle("Keyboard setup")
        .sheet(isPresented: $manualSetupSheetShowing) {
            ManualKeyboardSetupView()
        }
    }
    
    private func getIconHeight(in geometry: GeometryProxy) -> CGFloat {
        let totalHeight = geometry.size.height
        let titleHeight: CGFloat = 100
        let actionsHeight: CGFloat = GlobalConstants.isKeyboardExtensionEnabled ? 120 : 140
        let padding: CGFloat = 48

        // Calculate available space for icon
        let availableHeight = totalHeight - titleHeight - actionsHeight - padding

        let ratio: CGFloat = 1.51099831
        let width = geometry.size.width - 64
        let idealHeight = width * ratio
        
        return min(idealHeight, availableHeight)
    }
    
    var postSetupGuide: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 48))
            
            Text("Keyboard is ready!")
                .font(.headline)
                .foregroundColor(Asset.Colors.text.swiftUIColor)
        }
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
            .background(.blue)
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
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 16)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
        })
    }

    var quickSetupIcon: some View {
        Asset.Images.onboardingKeyboardSetup.swiftUIImage
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

struct NewKeyboardSetupView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            NewKeyboardSetupView()
        }
    }
}
