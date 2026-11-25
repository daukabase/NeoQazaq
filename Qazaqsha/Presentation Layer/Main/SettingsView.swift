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
    
    @State private var didRequestLearnedWordsReset = false

    var body: some View {
        Form {
            settings
            autocorrectionSection
            learnedWordsSection
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

    /// The keyboard keeps learned words in its own storage, which the app can't write. The app
    /// leaves a new token in the shared app group; the keyboard sees it on its next launch and
    /// clears its store (see PersonalStore.resetIfRequested).
    var learnedWordsSection: some View {
        Section(content: {
            Button(role: .destructive) {
                UserDefaults.localAppGroup.set(UUID().uuidString, forKey: UserDefaults.personalStoreResetTokenKey)
                didRequestLearnedWordsReset = true
            } label: {
                Text("reset_learned_words")
            }
            .disabled(didRequestLearnedWordsReset)
        }, footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey(didRequestLearnedWordsReset ? "reset_learned_words_done" : "reset_learned_words_footer"))
                Text("prediction_data_credit")
            }
        })
    }
}

struct SettingsView_Preview: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: SettingsViewModel())
    }
}
