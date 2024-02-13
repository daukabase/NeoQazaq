//
//  LetterKeyButtonView.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 01.02.2024.
//

import UIKit

//struct LetterKeyButtonViewModel {
//    let title: String
//    let value: String
//    let font: UIFont
//    var onPress: (String) -> Void
//
//    init(title: String, value: String, font: UIFont = UIFont.systemFont(ofSize: 24), onPress: @escaping (String) -> Void) {
//        self.title = title
//        self.value = value
//        self.font = font
//        self.onPress = onPress
//    }
//}
//
//final class LetterKeyButton: UIView {
//    enum Constants {
//        static let cornerRadius: CGFloat = 5
//        static let borderWidth: CGFloat = 0.5
//        static let borderColor: CGColor = UIColor.lightGray.cgColor
//    }
//
//    private var viewModel = LetterKeyButtonViewModel(title: "", value: "", onPress: { _ in })
//    private lazy var titleLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 24)
//        label.textColor = Asset.Colors.lightInk.color
//        return label
//    }()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupViews()
//    }
//    
//    required init?(coder aDecoder: NSCoder) { fatalError() }
//
//    func configure(viewModel: LetterKeyButtonViewModel) {
//        self.viewModel = viewModel
//        let tapGesture = UITapGestureRecognizer()
//
//        tapGesture.addTarget(self, action: #selector(buttonPressed))
//        addGestureRecognizer(tapGesture)
//        titleLabel.text = viewModel.title
//        titleLabel.font = viewModel.font
//    }
//
//    private func setupViews() {
//        layer.cornerRadius = Constants.cornerRadius
//        backgroundColor = Asset.Colors.lightPrimary.color
//        layer.borderWidth = Constants.borderWidth
//        layer.borderColor = Constants.borderColor
//
//        addSubview(titleLabel)
//
//        titleLabel.snp.makeConstraints { make in
//            make.center.equalToSuperview()
//        }
//    }
//
//    @objc
//    private func buttonPressed(_ sender: UIButton) {
//        viewModel.onPress(viewModel.value)
//    }
//}
