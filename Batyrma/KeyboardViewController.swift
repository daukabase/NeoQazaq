//
//  KeyboardViewController.swift
//  Batyrma
//
//  Created by Daulet Almagambetov on 29.01.2024.
//

import UIKit

class KeyboardViewController: UIInputViewController {
    let provider: AutocompleteProvider = QazaqAutocompleteProvider()
    var currentTextBuffer: String? {
        didSet {
            if let currentTextBuffer = currentTextBuffer {
                previewLabel.text = "«\(currentTextBuffer)»"
            } else {
                previewLabel.text = "«»"
            }
        }
    }

    private lazy var nextKeyboardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Next Keyboard", comment: "Title for 'Next Keyboard' button"), for: [])
        button.sizeToFit()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        return button
    }()

    private lazy var previewLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    private lazy var keyboardView: RussianKeyboardView = {
        let view = RussianKeyboardView()
        view.delegate = self
        return view
    }()

    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Add custom view sizing constraints here
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(previewLabel)
        view.addSubview(keyboardView)
        view.addSubview(nextKeyboardButton)
        
        previewLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(4)
            make.height.equalTo(20)
        }
        keyboardView.snp.makeConstraints { make in
            make.top.equalTo(previewLabel.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        nextKeyboardButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    override func viewWillLayoutSubviews() {
        self.nextKeyboardButton.isHidden = !self.needsInputModeSwitchKey
        super.viewWillLayoutSubviews()
    }

    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        
        var textColor: UIColor
        let proxy = self.textDocumentProxy
        if proxy.keyboardAppearance == UIKeyboardAppearance.dark {
            textColor = UIColor.white
        } else {
            textColor = UIColor.black
        }
        self.nextKeyboardButton.setTitleColor(textColor, for: [])
    }

}

extension KeyboardViewController: RussianKeyboardViewDelegate {
    func russianKeyboardViewDidTapBackspace(_ keyboardView: RussianKeyboardView) {
        textDocumentProxy.deleteBackward()
    }

    func russianKeyboardView(_ keyboardView: RussianKeyboardView, didTapKey key: String) {
        let currentWord = textDocumentProxy.currentWord ?? ""
        let primarySuggestion = provider.suggestions(for: currentWord).first?.text

        if key == .space {
            if let primarySuggestion = primarySuggestion {
                textDocumentProxy.replaceCurrentWord(with: primarySuggestion)
                textDocumentProxy.insertText(.space)
            } else {
                textDocumentProxy.insertText(key)
            }
        } else {
            textDocumentProxy.insertText(key)
        }
        
        let updatedSuggestion = provider.suggestions(for: textDocumentProxy.currentWord ?? "").first?.text
        currentTextBuffer = updatedSuggestion
    }
}
