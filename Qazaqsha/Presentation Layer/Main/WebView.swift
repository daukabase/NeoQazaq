//
//  WebView.swift
//  Qazaqsha
//
//  Created by Daulet Almagambetov on 18.04.2024.
//

import SwiftUI
import WebKit


struct WebView: UIViewRepresentable {
    var url: URL
    @Binding var height: CGFloat// = CGFloat(200)  // A binding to adjust the height

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { (result, error) in
                if let height = result as? CGFloat {
                    self.parent.height = height
                }
            }
        }
    }
}
struct PrivacyPolicyView: View {
    @State private var contentHeight: CGFloat = UIScreen.main.bounds.height  // Default height, can adjust as needed

    var body: some View {
        Form {
            Section(header: Text("Privacy Policy")) {
                WebView(url: URL(string: "https://www.termsfeed.com/live/b5039a8d-5c6d-4f8f-973c-1b032ab9b18b")!, height: $contentHeight)
                    .frame(height: contentHeight)
            }
        }
        .navigationBarTitle("Privacy Policy")
    }
}

struct PrivacyPolicyView_Preview: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView()
    }
}
