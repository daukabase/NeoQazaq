//
//  ManualKeyboardSetupView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 25.02.2024.
//

import SwiftUI
import QazaqFoundation

// TODO: move to global constants

final class ManualKeyboardSetupViewModel: ObservableObject {
    var isSetupFinished: Bool {
        GlobalConstants.isKeyboardExtensionEnabled
    }
}

struct ManualKeyboardSetupView: View {
    enum Constants {
        static let iconSize = CGSize(width: 32, height: 32)
        static let indexItemSize = CGSize(width: 22, height: 22)
        static let iOSIconRoundedCornersScale: CGFloat = 10 / 57
        static let appName = GlobalConstants.appName
        static let keyboardName = appName
        static let appURL = URL(string: UIApplication.openSettingsURLString)!
    }
    
    @State private var showKeyboardGuide = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack(alignment: .leading, content: {
            titleView
                .padding(.top, 16)
            setupStepsView
                .padding(.top, 32)
            
            keyboardGuideButton
                .padding(.top, 32)
            Spacer()
            policyView
        })
        .padding(.horizontal, 32)
        .navigationBarTitle("Keyboard setup")
        .sheet(isPresented: $showKeyboardGuide) {
            KeyboardSelectionGuideView()
        }
    }

    var keyboardGuideButton: some View {
        Button(action: {
            showKeyboardGuide = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .imageScale(.small)
                Text("How to switch to keyboard")
                    .font(.subheadline)
            }
            .foregroundStyle(.blue)
        }
    }
    
    var titleView: some View {
        VStack(alignment: .leading, content: {
            HStack(content: {
                Text("Manual setup guide")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(Asset.Colors.text.swiftUIColor)
                    .padding(.top, 16)
                if GlobalConstants.isKeyboardExtensionEnabled {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)  // Apple's standard green color
                        .font(.system(size: 24, weight: .bold))  // Adjust the size and weight as needed
                }
            })
            Text("Follow steps below to setup keyboard").foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
        })
    }
    
    var policyView: some View {
        Text("common_privacy_policy_content")
            .font(.caption)
    }
    
    var setupStepsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0 ..< 6, id: \.self) { index in
                switch index {
                case 0:
                    iconText(
                        index: index,
                        icon: icon(for: Asset.Images.appleSettingsGear.swiftUIImage),
                        text: String(localized: "Settings")
                    )
                case 1:
                    iconText(
                        index: index,
                        icon: icon(for: Asset.Images.appIconWelcome.swiftUIImage),
                        text: Constants.appName,
                        openAppEnabled: true
                    )
                case 2:
                    iconText(
                        index: index,
                        icon: keyboardIcon,
                        text: String(localized: "Keyboards")
                    )
                case 3:
                    text(index: index, text: "Enable \(Constants.keyboardName)")
                case 4:
                    text(
                        index: index,
                        text: String(localized: "Allow Full Access"),
                        subtitle: String(localized: "Optional")
                    )
                case 5:
                    text(
                        index: index,
                        text: String(localized: "If the keyboard does not appear"),
                        subtitle: String(localized: "Try closing and reopening the Settings app")
                    )
                default:
                    Rectangle()
                }
            }
        }
    }
    
    var openAppButton: some View {
        Button(action: {
            openURL(URL(string: UIApplication.openSettingsURLString)!)
        }, label: {
            Text("take me there").foregroundStyle(Asset.Colors.lightAction.swiftUIColor)
        })
    }
    
    var keyboardIcon: some View {
        Image(systemName: "keyboard")
            .renderingMode(.template)
            .foregroundColor(.white)
            .frame(width: Constants.iconSize.width, height: Constants.iconSize.height)
            .background(Asset.Colors.lightAction.swiftUIColor)
            .clipShape(RoundedRectangle(
                cornerRadius: Constants.iOSIconRoundedCornersScale * Constants.iconSize.width,
                style: .continuous
            ))
    }
    
    func iconText(
        index: Int,
        icon: (some View)?,
        text: String,
        openAppEnabled: Bool = false
    ) -> some View {
        HStack(alignment: .center, spacing: 16) {
            indexView(index: index)
            
            HStack(spacing: 8, content: {
                if let icon {
                    icon
                }
                
                VStack(alignment: .leading, content: {
                    HStack {
                        Text(text).foregroundColor(Asset.Colors.text.swiftUIColor)
                        
                        if openAppEnabled {
                            openAppButton
                        }
                    }
                })
            })
            
            Spacer()
        }
        .frame(height: 40)
    }
    
    func icon(for image: Image) -> some View {
        image
            .resizable()
            .frame(width: Constants.iconSize.width, height: Constants.iconSize.height)
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(
                cornerRadius: Constants.iOSIconRoundedCornersScale * Constants.iconSize.width,
                style: .continuous
            ))
    }
    
    func text(
        index: Int,
        text: String,
        subtitle: String? = nil
    ) -> some View {
        HStack(alignment: .center, spacing: 16) {
            indexView(index: index)
            
            VStack(alignment: .leading, content: {
                HStack {
                    Text(text).foregroundColor(Asset.Colors.text.swiftUIColor).lineLimit(nil)
                }
                
                if let subtitle {
                    Text(subtitle).foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
                }
            })
            
            Spacer()
        }
        .frame(minHeight: 40)
    }
    
    func indexView(index: Int) -> some View {
        Text(String(index + 1))
            .font(.caption)
            .frame(width: Constants.indexItemSize.width - 1, height: Constants.indexItemSize.height - 1)
            .foregroundColor(Asset.Colors.text.swiftUIColor)
            .background(
                Circle()
                    .strokeBorder(Asset.Colors.text.swiftUIColor, lineWidth: 1)
            )
    }
}

struct ManualKeyboardSetupView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ManualKeyboardSetupView()
        }
    }
}
