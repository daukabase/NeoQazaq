//
//  KeyboardSetupView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 25.02.2024.
//

import SwiftUI

enum GlobalConstants {
    static let appName = "NeoQazaq"
    static let appVersion = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return version ?? "1.0.0"
    }()
}

struct KeyboardSetupView: View {
    enum Constants {
        static let iconSize = CGSize(width: 32, height: 32)
        static let indexItemSize = CGSize(width: 28, height: 28)
        static let iOSIconRoundedCornersScale: CGFloat = 10 / 57
        static let appName = GlobalConstants.appName
        static let keyboardName = appName
        static let appURL = URL(string: UIApplication.openSettingsURLString)!
    }

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL

    var body: some View {
        welcomeView
        Spacer()
        setupStepsView
        Spacer()
        policyView
    }

    var welcomeView: some View {
        VStack(alignment: .center, content: {
            Text("Welcome to \(Constants.appName)").foregroundColor(Asset.Colors.text.swiftUIColor)
            Text("Follow steps below to setup keyboard").foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
        })
    }
    
    var policyView: some View {
        Text("By installing, you are agreeing to \(Constants.appName)'s privacy policy")
    }
    
    var setupStepsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0 ..< 6, id: \.self) { index in
                switch index {
                case 0:
                    iconText(
                        index: index,
                        icon: icon(for: Asset.Images.appleSettingsGear.swiftUIImage),
                        text: "Open Settings"
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
        .padding(.leading, 36)
    }
    
    var openAppButton: some View {
        Button(action: {
            openURL(URL(string: UIApplication.openSettingsURLString)!)
        }, label: {
            Text("open").foregroundStyle(Asset.Colors.lightAction.swiftUIColor)
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
        HStack(alignment: .center, spacing: 12) {
            indexView(index: index + 1)
            
            Spacer().frame(width: 12)
            
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
        HStack(alignment: .center, spacing: 12) {
            indexView(index: index + 1)
            
            Spacer().frame(width: 12)
            
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
        Text(String(index))
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
