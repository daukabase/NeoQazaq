//
//  GifImage.swift
//  QazaqFoundation
//
//  Created by Daulet Almagambetov on 15.04.2024.
//

import SwiftUI
import FLAnimatedImage

public struct GifImage: UIViewRepresentable {
    var name: String
    private var animatedView = FLAnimatedImageView()

    public init(name: String) {
        self.name = name
    }

    public func makeUIView(context: UIViewRepresentableContext<GifImage>) -> UIView {
        if
            let bundleURL = Bundle.main.url(forResource: name, withExtension: "gif"),
            let imageData = try? Data(contentsOf: bundleURL)
        {
            let gif = FLAnimatedImage(gifData: imageData)
            animatedView.animatedImage = gif
            animatedView.translatesAutoresizingMaskIntoConstraints = false
        }

        let view = UIView()
        view.addSubview(animatedView)

        view.heightAnchor.constraint(equalTo: animatedView.heightAnchor).isActive = true
        view.widthAnchor.constraint(equalTo: animatedView.widthAnchor).isActive = true

        return view
    }

    public func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<GifImage>) {}
}

import Combine

public class KeyboardResponder: ObservableObject {
    @Published
    public var currentHeight: CGFloat = 0

    public var keyboardShowSubscriber: AnyCancellable?
    public var keyboardHideSubscriber: AnyCancellable?

    public init() {
        keyboardShowSubscriber = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification in
                notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            }
            .map { $0.height }
            .assign(to: \.currentHeight, on: self)

        keyboardHideSubscriber = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
            .assign(to: \.currentHeight, on: self)
    }
}
