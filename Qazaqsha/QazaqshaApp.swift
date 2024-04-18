//
//  QazaqshaApp.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 29.01.2024.
//

import SwiftUI

@main
struct QazaqshaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    let viewModel = MagicAutocorrectionViewModel()
    var body: some Scene {
        WindowGroup {
            AppMain(viewModel: AppMainModel())
        }
    }
}
