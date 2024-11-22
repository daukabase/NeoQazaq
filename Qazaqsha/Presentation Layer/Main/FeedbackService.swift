//
//  FeedbackServicew.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 22.11.2024.
//

import Foundation
import UIKit
import MessageUI
import QazaqFoundation
import SwiftUI

class FeedbackService: NSObject, MFMailComposeViewControllerDelegate {
    static let shared = FeedbackService()

    private let supportEmail = "daukabasegaming@gmail.com"
    
    enum FeedbackType {
        case question
        case bug
        
        var subject: String {
            switch self {
            case .question:
                return String(localized: "feedback_support_subject\(GlobalConstants.appName)")
            case .bug:
                return String(localized: "feedback_bug_subject\(GlobalConstants.appName)")
            }
        }
        
        var template: String {
            let deviceInfo = """
            
            \(String(localized: "feedback_device_info")):
            • \(String(localized: "feedback_device_model")): \(UIDevice.current.model)
            • \(String(localized: "feedback_ios_version")): \(UIDevice.current.systemVersion)
            • \(String(localized: "feedback_app_version")): \(GlobalConstants.appVersion)
            """
            
            switch self {
            case .question:
                return """
                
                
                
                \(deviceInfo)
                """
            case .bug:
                return """
                \(String(localized: "feedback_bug_description")):
                
                
                \(String(localized: "feedback_steps_to_reproduce")):
                1.
                2.
                3.
                
                \(String(localized: "feedback_expected_behavior")):
                
                \(deviceInfo)
                """
            }
        }
    }
    
    func showFeedback(type: FeedbackType, from viewController: UIViewController) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([supportEmail])
            mail.setSubject(type.subject)
            mail.setMessageBody(type.template, isHTML: false)
            
            viewController.present(mail, animated: true)
        } else {
            let alertController = UIAlertController(
                title: String(localized: "feedback_email_unavailable_title"),
                message: String(localized: "feedback_email_unavailable_message\(supportEmail)"),
                preferredStyle: .alert
            )
            
            alertController.addAction(UIAlertAction(
                title: String(localized: "feedback_copy_email"),
                style: .default,
                handler: { _ in
                    UIPasteboard.general.string = self.supportEmail
                }
            ))
            
            alertController.addAction(UIAlertAction(
                title: String(localized: "feedback_ok"),
                style: .default
            ))
            
            viewController.present(alertController, animated: true)
        }
    }
    
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)
    }
}

// SwiftUI View Extension
extension View {
    func presentFeedback(_ type: FeedbackService.FeedbackType) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        FeedbackService.shared.showFeedback(type: type, from: rootViewController)
    }
}
