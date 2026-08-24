import Foundation

enum ChooserLaunch {
    static let notification = Notification.Name("MoveForward.openChooser")
    static let defaultsKey = "pendingTemplateChooser"

    static func request() {
        UserDefaults.standard.set(true, forKey: defaultsKey)
        NotificationCenter.default.post(name: notification, object: nil)
    }

    @discardableResult
    static func consume() -> Bool {
        let pending = UserDefaults.standard.bool(forKey: defaultsKey)
        UserDefaults.standard.set(false, forKey: defaultsKey)
        return pending
    }
}
