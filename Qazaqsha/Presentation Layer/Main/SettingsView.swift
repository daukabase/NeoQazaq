//
//  SettingsView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 13.04.2024.
//

import SwiftUI
import QazaqFoundation

final class SettingsViewModel: ObservableObject {
    @UserDefault(item: UserDefaults.autoCapitalizationItem)
    var isAutoCapitalizationEnabled
    @UserDefault(item: UserDefaults.isKeyClicksSoundItem)
    var isKeyClicksSoundEnabled

    let magicAutocorrection = MagicAutocorrectionViewModel()
}

struct SettingsView: View {
    @ObservedObject
    var viewModel: SettingsViewModel
    
    @State var downloadViaWifiEnabled: Bool = false
    
    var body: some View {
        Form {
            settings
            autocorrectionSection
        }
        .navigationBarTitle("Settings")
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
            NavigationLink {
                MagicAutocorrectionView(viewModel: viewModel.magicAutocorrection)
            } label: {
                Text("Magic Auto-Correction")
            }
        }, footer: {
            Text("common_beta_magic_autocorrection")
        })
    }
}

struct SettingsView_Preview: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: SettingsViewModel())
    }
}
