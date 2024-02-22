//
//  ContentView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 29.01.2024.
//

import SwiftUI

struct ContentView: View {
    @State
    var text = "" {
        didSet {
            print(text)
        }
    }

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
            Text("Install\nSettings -> General -> Keyboard -> Keyboards -> Add New Keyboard -> Qazaqsha")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            Text("(Optional)\nSettings -> General -> Keyboard -> Keyboards -> Batyrma - Qazaqsha -> Turn Allow Full Access")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            Text(
                """
                After you have done steps above
                select "Batyrma - Qazaqsha" keyboard then
                type "казагым" and tap to the space button.
                Then magic happens 🪄 and we convert
                shalaqazaq word "казагым" -> "қазағым"🤩
                """
            )
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 20)
            TextField("Type салем and type space ", text: $text).padding(20).border(Color.gray, width: 1)
            Spacer()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
