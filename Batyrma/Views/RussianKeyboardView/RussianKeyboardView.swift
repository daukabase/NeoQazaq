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
    func russianKeyboardViewDidTapBackspace(_ keyboardView: RussianKeyboardView)
}

class RussianKeyboardView: UIView {
    weak var delegate: RussianKeyboardViewDelegate?
    private var viewModel = RussianKeyboardViewModel() {
        didSet {
            render()
        }
    }

    // MARK: - UI
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 11
        return stackView
    }()

    private lazy var shiftKeyButton: ActionKeyButton = {
        let button = ActionKeyButton()
        let viewModel = ActionKeyButtonViewModel(
            image: Asset.Images.keyLowercased.image,
            title: nil,
            backgroundColor: Asset.Colors.lightSecondary.color,
            onTap: { [weak self] in
                guard let self else { return }
                self.viewModel.shift = self.viewModel.shift.next
            },
            onDoubleTap: { [weak self] in
                guard let self else { return }
                self.viewModel.shift = .uppercased
            }
        )
        
        button.configure(viewModel: viewModel)
        return button
    }()

    private lazy var backspaceKeyButton: ActionKeyButton = {
        let button = ActionKeyButton()
        let viewModel = ActionKeyButtonViewModel(
            image: Asset.Images.keyBackspace.image,
            title: nil,
            backgroundColor: Asset.Colors.lightSecondary.color,
            onTap: { [weak self] in
                guard let self else { return }
                self.delegate?.russianKeyboardViewDidTapBackspace(self)
            },
            onDoubleTap: nil
        )

        button.configure(viewModel: viewModel)
        return button
    }()

    private lazy var numbersLayoutKeyButton: ActionKeyButton = {
        let button = ActionKeyButton()
        let viewModel = ActionKeyButtonViewModel(
            image: nil,
            title: "123",
            backgroundColor: Asset.Colors.lightSecondary.color,
            onTap: { [weak self] in
                guard let self else { return }
                print("numbers")
            },
            onDoubleTap: nil
        )

        button.configure(viewModel: viewModel)
        return button
    }()

    private lazy var emojiKeyButton: ActionKeyButton = {
        let button = ActionKeyButton()
        let viewModel = ActionKeyButtonViewModel(
            image: Asset.Images.keyEmoji.image,
            title: nil,
            backgroundColor: Asset.Colors.lightSecondary.color,
            onTap: { [weak self] in
                guard let self else { return }
                print("emoji")
            },
            onDoubleTap: nil
        )

        button.configure(viewModel: viewModel)
        return button
    }()

    private lazy var spaceKeyButton: LetterKeyButton = {
        let button = LetterKeyButton()
        let viewModel = LetterKeyButtonViewModel(
            title: "space",
            value: " ",
            font: UIFont.systemFont(ofSize: 16),
            onPress: { [weak self] value in
                self?.onTap(value: value)
            }
        )

        button.configure(viewModel: viewModel)
        return button
    }()

    private lazy var returnKeyButton: ActionKeyButton = {
        let button = ActionKeyButton()
        let viewModel = ActionKeyButtonViewModel(
            image: nil,
            title: "return",
            backgroundColor: Asset.Colors.lightSecondary.color,
            onTap: { [weak self] in
                guard let self else { return }
                
            },
            onDoubleTap: nil
        )

        button.configure(viewModel: viewModel)
        return button
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
    
    func render() {
        setupRowsFor(stackView: stackView)
        shiftKeyButton.setImage(viewModel.shift.image, for: .normal)
    }
}

private extension RussianKeyboardView {
    func setupViews() {
        backgroundColor = Asset.Colors.keyboardBackground.color
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(1)
        }

        setupRowsFor(stackView: stackView)
        shiftKeyButton.setImage(viewModel.shift.image, for: .normal)
    }

    func setupRowsFor(stackView: UIStackView) {
        stackView.removeAllArrangedSubviews()
        viewModel.letterKeys.enumerated().forEach { (row, letters) in
            switch row {
            case 0, 1:
                let rowStackView = createRowStackView()
                append(letters: letters, into: rowStackView)
                stackView.addArrangedSubview(rowStackView)
            case 2:
                let rowStackView = createRowStackView()

                rowStackView.addArrangedSubview(shiftKeyButton)
                append(letters: letters, into: rowStackView)
                rowStackView.addArrangedSubview(backspaceKeyButton)

                stackView.addArrangedSubview(rowStackView)
            default:
                break
            }
        }

        stackView.addArrangedSubview(createLastRowStackView())
    }

    func createRowStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 6
        stackView.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        return stackView
    }

    func createLastRowStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 7
        
        stackView.addArrangedSubview(numbersLayoutKeyButton)
        stackView.addArrangedSubview(emojiKeyButton)
        stackView.addArrangedSubview(spaceKeyButton)
        stackView.addArrangedSubview(returnKeyButton)

        returnKeyButton.snp.makeConstraints { make in
            make.width.equalTo(87)
        }

        numbersLayoutKeyButton.snp.makeConstraints { make in
            make.width.equalTo(emojiKeyButton)
            make.width.equalTo(44)
        }

        stackView.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        return stackView
    }

    private func append(letters: [LetterKey], into stackView: UIStackView) {
        letters.forEach { key in
            let model = LetterKeyButtonViewModel(
                title: viewModel.shift == .lowercased ? key.lowercased : key.uppercased,
                value: viewModel.shift == .lowercased ? key.lowercased : key.uppercased,
                onPress: { [weak self] value in
                    self?.onTap(value: value)
                }
            )
            let button = LetterKeyButton()
            button.configure(viewModel: model)
            stackView.addArrangedSubview(button)
        }
    }

    func createKeyButton(model: LetterKeyButtonViewModel) -> LetterKeyButton {
        let button = LetterKeyButton()
        button.configure(viewModel: model)
        return button
    }

    // MARK: - Actions

    private func onTap(value: String) {
        delegate?.russianKeyboardView(self, didTapKey: value)

        if viewModel.shift == .uppercasedOnce {
            viewModel.shift = viewModel.shift.next
        }
    }
}
