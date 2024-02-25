//
//  ContentView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 29.01.2024.
//

import SwiftUI

struct ContentView: View {
    enum Constants {
        static let iconSize = CGSize(width: 32, height: 32)
        static let indexItemSize = CGSize(width: 28, height: 28)
        static let iOSIconRoundedCornersScale: CGFloat = 10 / 57
        static let appName = "TazaQazaq"
        static let keyboardName = "Batyrma"
    }

    var body: some View {
        welcomeView
        Spacer(minLength: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/)
        setupStepsView
        Spacer()
        policyView
    }

    var welcomeView: some View {
        VStack(alignment: .center, content: {
            Text("Welcome to \(Constants.appName)").foregroundColor(.black)
            Text("Follow steps below to setup keyboard").foregroundColor(.gray)
        })
    }

    var policyView: some View {
        Text("This is policy privacy for \(Constants.appName)")
    }

    var setupStepsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0 ..< 6, id: \.self) { index in
                switch index {
                case 0:
                    iconText(
                        index: index,
                        icon: Asset.Images.appleSettingsGear.swiftUIImage,
                        text: "Open Settings"
                    )
                case 1:
                    iconText(
                        index: index,
                        icon: Asset.Images.appIconWelcome.swiftUIImage,
                        text: Constants.appName
                    )
                case 2:
                    iconText(
                        index: index,
                        icon: Asset.Images.appleSettingsGear.swiftUIImage,
                        text: "Keyboards"
                    )
                case 3:
                    iconText(
                        index: index,
                        text: "Enable \(Constants.keyboardName)"
                    )
                case 4:
                    iconText(
                        index: index,
                        text: "Allow Full Access",
                        subtitle: "Optional"
                    )
                case 5:
                    iconText(
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

    func iconText(index: Int, icon: Image? = nil, text: String, subtitle: String? = nil) -> some View {
        HStack(alignment: .center, spacing: 12) {
            indexView(index: index + 1)

            Spacer().frame(width: 12)

            if let icon {
                icon
                    .resizable()
                    .frame(width: Constants.iconSize.width, height: Constants.iconSize.height)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(
                        cornerRadius: Constants.iOSIconRoundedCornersScale * Constants.iconSize.width,
                        style: .continuous
                    ))
            }

            VStack(alignment: .leading, content: {
                Text(text).foregroundColor(.black)

                if let subtitle {
                    Text(subtitle).foregroundColor(.gray)
                }
            })

            Spacer()
        }
        .frame(height: 40)
    }

    func indexView(index: Int) -> some View {
        Text(String(index))
            .frame(width: Constants.indexItemSize.width - 1, height: Constants.indexItemSize.height - 1)
            .foregroundColor(.black)
            .background(
                Circle()
                    .strokeBorder(.black, lineWidth: 1)
            )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
