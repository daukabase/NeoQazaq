//
//  FeedbackService.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 22.11.2024.
//

import Foundation
import UIKit
import QazaqFoundation
import SwiftUI

// MARK: - Service

/// Delivers user feedback to a Telegram chat via the Bot API.
///
/// Configure through Info.plist keys `TelegramBotToken` and `TelegramChatID`
/// (they expand from the `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID` build settings).
final class FeedbackService {
    static let shared = FeedbackService()

    static let minimumMessageLength = 10
    static let maximumMessageLength = 3000  // Telegram caps a message at 4096 chars incl. metadata
    private static let cooldown: TimeInterval = 30
    private static let lastSentKey = "feedbackLastSentAt"

    enum FeedbackType: String, Identifiable {
        case question
        case collaboration
        case advertising

        var id: String { rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .question: return "tech_support"
            case .collaboration: return "feedback_collaboration_title"
            case .advertising: return "feedback_advertising_title"
            }
        }

        /// The sponsor form has none: it should read as a partnership, not a shout.
        var emoji: String? {
            switch self {
            case .question: return "💬"
            case .collaboration: return "🤝"
            case .advertising: return nil
            }
        }

        /// Title with its emoji, used for the menu row and the form's navigation bar.
        var displayTitle: Text {
            guard let emoji else { return Text(title) }
            return Text(verbatim: "\(emoji) ") + Text(title)
        }

        /// Shown above the message field.
        var prompt: LocalizedStringKey {
            switch self {
            case .question: return "feedback_question_prompt"
            case .collaboration: return "feedback_collaboration_prompt"
            case .advertising: return "feedback_advertising_request_title"
            }
        }

        var placeholder: LocalizedStringKey {
            self == .advertising ? "feedback_advertising_placeholder" : "feedback_message_placeholder"
        }

        /// What companies can buy, shown as rows above the form. Only formats that exist today.
        var formats: [(icon: String, text: LocalizedStringKey)] {
            guard self == .advertising else { return [] }
            return [
                ("paintpalette.fill", "feedback_advertising_format_skin"),
                ("space", "feedback_advertising_format_name"),
            ]
        }

        /// Under the message field (unless the length hint is showing).
        var messageFooter: LocalizedStringKey? {
            self == .advertising ? "feedback_advertising_reply_note" : nil
        }

        /// Collaboration and advertising requests are useless without a way to reply.
        var requiresContact: Bool {
            self == .collaboration || self == .advertising
        }

        fileprivate var telegramHeader: String {
            switch self {
            case .question: return "💬 Support request #support"
            case .collaboration: return "🤝 Collaboration request #collab"
            case .advertising: return "📣 Advertising request #ads"
            }
        }
    }

    enum SendError: Error {
        case notConfigured
        case rateLimited
        case requestFailed
    }

    private let session: URLSession
    private let defaults: UserDefaults

    init(session: URLSession = .shared, defaults: UserDefaults = .standard) {
        self.session = session
        self.defaults = defaults
    }

    static func isValid(_ message: String) -> Bool {
        message.trimmingCharacters(in: .whitespacesAndNewlines).count >= minimumMessageLength
    }

    static func isValid(contact: String, for type: FeedbackType) -> Bool {
        !type.requiresContact || !contact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func send(type: FeedbackType, message: String, contact: String) async throws {
        guard let token = Self.infoValue("TelegramBotToken"),
              let chatID = Self.infoValue("TelegramChatID"),
              let url = URL(string: "https://api.telegram.org/bot\(token)/sendMessage") else {
            throw SendError.notConfigured
        }

        if let lastSent = defaults.object(forKey: Self.lastSentKey) as? Date,
           Date().timeIntervalSince(lastSent) < Self.cooldown {
            throw SendError.rateLimited
        }

        var request = URLRequest(url: url, timeoutInterval: 20)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "chat_id": chatID,
            "text": Self.composeText(type: type, message: message, contact: contact),
            "disable_web_page_preview": true
        ])

        let (_, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw SendError.requestFailed
        }

        defaults.set(Date(), forKey: Self.lastSentKey)
    }

    private static func composeText(type: FeedbackType, message: String, contact: String) -> String {
        let body = String(message.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maximumMessageLength))
        let contact = contact.trimmingCharacters(in: .whitespacesAndNewlines)

        var lines = [type.telegramHeader, "", body, ""]
        if !contact.isEmpty {
            lines.append("Contact: \(contact)")
        }
        lines += [
            "Device: \(deviceIdentifier)",
            "iOS: \(UIDevice.current.systemVersion)",
            "App: \(GlobalConstants.appVersion)",
            "Language: \(Locale.preferredLanguages.first ?? "unknown")",
            "Keyboard enabled: \(GlobalConstants.isKeyboardExtensionEnabled ? "yes" : "no")"
        ]
        return lines.joined(separator: "\n")
    }

    /// Hardware model such as "iPhone15,2" (UIDevice.model only says "iPhone").
    private static var deviceIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafeBytes(of: &systemInfo.machine) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
    }

    private static func infoValue(_ key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        // An unset build setting leaves the value empty or as the literal "$(VAR)".
        return trimmed.isEmpty || trimmed.hasPrefix("$(") ? nil : trimmed
    }
}

