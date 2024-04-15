//
//  QazaqshaApp.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 29.01.2024.
//

import SwiftUI

@main
struct QazaqshaApp: App {
    let viewModel = MagicAutocorrectionViewModel()
    var body: some Scene {
        WindowGroup {
//            AppMain(viewModel: AppMainModel())
//            MainView(viewModel: MainViewModel())
            MagicAutocorrectionView(viewModel: viewModel)
        }
    }
}
