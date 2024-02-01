//
//  ActionKeyButton.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 01.02.2024.
//

import UIKit

struct ActionKeyButtonViewModel {
    let image: UIImage?
    let title: String?
    let backgroundColor: UIColor
    var onTap: () -> Void
    var onDoubleTap: (() -> Void)?

    static let initial = ActionKeyButtonViewModel(
        image: UIImage(),
        title: nil,
        backgroundColor: .white,
        onTap: {},
        onDoubleTap: {}
    )
}

final class ActionKeyButton: UIButton {
    enum Constants {
        static let cornerRadius: CGFloat = 5
        static let borderWidth: CGFloat = 0.5
        static let borderColor: CGColor = UIColor.lightGray.cgColor
    }

    private var viewModel = ActionKeyButtonViewModel.initial

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    func configure(viewModel: ActionKeyButtonViewModel) {
        self.viewModel = viewModel

        setImage(viewModel.image, for: .normal)
        setTitle(viewModel.title, for: .normal)
        backgroundColor = viewModel.backgroundColor

        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        if viewModel.onDoubleTap != nil {
            addDoubleTapGesture()
        }
    }

    private func addDoubleTapGesture() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(buttonDoubleTapped))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
    }

    private func setupViews() {
        layer.cornerRadius = Constants.cornerRadius
        layer.borderWidth = Constants.borderWidth
        layer.borderColor = Constants.borderColor
        titleLabel?.font = UIFont.systemFont(ofSize: 16)
        setTitleColor(.black, for: .normal)
        backgroundColor = .white
    }

    @objc
    private func buttonTapped(_ sender: UIButton) {
        viewModel.onTap()
    }

    @objc
    private func buttonDoubleTapped(_ sender: UIButton) {
        viewModel.onDoubleTap?()
    }
}
