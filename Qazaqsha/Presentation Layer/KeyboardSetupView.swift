//
//  KeyboardSetupView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 25.02.2024.
//

import SwiftUI
import QazaqFoundation

// TODO: move to global constants

final class KeyboardSetupViewModel: ObservableObject {
    var isSetupFinished: Bool {
        GlobalConstants.isKeyboardExtensionEnabled
    }
}

struct KeyboardSetupView: View {
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
    
    var body: some View {
        VStack(alignment: .leading, content: {
            titleView
            setupStepsView
                .padding(.top, 32)
            Spacer()
            policyView
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
    
    var policyView: some View {
        Text("By installing, you are agreeing to [privacy policy](https://www.freeprivacypolicy.com/blog/privacy-policy-url/)")
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
                        text: "Settings"
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
                        text: "Keyboards"
                    )
                case 3:
                    text(index: index, text: "Enable \(Constants.keyboardName)")
                case 4:
                    text(
                        index: index,
                        text: "Allow Full Access",
                        subtitle: "Optional"
                    )
                case 5:
                    text(
                        index: index,
                        text: "Come back to finish setup"
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
                    Text(text).foregroundColor(Asset.Colors.text.swiftUIColor)
                }
                
                if let subtitle {
                    Text(subtitle).foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
                }
            })
            
            Spacer()
        }
        .frame(height: 40)
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

struct KeyboardSetupView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            KeyboardSetupView()
        }
    }
}
