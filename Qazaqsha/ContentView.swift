//
//  ContentView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 29.01.2024.
//

import SwiftUI

struct ContentView: View {
    @State
    var text = ""
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Open Settings -> General -> Keyboard -> Keyboards -> Add New Keyboard -> Batyrma - Qazaqsha")
                .multilineTextAlignment(.center)
                .padding(20)
            Text("Then Open Batyrman - Qazaqsha -> Turn Allow Full Access")
                .multilineTextAlignment(.center)
                .padding(20)
            Spacer(minLength: 16)
            TextField("Placeholder", text: $text).padding(20).border(Color.gray, width: 1)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
