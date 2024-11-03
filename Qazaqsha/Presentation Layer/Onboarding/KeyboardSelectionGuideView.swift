//
//  KeyboardSelectionGuideView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 04.11.2024.
//

import SwiftUI
import QazaqFoundation

struct KeyboardSelectionGuideView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            stepsView
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Using the keyboard")
                .font(.headline)
                .foregroundColor(Asset.Colors.text.swiftUIColor)
            Text("Follow these steps to start using")
                .font(.subheadline)
                .foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
                .lineLimit(nil)
        }
    }

    var stepsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            text(
                index: 0,
                text: "Open any text field",
                subtitle: "Bring up the keyboard"
            )
            iconText(
                index: 1,
                icon: globeIcon,
                text: "Long-press globe icon",
                subtitle: "Located next to spacebar"
            )
            text(
                index: 2,
                text: "Select \(GlobalConstants.appName)",
                subtitle: "Will remain active until changed"
            )
        }
    }
    
    var globeIcon: some View {
        Image(systemName: "globe")
            .renderingMode(.template)
            .foregroundColor(.white)
            .frame(width: 32, height: 32)
            .background(Asset.Colors.lightAction.swiftUIColor)
            .clipShape(RoundedRectangle(
                cornerRadius: (10 / 57) * 32,
                style: .continuous
            ))
    }
    
    func iconText(
        index: Int,
        icon: some View,
        text: String,
        subtitle: String? = nil
    ) -> some View {
        HStack(alignment: .center, spacing: 16) {
            indexView(index: index)
            
            HStack(spacing: 8) {
                icon
                
                VStack(alignment: .leading) {
                    Text(text)
                        .foregroundColor(Asset.Colors.text.swiftUIColor)
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
                            .lineLimit(nil)
                    }
                }
            }
            
            Spacer()
        }
        .frame(height: subtitle == nil ? 40 : 50)
    }
    
    func text(
        index: Int,
        text: String,
        subtitle: String? = nil
    ) -> some View {
        HStack(alignment: .center, spacing: 16) {
            indexView(index: index)
            
            VStack(alignment: .leading) {
                Text(text)
                    .foregroundColor(Asset.Colors.text.swiftUIColor)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(Asset.Colors.lightSecondary.swiftUIColor)
                        .lineLimit(nil)
                }
            }
            
            Spacer()
        }
        .frame(height: subtitle == nil ? 40 : 50)
    }
    
    func indexView(index: Int) -> some View {
        Text(String(index + 1))
            .font(.caption)
            .frame(width: 21, height: 21)
            .foregroundColor(Asset.Colors.text.swiftUIColor)
            .background(
                Circle()
                    .strokeBorder(Asset.Colors.text.swiftUIColor, lineWidth: 1)
            )
    }
}
