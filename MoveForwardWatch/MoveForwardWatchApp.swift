import SwiftUI
import UserNotifications

@main
struct MoveForwardWatchApp: App {
    @StateObject private var store: AppStore
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let persistence = PersistenceStore(fileURL: PersistenceStore.defaultURL())
        let scheduler = UserNotificationScheduler()
        UNUserNotificationCenter.current().delegate = scheduler
        scheduler.presentsInForeground = false
        let notifications = SessionNotificationController(
            scheduler: scheduler,
            schedulesSystemNotifications: true
        )
        _store = StateObject(
            wrappedValue: AppStore(
                localDevice: .watch,
                persistence: persistence,
                notifications: notifications,
                connectivity: ConnectivityService()
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(store)
                .onOpenURL { url in
                    store.handleOpenURL(url)
                }
        }
        .onChange(of: scenePhase) { _, phase in
            store.setPresentsNotificationsInForeground(phase == .active)
            if phase == .active {
                Task { await store.reconcileSession() }
                if ChooserLaunch.consume() {
                    store.showChooser = true
                }
            }
        }
    }
}
