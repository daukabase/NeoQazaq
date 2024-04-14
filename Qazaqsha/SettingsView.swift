//
//  SettingsView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 13.04.2024.
//

import SwiftUI
import QazaqFoundation

final class SettingsViewModel: ObservableObject {
    @UserDefault("isAutocompleteEnabled", store: .localAppGroup)
    var isAutocompleteEnabled: Bool = false
    @UserDefault("isAutoCapitalizationEnabled", store: .localAppGroup)
    var isAutoCapitalizationEnabled: Bool = false
    @UserDefault("isKeyClicksSoundEnabled", store: .localAppGroup)
    var isKeyClicksSoundEnabled: Bool = false
}

struct SettingsView: View {
    @ObservedObject
    var viewModel: SettingsViewModel

    @State var downloadViaWifiEnabled: Bool = false

    var body: some View {
        NavigationView {
            Form {
                settings
                autocorrectionSection
            }
            .navigationBarTitle("Settings")
        }
    }

    var settings: some View {
        Section(content: {
            Toggle(isOn: $viewModel.isAutoCapitalizationEnabled) {
                HStack {
                    Text("Auto-Capitalization")
                }
            }
            Toggle(isOn: $viewModel.isKeyClicksSoundEnabled) {
                HStack {
                    Text("Key Click Sounds")
                }
            }
            HStack {
                Text("Emoji key").foregroundColor(Asset.Colors.text.swiftUIColor)
                Spacer(minLength: 8)
                Text("coming soon")
                    .font(.callout)
                    .foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
            }
        })
    }

    var autocorrectionSection: some View {
        Section(content: {
            TextRightChevronView(viewModel: TextRightChevronViewModel(
                text: "Magic Auto-Correction", onTap: {
                    print("show magic autocorrection setup view")
                }
            ))
        }, footer: {
            Text("BETA: This feature is still in development and may not work as expected.")
        })
    }

    var autocorrectionInfoButton: some View {
        Button(action: {
            // show gif
        }, label: {
            Image(systemName: "info")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Asset.Colors.lightAction.swiftUIColor)
                .frame(width: 6, height: 9)
                .frame(width: 18, height: 18)
                .background(
                    Circle().strokeBorder(
                        Asset.Colors.lightAction.swiftUIColor,
                        lineWidth: 1
                    )
                )
        })
    }
}

struct SettingsView_Preview: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: SettingsViewModel())
    }
}
