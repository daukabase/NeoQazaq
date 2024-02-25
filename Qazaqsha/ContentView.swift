//
//  ContentView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 29.01.2024.
//

import SwiftUI

struct ContentView: View {
    enum Constants {
        static let iconSize = CGSize(width: 24, height: 24)
        static let indexItemSize = CGSize(width: 24, height: 24)
    }

//    @State
//    var text = "" {
//        didSet {
//            print(text)
//        }
//    }

    var body: some View {
        VStack {
            
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
                        text: "Keyboards"
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
                        icon: nil,
                        text: "Enable Batyrma"
                    )
                case 4:
                    iconText(
                        index: index,
                        icon: nil,
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
        .padding()
    }

    func iconText(index: Int, icon: Image? = nil, text: String, subtitle: String? = nil) -> some View {
        HStack(alignment: .center, spacing: 4) {
            indexView(index: index + 1)

            if let icon {
                icon.frame(width: Constants.iconSize.width, height: Constants.iconSize.height)
            }

            VStack(alignment: .leading, content: {
                Text(text).foregroundColor(Asset.Colors.lightPrimary.swiftUIColor)

                if let subtitle {
                    Text(subtitle).foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
                }
            })
        }
    }

    func indexView(index: Int) -> some View {
        ZStack(alignment: .center) {
            Rectangle()
                .fill(Color.green)
                .frame(width: Constants.indexItemSize.width + 1, height: Constants.indexItemSize.width + 1)
                .background(Asset.Colors.lightSecondary.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(String(index))
                .frame(width: Constants.indexItemSize.width, height: Constants.indexItemSize.height)
                .background(Asset.Colors.lightPrimary.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
