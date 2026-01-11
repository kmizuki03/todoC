import SwiftUI
import UIKit

private struct NotificationErrorAlertModifier: ViewModifier {
    @ObservedObject var model: NotificationErrorViewModel
    @Environment(\.openURL) private var openURL

    func body(content: Content) -> some View {
        content
            .alert("通知", isPresented: $model.isPresented) {
                if model.canOpenSettings {
                    Button("設定を開く") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text(model.message)
            }
    }
}

extension View {
    func notificationErrorAlert(_ model: NotificationErrorViewModel) -> some View {
        modifier(NotificationErrorAlertModifier(model: model))
    }
}
