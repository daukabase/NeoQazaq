//
//  TextRightChevronView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 14.04.2024.
//

import SwiftUI

final class TextRightChevronViewModel: ObservableObject {
    var text: String
    var onTap: () -> Void
    
    init(text: String, onTap: @escaping () -> Void) {
        self.text = text
        self.onTap = onTap
    }
}

struct TextRightChevronView: View {
    @ObservedObject
    var viewModel: TextRightChevronViewModel
    
    var body: some View {
        HStack {
            Text(viewModel.text)
            Spacer()
            Image(systemName: "chevron.right")
                .renderingMode(.template)
                .resizable()
                .frame(width: 8, height: 12)
                .foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
        }
    }
}

