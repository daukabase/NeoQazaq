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

struct RussianKeyboardViewModel {
    enum Constants {
        static let russianKeys = {
            russianUppercasedKeys.map { row in
                row.map { key in
                    LetterKey(uppercased: key, lowercased: key.lowercased())
                }
            }
        }()
        static let russianUppercasedKeys = [
            ["Й", "Ц", "У", "К", "Е", "Н", "Г", "Ш", "Щ", "З", "Х", "Ъ"],
            ["Ф", "Ы", "В", "А", "П", "Р", "О", "Л", "Д", "Ж", "Э"],
            ["Я", "Ч", "С", "М", "И", "Т", "Ь", "Б", "Ю"]
        ]
    }

    enum Shift: Equatable {
        case lowercased
        case uppercasedOnce
        case uppercased

        var next: Shift {
            switch self {
            case .lowercased:
                return .uppercasedOnce
            case .uppercasedOnce:
                return .uppercased
            case .uppercased:
                return .lowercased
            }
        }
    }

    var shift: Shift = .lowercased
    let letterKeys: [[LetterKey]] = Constants.russianKeys
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
            image: UIImage(),
            title: nil,
            backgroundColor: .lightGray,
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
            image: UIImage(),
            title: nil,
            backgroundColor: .lightGray,
            onTap: { [weak self] in
                guard let self else { return }
                print("backspace")
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
            backgroundColor: .lightGray,
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
            image: UIImage(),
            title: nil,
            backgroundColor: .lightGray,
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
            onPress: { [weak self] value in
                guard let self else { return }
                self.delegate?.russianKeyboardView(self, didTapKey: value)
            }
        )

        button.configure(viewModel: viewModel)
        return button
    }()

    private lazy var returnKeyButton: ActionKeyButton = {
        let button = ActionKeyButton()
        let viewModel = ActionKeyButtonViewModel(
            image: UIImage(),
            title: nil,
            backgroundColor: .lightGray,
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
    }
}

private extension RussianKeyboardView {
    func setupViews() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(5)
        }

        setupRowsFor(stackView: stackView)
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
        stackView.spacing = 5
        return stackView
    }

    func createLastRowStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill
        stackView.spacing = 5
        
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

        return stackView
    }

    private func append(letters: [LetterKey], into stackView: UIStackView) {
        letters.forEach { key in
            let model = LetterKeyButtonViewModel(
                title: viewModel.shift == .lowercased ? key.lowercased : key.uppercased,
                value: viewModel.shift == .lowercased ? key.lowercased : key.uppercased,
                onPress: { [weak self] key in
                    guard let self else { return }
                    self.delegate?.russianKeyboardView(self, didTapKey: key)

                    if self.viewModel.shift == .uppercasedOnce {
                        self.viewModel.shift = self.viewModel.shift.next
                    }
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
}


// struct that has two states for uppercased and lowercased letter with init
struct LetterKey {
    let uppercased: String
    let lowercased: String

    init(uppercased: String, lowercased: String) {
        self.uppercased = uppercased
        self.lowercased = lowercased
    }
}

// MARK: - LetterKeyButton

struct LetterKeyButtonViewModel {
    let title: String
    let value: String
    var onPress: (String) -> Void
}

final class LetterKeyButton: UIButton {
    enum Constants {
        static let cornerRadius: CGFloat = 5
        static let borderWidth: CGFloat = 0.5
        static let borderColor: CGColor = UIColor.lightGray.cgColor
    }

    private var viewModel = LetterKeyButtonViewModel(title: "", value: "", onPress: { _ in })

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }

    func configure(viewModel: LetterKeyButtonViewModel) {
        self.viewModel = viewModel
        setTitle(viewModel.title, for: .normal)
        addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
    }

    private func setupViews() {
        layer.cornerRadius = Constants.cornerRadius
        layer.borderWidth = Constants.borderWidth
        layer.borderColor = Constants.borderColor
        titleLabel?.font = UIFont.systemFont(ofSize: 24)
        setTitleColor(.black, for: .normal)
        backgroundColor = .white
    }

    @objc
    private func buttonPressed(_ sender: UIButton) {
        viewModel.onPress(viewModel.value)
    }
}

// MARK: - ActionButton

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

extension UIStackView {
    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach {
            removeArrangedSubview($0)
            $0.removeFromSuperview()
            NSLayoutConstraint.deactivate($0.constraints)
        }
    }
}
