import SwiftUI
import UserNotifications

@main
struct MoveForwardApp: App {
    @StateObject private var store: AppStore
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let persistence = PersistenceStore(fileURL: PersistenceStore.defaultURL())
        let scheduler = UserNotificationScheduler()
        UNUserNotificationCenter.current().delegate = scheduler
        let notifications = SessionNotificationController(
            scheduler: scheduler,
            schedulesSystemNotifications: false
        )
        _store = StateObject(
            wrappedValue: AppStore(
                localDevice: .phone,
                persistence: persistence,
                notifications: notifications,
                connectivity: ConnectivityService()
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(store.settings.appearance.colorScheme)
                .tint(Palette.teal)
                .onOpenURL { url in
                    store.handleOpenURL(url)
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task {
                    await store.reconcileSession()
                    await store.refreshNotificationStatus()
                }
                if ChooserLaunch.consume() {
                    store.showChooser = true
                }
            }
        }
    }
}
