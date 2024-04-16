//
//  KeyboardSelectionView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 16.04.2024.
//

import SwiftUI
import QazaqFoundation

final class KeyboardSelectionViewModel: ObservableObject {
    
}

struct KeyboardSelectionView: View {
    @ObservedObject
    var viewModel: KeyboardSelectionViewModel
    
    @Environment(\.colorScheme)
    private var isDarkMode: ColorScheme
    
    var body: some View {
        Form {
            Section(content: {
                gifSelectKeyboardExample
            }, header: {
                headerView
                    .padding(.vertical, 32)
            })
            .listRowInsets(EdgeInsets())
        }
        .navigationBarTitle("Switch to \(GlobalConstants.appName)")
    }
    
    func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 5) {
            Text("•")
                .foregroundColor(Asset.Colors.text.swiftUIColor)
            Text(text)
                .foregroundColor(Asset.Colors.text.swiftUIColor)
                .fixedSize(horizontal: false, vertical: true)  // Ensures text wraps correctly
        }
    }
    
    var headerView: some View {
        VStack(alignment: .leading, spacing: 10, content: {
            Text("How to Switch to the \(GlobalConstants.appName) Keyboard?")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Asset.Colors.text.swiftUIColor)
                .textCase(nil) // Ensuring text case is not altered
                .fixedSize(horizontal: false, vertical: true)
            
            Text("Follow these steps to set \(GlobalConstants.appName) as your default keyboard:")
                .foregroundColor(Asset.Colors.text.swiftUIColor)
                .font(.body)
                .textCase(nil) // Ensuring text case is not altered
                .fixedSize(horizontal: false, vertical: true)
            
            // Steps with custom alignment
            VStack(alignment: .leading, spacing: 5) {
                bulletPoint("Open any text field to bring up the keyboard.")
                bulletPoint("Tap the globe icon next to the spacebar to cycle through installed keyboards.")
                bulletPoint("Select \(GlobalConstants.appName). Once selected, it will remain your default keyboard unless changed.")
            }
            .foregroundColor(Asset.Colors.text.swiftUIColor)
            .font(.body)
            .textCase(nil) // Ensuring text case is not altered
        })
    }

    var gifSelectKeyboardExample: some View {
        let ratio = 1.06078431
        let width = UIScreen.main.bounds.width - 32
        let height = width / ratio
        
        let gifName = isDarkMode == .dark ? "selectNeoQazaqKeyboardDark" : "selectNeoQazaqKeyboardWhite"
        
        return GifImage(name: gifName)
            .frame(width: width, height: height)
    }
}

struct KeyboardSelectionView_Preview: PreviewProvider {
    static var previews: some View {
        KeyboardSelectionView(viewModel: KeyboardSelectionViewModel())
    }
}
