//
//  RussianKeyboardView.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 29.01.2024.
//

import UIKit
import SnapKit

// delegate for key tap
protocol RussianKeyboardViewDelegate: AnyObject {
    func russianKeyboardView(_ keyboardView: RussianKeyboardView, didTapKey key: String)
}

class RussianKeyboardView: UIView {
    enum Constants {
        static let russianKeys = [
            ["Й", "Ц", "У", "К", "Е", "Н", "Г", "Ш", "Щ", "З", "Х", "Ъ"],
            ["Ф", "Ы", "В", "А", "П", "Р", "О", "Л", "Д", "Ж", "Э"],
            ["Я", "Ч", "С", "М", "И", "Т", "Ь", "Б", "Ю"]
        ]
    }
    weak var delegate: RussianKeyboardViewDelegate?

    // MARK: - UI
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 5
        return stackView
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    // MARK: - Public Methods
    func addButtons(_ buttons: [KeyboardButton]) {
        buttons.forEach { stackView.addArrangedSubview($0) }
    }
}

private extension RussianKeyboardView {
    func setupViews() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(5)
        }

        for row in Constants.russianKeys {
            let rowStackView = createRowStackView()
            for key in row {
                let keyButton = createKeyButton(title: key)
                rowStackView.addArrangedSubview(keyButton)
            }
            stackView.addArrangedSubview(rowStackView)
        }

        let spaceStack = createRowStackView()
        let spaceKey = createKeyButton(title: "space")
        spaceStack.addArrangedSubview(spaceKey)

        stackView.addArrangedSubview(spaceStack)
    }

    func createRowStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 5
        return stackView
    }

    func createKeyButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .lightGray
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(keyPressed), for: .touchUpInside)
        return button
    }

    @objc private func keyPressed(_ sender: UIButton) {
        guard let key = sender.titleLabel?.text else { return }
        delegate?.russianKeyboardView(self, didTapKey: key)
    }
}