// MARK: - View

struct FeedbackView: View {
    let type: FeedbackService.FeedbackType

    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var contact = ""
    @State private var isSending = false
    @State private var result: SendResult?
    @FocusState private var isMessageFocused: Bool

    private enum SendResult: Identifiable {
        case success
        case failure(FeedbackService.SendError)

        var id: String {
            switch self {
            case .success: return "success"
            case .failure(let error): return "failure-\(error)"
            }
        }
    }

    private var canSend: Bool {
        FeedbackService.isValid(message)
            && FeedbackService.isValid(contact: contact, for: type)
            && !isSending
    }

    var body: some View {
        NavigationView {
            Form {
                if !type.formats.isEmpty {
                    Section(
                        content: {
                            ForEach(Array(type.formats.enumerated()), id: \.offset) { _, format in
                                Label {
                                    Text(format.text)
                                        .fixedSize(horizontal: false, vertical: true)
                                } icon: {
                                    Image(systemName: format.icon)
                                        .foregroundColor(.accentColor)
                                }
                                .padding(.vertical, 2)
                            }
                        },
                        header: { Text("feedback_advertising_formats_title").textCase(nil) }
                    )
                }

                Section(
                    content: {
                        ZStack(alignment: .topLeading) {
                            if message.isEmpty {
                                Text(type.placeholder)
                                    .foregroundColor(Color(uiColor: .placeholderText))
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $message)
                                .frame(minHeight: 180)
                                .focused($isMessageFocused)
                        }
                    },
                    // Full sentences: keep their case instead of the default all-caps header.
                    header: { Text(type.prompt).textCase(nil) },
                    footer: {
                        if !message.isEmpty && !FeedbackService.isValid(message) {
                            Text("feedback_min_length_hint\(FeedbackService.minimumMessageLength)")
                        } else if let footer = type.messageFooter {
                            Text(footer)
                        }
                    }
                )

                Section(
                    content: {
                        TextField(
                            type.requiresContact ? "feedback_contact_required_placeholder" : "feedback_contact_placeholder",
                            text: $contact
                        )
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    },
                    footer: {
                        Text(type.requiresContact ? "feedback_contact_required_footer" : "feedback_contact_footer")
                    }
                )
            }
            .disabled(isSending)
            .navigationTitle(type.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("feedback_cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSending {
                        ProgressView()
                    } else {
                        Button("feedback_send", action: send)
                            .disabled(!canSend)
                    }
                }
            }
            .alert(item: $result) { result in
                switch result {
                case .success:
                    return Alert(
                        title: Text("feedback_sent_title"),
                        message: Text("feedback_sent_message"),
                        dismissButton: .default(Text("feedback_ok")) { dismiss() }
                    )
                case .failure(let error):
                    return Alert(
                        title: Text("feedback_error_title"),
                        message: Text(error == .rateLimited ? "feedback_rate_limited_message" : "feedback_error_message"),
                        dismissButton: .default(Text("feedback_ok"))
                    )
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isMessageFocused = true
                }
            }
        }
        .interactiveDismissDisabled(!message.isEmpty)
    }

    private func send() {
        guard canSend else { return }
        isSending = true
        Task { @MainActor in
            defer { isSending = false }
            do {
                try await FeedbackService.shared.send(type: type, message: message, contact: contact)
                result = .success
            } catch let error as FeedbackService.SendError {
                result = .failure(error)
            } catch {
                result = .failure(.requestFailed)
            }
        }
    }
}

struct FeedbackView_Preview: PreviewProvider {
    static var previews: some View {
        FeedbackView(type: .question)
    }
}
